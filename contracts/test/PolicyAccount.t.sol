// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { PolicyAccount } from "../src/PolicyAccount.sol";
import { HonkVerifier } from "../src/verifier/HonkVerifier.sol";

contract PolicyAccountTest is Test {
    uint256 internal constant COMMITMENT =
        0x10ab3b74faac7b7dbead3e6901e341220f41a0130935d19b3604b680eadd3026;
    address internal constant ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address internal constant TARGET = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    uint256 internal constant VALUE = 0.5 ether;
    uint64 internal constant EXPIRY = 2_000_000_000;

    HonkVerifier internal honk;
    PolicyAccount internal account;
    bytes internal proof;
    bytes32[] internal publicInputs;

    function setUp() public {
        honk = new HonkVerifier();
        PolicyAccount impl = new PolicyAccount(address(honk), address(this), COMMITMENT);
        vm.etch(ACCOUNT, address(impl).code);
        account = PolicyAccount(payable(ACCOUNT));
        vm.deal(ACCOUNT, 10 ether);

        proof = vm.readFileBinary(string.concat(vm.projectRoot(), "/test/fixtures/allow.proof.bin"));
        publicInputs.push(bytes32(uint256(COMMITMENT)));
        publicInputs.push(bytes32(uint256(31337)));
        publicInputs.push(bytes32(uint256(uint160(ACCOUNT))));
        publicInputs.push(bytes32(uint256(uint160(TARGET))));
        publicInputs.push(bytes32(VALUE));
        publicInputs.push(bytes32(uint256(0x04410c360230a295b13d66d8d6c1a24c44311531e39c64f66c7301b49d85a46c)));
        publicInputs.push(bytes32(uint256(0)));
        publicInputs.push(bytes32(uint256(EXPIRY)));
    }

    function test_honkVerifierAcceptsAllowProof() public view {
        assertTrue(honk.verify(proof, publicInputs));
    }

    function test_honkVerifierRejectsTamperedProof() public {
        bytes memory bad = proof;
        bad[100] = bytes1(uint8(bad[100]) ^ 0x01);
        vm.expectRevert();
        honk.verify(bad, publicInputs);
    }

    function test_executeSendsEth() public {
        uint256 beforeBal = TARGET.balance;
        account.execute(proof, publicInputs, TARGET, VALUE, "", EXPIRY);
        assertEq(TARGET.balance, beforeBal + VALUE);
        assertEq(account.nonce(), 1);
    }

    function test_executeRejectsWrongTarget() public {
        address thief = address(0xBEEF);
        vm.expectRevert(PolicyAccount.TargetMismatch.selector);
        account.execute(proof, publicInputs, thief, VALUE, "", EXPIRY);
    }

    function test_executeRejectsWrongValue() public {
        vm.expectRevert(PolicyAccount.ValueMismatch.selector);
        account.execute(proof, publicInputs, TARGET, VALUE + 1, "", EXPIRY);
    }

    function test_executeRejectsReplay() public {
        account.execute(proof, publicInputs, TARGET, VALUE, "", EXPIRY);
        vm.expectRevert(PolicyAccount.NonceMismatch.selector);
        account.execute(proof, publicInputs, TARGET, VALUE, "", EXPIRY);
    }

    function test_executeRejectsExpired() public {
        vm.warp(uint256(EXPIRY) + 1);
        vm.expectRevert(PolicyAccount.Expired.selector);
        account.execute(proof, publicInputs, TARGET, VALUE, "", EXPIRY);
    }
}
