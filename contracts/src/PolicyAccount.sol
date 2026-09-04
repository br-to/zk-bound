// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IHonkVerifier {
    function verify(bytes calldata proof, bytes32[] calldata publicInputs) external view returns (bool);
}

/// @notice Minimal smart account: a valid UltraHonk policy proof is required to send ETH.
/// @dev Public input order matches `packages/policy-sdk` / the Noir circuit:
///      commitment, chainId, account, target, value, calldataHash, nonce, expiry.
contract PolicyAccount {
    uint256 internal constant BN254_FR =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 internal constant PUBLIC_INPUT_COUNT = 8;

    IHonkVerifier public immutable verifier;
    /// @dev Who registered the commitment. Reserved for later policy updates.
    address public immutable owner;
    uint256 public immutable policyCommitment;
    uint256 public nonce;

    error NotOwner();
    error BadPublicInputLength();
    error CommitmentMismatch();
    error ChainIdMismatch();
    error AccountMismatch();
    error TargetMismatch();
    error ValueMismatch();
    error CalldataHashMismatch();
    error NonceMismatch();
    error ExpiryMismatch();
    error Expired();
    error ProofInvalid();
    error CallFailed();

    constructor(address verifier_, address owner_, uint256 policyCommitment_) {
        verifier = IHonkVerifier(verifier_);
        owner = owner_;
        policyCommitment = policyCommitment_;
    }

    receive() external payable {}

    /// @notice Anyone may submit a bound proof. The circuit witness stays off-chain.
    function execute(
        bytes calldata proof,
        bytes32[] calldata publicInputs,
        address target,
        uint256 value,
        bytes calldata data,
        uint64 expiry
    ) external {
        if (publicInputs.length != PUBLIC_INPUT_COUNT) revert BadPublicInputLength();
        if (uint256(publicInputs[0]) != policyCommitment) revert CommitmentMismatch();
        if (uint256(publicInputs[1]) != block.chainid) revert ChainIdMismatch();
        if (address(uint160(uint256(publicInputs[2]))) != address(this)) revert AccountMismatch();
        if (address(uint160(uint256(publicInputs[3]))) != target) revert TargetMismatch();
        if (uint256(publicInputs[4]) != value) revert ValueMismatch();
        if (uint256(publicInputs[5]) != uint256(keccak256(data)) % BN254_FR) revert CalldataHashMismatch();
        if (uint256(publicInputs[6]) != nonce) revert NonceMismatch();
        if (uint256(publicInputs[7]) != expiry) revert ExpiryMismatch();
        if (block.timestamp > expiry) revert Expired();

        nonce += 1;
        if (!verifier.verify(proof, publicInputs)) revert ProofInvalid();

        (bool ok,) = target.call{ value: value }(data);
        if (!ok) revert CallFailed();
    }
}
