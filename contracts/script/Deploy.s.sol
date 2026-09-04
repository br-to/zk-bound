// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { PolicyAccount } from "../src/PolicyAccount.sol";
import { HonkVerifier } from "../src/verifier/HonkVerifier.sol";

/// @notice Deploy the generated verifier and a funded PolicyAccount on Anvil.
contract Deploy is Script {
    uint256 internal constant COMMITMENT =
        0x10ab3b74faac7b7dbead3e6901e341220f41a0130935d19b3604b680eadd3026;

    function run() external {
        vm.startBroadcast();
        HonkVerifier verifier = new HonkVerifier();
        PolicyAccount account = new PolicyAccount(address(verifier), msg.sender, COMMITMENT);
        (bool funded,) = address(account).call{ value: 10 ether }("");
        require(funded, "fund");
        vm.stopBroadcast();

        console.log("verifier", address(verifier));
        console.log("account", address(account));
        console.log("owner", account.owner());
        console.log("commitment", account.policyCommitment());
    }
}
