// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { Enum } from "safe-smart-account/common/Enum.sol";
import { ZkPolicySafeModule } from "../src/ZkPolicySafeModule.sol";

/// @notice Submit a bound UltraHonk proof via ZkPolicySafeModule.executeWithPolicy.
contract ExecuteSafe is Script {
    uint256 internal constant COMMITMENT =
        0x10ab3b74faac7b7dbead3e6901e341220f41a0130935d19b3604b680eadd3026;
    uint256 internal constant EMPTY_CALLDATA_FIELD =
        0x04410c360230a295b13d66d8d6c1a24c44311531e39c64f66c7301b49d85a46c;

    function run(
        address module,
        address safe,
        address target,
        uint256 value,
        uint64 expiry,
        string memory proofPath
    ) external {
        bytes memory proof = vm.readFileBinary(proofPath);
        bytes32[] memory pubs = _publicInputs(module, safe, target, value, expiry);

        vm.startBroadcast();
        ZkPolicySafeModule(module).executeWithPolicy(
            safe, proof, pubs, target, value, "", expiry, Enum.Operation.Call
        );
        vm.stopBroadcast();

        (, uint256 nonce,) = ZkPolicySafeModule(module).getPolicyState(safe);
        console.log("nonce after", nonce);
    }

    function _publicInputs(
        address module,
        address safe,
        address target,
        uint256 value,
        uint64 expiry
    ) internal view returns (bytes32[] memory pubs) {
        (, uint256 nonce,) = ZkPolicySafeModule(module).getPolicyState(safe);
        pubs = new bytes32[](8);
        pubs[0] = bytes32(COMMITMENT);
        pubs[1] = bytes32(uint256(block.chainid));
        pubs[2] = bytes32(uint256(uint160(safe)));
        pubs[3] = bytes32(uint256(uint160(target)));
        pubs[4] = bytes32(value);
        pubs[5] = bytes32(EMPTY_CALLDATA_FIELD);
        pubs[6] = bytes32(nonce);
        pubs[7] = bytes32(uint256(expiry));
    }
}

/// @notice Reuse an allow proof but swap the execute target. Must revert TargetMismatch.
contract ExecuteSafeWrongTarget is Script {
    uint256 internal constant COMMITMENT =
        0x10ab3b74faac7b7dbead3e6901e341220f41a0130935d19b3604b680eadd3026;
    uint256 internal constant EMPTY_CALLDATA_FIELD =
        0x04410c360230a295b13d66d8d6c1a24c44311531e39c64f66c7301b49d85a46c;

    function run(
        address module,
        address safe,
        address allowedTarget,
        address thief,
        uint256 value,
        uint64 expiry,
        string memory proofPath
    ) external {
        bytes memory proof = vm.readFileBinary(proofPath);
        (, uint256 nonce,) = ZkPolicySafeModule(module).getPolicyState(safe);
        bytes32[] memory pubs = new bytes32[](8);
        pubs[0] = bytes32(COMMITMENT);
        pubs[1] = bytes32(uint256(block.chainid));
        pubs[2] = bytes32(uint256(uint160(safe)));
        pubs[3] = bytes32(uint256(uint160(allowedTarget)));
        pubs[4] = bytes32(value);
        pubs[5] = bytes32(EMPTY_CALLDATA_FIELD);
        pubs[6] = bytes32(nonce);
        pubs[7] = bytes32(uint256(expiry));

        vm.startBroadcast();
        ZkPolicySafeModule(module).executeWithPolicy(
            safe, proof, pubs, thief, value, "", expiry, Enum.Operation.Call
        );
        vm.stopBroadcast();
    }
}
