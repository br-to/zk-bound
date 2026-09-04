// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { PolicyAccount } from "../src/PolicyAccount.sol";

/// @notice Submit a bound UltraHonk proof to PolicyAccount.execute.
contract Execute is Script {
    uint256 internal constant COMMITMENT =
        0x10ab3b74faac7b7dbead3e6901e341220f41a0130935d19b3604b680eadd3026;
    uint256 internal constant EMPTY_CALLDATA_FIELD =
        0x04410c360230a295b13d66d8d6c1a24c44311531e39c64f66c7301b49d85a46c;

    function run(
        address payable account,
        address target,
        uint256 value,
        uint64 expiry,
        string memory proofPath
    ) external {
        bytes memory proof = vm.readFileBinary(proofPath);
        bytes32[] memory pubs = _publicInputs(account, target, value, expiry);

        vm.startBroadcast();
        PolicyAccount(account).execute(proof, pubs, target, value, "", expiry);
        vm.stopBroadcast();

        console.log("nonce after", PolicyAccount(account).nonce());
    }

    function _publicInputs(address account, address target, uint256 value, uint64 expiry)
        internal
        view
        returns (bytes32[] memory pubs)
    {
        pubs = new bytes32[](8);
        pubs[0] = bytes32(COMMITMENT);
        pubs[1] = bytes32(uint256(block.chainid));
        pubs[2] = bytes32(uint256(uint160(account)));
        pubs[3] = bytes32(uint256(uint160(target)));
        pubs[4] = bytes32(value);
        pubs[5] = bytes32(EMPTY_CALLDATA_FIELD);
        pubs[6] = bytes32(PolicyAccount(payable(account)).nonce());
        pubs[7] = bytes32(uint256(expiry));
    }
}

/// @notice Reuse an allow proof but swap the execute target. Must revert.
contract ExecuteWrongTarget is Script {
    uint256 internal constant COMMITMENT =
        0x10ab3b74faac7b7dbead3e6901e341220f41a0130935d19b3604b680eadd3026;
    uint256 internal constant EMPTY_CALLDATA_FIELD =
        0x04410c360230a295b13d66d8d6c1a24c44311531e39c64f66c7301b49d85a46c;

    function run(
        address payable account,
        address allowedTarget,
        address thief,
        uint256 value,
        uint64 expiry,
        string memory proofPath
    ) external {
        bytes memory proof = vm.readFileBinary(proofPath);
        bytes32[] memory pubs = new bytes32[](8);
        pubs[0] = bytes32(COMMITMENT);
        pubs[1] = bytes32(uint256(block.chainid));
        pubs[2] = bytes32(uint256(uint160(address(account))));
        pubs[3] = bytes32(uint256(uint160(allowedTarget)));
        pubs[4] = bytes32(value);
        pubs[5] = bytes32(EMPTY_CALLDATA_FIELD);
        pubs[6] = bytes32(PolicyAccount(account).nonce());
        pubs[7] = bytes32(uint256(expiry));

        vm.startBroadcast();
        PolicyAccount(account).execute(proof, pubs, thief, value, "", expiry);
        vm.stopBroadcast();
    }
}
