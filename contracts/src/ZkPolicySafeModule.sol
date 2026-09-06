// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Enum} from "safe-smart-account/common/Enum.sol";

interface IHonkVerifier {
    function verify(bytes calldata proof, bytes32[] calldata publicInputs) external view returns (bool);
}

interface ISafe {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);
}

/// @notice Safe module that executes native ETH transfers only when a valid policy proof is provided.
/// @dev Public input order matches `packages/policy-sdk` / the Noir circuit:
///      commitment, chainId, account, target, value, calldataHash, nonce, expiry.
contract ZkPolicySafeModule is Enum {
    uint256 internal constant BN254_FR =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 internal constant PUBLIC_INPUT_COUNT = 8;

    struct PolicyState {
        uint256 commitment;
        uint256 nonce;
        bool active;
    }

    IHonkVerifier public immutable verifier;

    mapping(address => PolicyState) internal _policyStates;

    error AlreadyConfigured();
    error NotConfigured();
    error InactivePolicy();
    error BadPublicInputLength();
    error CommitmentMismatch();
    error ChainIdMismatch();
    error AccountMismatch();
    error TargetMismatch();
    error ValueMismatch();
    error CalldataHashMismatch();
    error NonEmptyCalldata();
    error InvalidOperation();
    error NonceMismatch();
    error ExpiryMismatch();
    error Expired();
    error ProofInvalid();
    error SafeCallFailed();

    event PolicyConfigured(address indexed safe, uint256 commitment);
    event PolicyReplaced(address indexed safe, uint256 commitment);
    event PolicyRevoked(address indexed safe);
    event PolicyExecuted(address indexed safe, address indexed target, uint256 value, uint256 nonce);

    constructor(address verifier_) {
        verifier = IHonkVerifier(verifier_);
    }

    function getPolicyState(address safe)
        external
        view
        returns (uint256 commitment, uint256 nonce, bool active)
    {
        PolicyState storage state = _policyStates[safe];
        return (state.commitment, state.nonce, state.active);
    }

    /// @notice Configure or reactivate a policy for a Safe. Callable only from the Safe itself.
    function configurePolicy(uint256 commitment) external {
        PolicyState storage state = _policyStates[msg.sender];
        if (state.active) revert AlreadyConfigured();

        state.commitment = commitment;
        state.active = true;
        emit PolicyConfigured(msg.sender, commitment);
    }

    /// @notice Replace the active policy commitment and invalidate outstanding proofs.
    function replacePolicy(uint256 commitment) external {
        PolicyState storage state = _policyStates[msg.sender];
        if (!state.active) revert NotConfigured();

        state.commitment = commitment;
        state.nonce += 1;
        emit PolicyReplaced(msg.sender, commitment);
    }

    /// @notice Revoke the active policy and invalidate outstanding proofs.
    function revokePolicy() external {
        PolicyState storage state = _policyStates[msg.sender];
        if (!state.active) revert NotConfigured();

        state.nonce += 1;
        state.active = false;
        emit PolicyRevoked(msg.sender);
    }

    /// @notice Execute a bound native ETH transfer through an enabled Safe module.
    function executeWithPolicy(
        address safe,
        bytes calldata proof,
        bytes32[] calldata publicInputs,
        address target,
        uint256 value,
        bytes calldata data,
        uint64 expiry,
        Enum.Operation operation
    ) external {
        PolicyState storage state = _policyStates[safe];
        if (!state.active) revert InactivePolicy();

        if (publicInputs.length != PUBLIC_INPUT_COUNT) revert BadPublicInputLength();
        if (uint256(publicInputs[0]) != state.commitment) revert CommitmentMismatch();
        if (uint256(publicInputs[1]) != block.chainid) revert ChainIdMismatch();
        if (address(uint160(uint256(publicInputs[2]))) != safe) revert AccountMismatch();
        if (address(uint160(uint256(publicInputs[3]))) != target) revert TargetMismatch();
        if (uint256(publicInputs[4]) != value) revert ValueMismatch();
        if (uint256(publicInputs[5]) != uint256(keccak256(data)) % BN254_FR) revert CalldataHashMismatch();
        if (data.length != 0) revert NonEmptyCalldata();
        if (operation != Enum.Operation.Call) revert InvalidOperation();
        if (uint256(publicInputs[6]) != state.nonce) revert NonceMismatch();
        if (uint256(publicInputs[7]) != expiry) revert ExpiryMismatch();
        if (block.timestamp > expiry) revert Expired();

        if (!verifier.verify(proof, publicInputs)) revert ProofInvalid();

        state.nonce += 1;
        if (!ISafe(safe).execTransactionFromModule(target, value, "", operation)) revert SafeCallFailed();

        emit PolicyExecuted(safe, target, value, state.nonce);
    }
}
