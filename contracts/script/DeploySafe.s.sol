// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { Safe } from "safe-smart-account/Safe.sol";
import { SafeProxyFactory } from "safe-smart-account/proxies/SafeProxyFactory.sol";
import { SafeProxy } from "safe-smart-account/proxies/SafeProxy.sol";
import { Enum } from "safe-smart-account/common/Enum.sol";
import { HonkVerifier } from "../src/verifier/HonkVerifier.sol";
import { ZkPolicySafeModule } from "../src/ZkPolicySafeModule.sol";

/// @notice Deploy HonkVerifier + ZkPolicySafeModule + funded Safe (v1.4.1) for Anvil demo.
/// @dev Uses Safe pre-validated signatures (v=1) so the broadcasting owner can enable the
///      module and configure policy without building EIP-712 signatures in the script.
contract DeploySafe is Script {
    uint256 internal constant COMMITMENT =
        0x10ab3b74faac7b7dbead3e6901e341220f41a0130935d19b3604b680eadd3026;
    bytes4 internal constant ENABLE_MODULE_SELECTOR = bytes4(keccak256("enableModule(address)"));

    function run() external {
        address owner = msg.sender;
        vm.startBroadcast();

        HonkVerifier verifier = new HonkVerifier();
        ZkPolicySafeModule module = new ZkPolicySafeModule(address(verifier));
        Safe safe = _deploySafe(owner);

        _execAsOwner(
            safe, owner, address(safe), abi.encodeWithSelector(ENABLE_MODULE_SELECTOR, address(module))
        );
        _execAsOwner(
            safe, owner, address(module), abi.encodeWithSelector(module.configurePolicy.selector, COMMITMENT)
        );

        (bool funded,) = address(safe).call{ value: 10 ether }("");
        require(funded, "fund");
        vm.stopBroadcast();

        require(safe.isModuleEnabled(address(module)), "module");
        (uint256 commitment, uint256 nonce, bool active) = module.getPolicyState(address(safe));
        require(active && commitment == COMMITMENT && nonce == 0, "policy");

        console.log("verifier", address(verifier));
        console.log("module", address(module));
        console.log("safe", address(safe));
        console.log("owner", owner);
        console.log("commitment", commitment);
    }

    function _deploySafe(address owner) internal returns (Safe safe) {
        Safe singleton = new Safe();
        SafeProxyFactory factory = new SafeProxyFactory();
        address[] memory owners = new address[](1);
        owners[0] = owner;
        bytes memory initializer = abi.encodeWithSelector(
            Safe.setup.selector,
            owners,
            uint256(1),
            address(0),
            "",
            address(0),
            address(0),
            uint256(0),
            payable(address(0))
        );
        SafeProxy proxy = factory.createProxyWithNonce(address(singleton), initializer, uint256(0));
        safe = Safe(payable(address(proxy)));
    }

    function _execAsOwner(Safe safe, address owner, address to, bytes memory data) internal {
        // Pre-validated signature: r = owner, s = 0, v = 1 (msg.sender must be owner).
        bytes memory signatures = abi.encodePacked(bytes32(uint256(uint160(owner))), bytes32(0), uint8(1));
        bool ok = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), signatures
        );
        require(ok, "safe exec");
    }
}
