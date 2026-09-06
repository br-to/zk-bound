// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { Safe } from "safe-smart-account/Safe.sol";
import { SafeProxyFactory } from "safe-smart-account/proxies/SafeProxyFactory.sol";
import { SafeProxy } from "safe-smart-account/proxies/SafeProxy.sol";
import { Enum } from "safe-smart-account/common/Enum.sol";
import { ZkPolicySafeModule } from "../src/ZkPolicySafeModule.sol";
import { HonkVerifier } from "../src/verifier/HonkVerifier.sol";

contract ZkPolicySafeModuleTest is Test {
    uint256 internal constant COMMITMENT =
        0x10ab3b74faac7b7dbead3e6901e341220f41a0130935d19b3604b680eadd3026;
    address internal constant ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address internal constant TARGET = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    uint256 internal constant VALUE = 0.5 ether;
    uint64 internal constant EXPIRY = 2_000_000_000;

    HonkVerifier internal honk;
    ZkPolicySafeModule internal module;
    Safe internal safe;
    bytes internal proof;
    bytes32[] internal publicInputs;

    function setUp() public {
        honk = new HonkVerifier();
        module = new ZkPolicySafeModule(address(honk));
        safe = _installSafeAtAccount(ACCOUNT, address(this));
        vm.deal(ACCOUNT, 10 ether);

        vm.prank(ACCOUNT);
        safe.enableModule(address(module));

        vm.prank(ACCOUNT);
        module.configurePolicy(COMMITMENT);

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

    function test_executeWithPolicySendsEth() public {
        uint256 beforeBal = TARGET.balance;
        module.executeWithPolicy(ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call);
        assertEq(TARGET.balance, beforeBal + VALUE);
        (uint256 commitment, uint256 nonce, bool active) = module.getPolicyState(ACCOUNT);
        assertEq(commitment, COMMITMENT);
        assertEq(nonce, 1);
        assertTrue(active);
    }

    function test_executeWithPolicyRejectsWrongTarget() public {
        address thief = address(0xBEEF);
        vm.expectRevert(ZkPolicySafeModule.TargetMismatch.selector);
        module.executeWithPolicy(ACCOUNT, proof, publicInputs, thief, VALUE, "", EXPIRY, Enum.Operation.Call);
    }

    function test_executeWithPolicyRejectsWrongValue() public {
        vm.expectRevert(ZkPolicySafeModule.ValueMismatch.selector);
        module.executeWithPolicy(ACCOUNT, proof, publicInputs, TARGET, VALUE + 1, "", EXPIRY, Enum.Operation.Call);
    }

    function test_executeWithPolicyRejectsReplay() public {
        module.executeWithPolicy(ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call);
        vm.expectRevert(ZkPolicySafeModule.NonceMismatch.selector);
        module.executeWithPolicy(ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call);
    }

    function test_executeWithPolicyRejectsExpired() public {
        vm.warp(uint256(EXPIRY) + 1);
        vm.expectRevert(ZkPolicySafeModule.Expired.selector);
        module.executeWithPolicy(ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call);
    }

    function test_executeWithPolicyRejectsInactivePolicy() public {
        vm.prank(ACCOUNT);
        module.revokePolicy();
        vm.expectRevert(ZkPolicySafeModule.InactivePolicy.selector);
        module.executeWithPolicy(ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call);
    }

    function test_executeWithPolicyRejectsDisabledModule() public {
        vm.prank(ACCOUNT);
        safe.disableModule(address(0x1), address(module));
        vm.expectRevert();
        module.executeWithPolicy(ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call);
    }


    function test_configureReplaceRevoke() public {
        address other = address(0xCAFE);
        Safe otherSafe = _installSafeAtAccount(other, address(this));
        vm.deal(other, 1 ether);
        vm.prank(other);
        otherSafe.enableModule(address(module));

        vm.prank(other);
        module.configurePolicy(COMMITMENT);
        (uint256 c0, uint256 n0, bool a0) = module.getPolicyState(other);
        assertEq(c0, COMMITMENT);
        assertEq(n0, 0);
        assertTrue(a0);

        uint256 nextCommitment = COMMITMENT + 1;
        vm.prank(other);
        module.replacePolicy(nextCommitment);
        (uint256 c1, uint256 n1, bool a1) = module.getPolicyState(other);
        assertEq(c1, nextCommitment);
        assertEq(n1, 1);
        assertTrue(a1);

        vm.prank(other);
        module.revokePolicy();
        (, uint256 n2, bool a2) = module.getPolicyState(other);
        assertEq(n2, 2);
        assertFalse(a2);
    }

    function test_replacePolicyInvalidatesOutstandingProof() public {
        vm.startPrank(ACCOUNT);
        module.replacePolicy(COMMITMENT + 1);
        module.replacePolicy(COMMITMENT);
        vm.stopPrank();

        vm.expectRevert(ZkPolicySafeModule.NonceMismatch.selector);
        module.executeWithPolicy(
            ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call
        );
    }

    function test_revokeAndReconfigureInvalidatesOutstandingProof() public {
        vm.startPrank(ACCOUNT);
        module.revokePolicy();
        module.configurePolicy(COMMITMENT);
        vm.stopPrank();

        vm.expectRevert(ZkPolicySafeModule.NonceMismatch.selector);
        module.executeWithPolicy(
            ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call
        );
    }

    function test_executeWithPolicyRejectsNonEmptyCalldata() public {
        vm.expectRevert(ZkPolicySafeModule.CalldataHashMismatch.selector);
        module.executeWithPolicy(
            ACCOUNT, proof, publicInputs, TARGET, VALUE, hex"01", EXPIRY, Enum.Operation.Call
        );
    }

    function test_executeWithPolicyRejectsDelegateCall() public {
        vm.expectRevert(ZkPolicySafeModule.InvalidOperation.selector);
        module.executeWithPolicy(
            ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.DelegateCall
        );
    }

    function test_executeWithPolicyRejectsWrongAccount() public {
        bytes32[] memory pubs = publicInputs;
        pubs[2] = bytes32(uint256(uint160(address(0xB0B))));
        vm.expectRevert(ZkPolicySafeModule.AccountMismatch.selector);
        module.executeWithPolicy(
            ACCOUNT, proof, pubs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call
        );
    }

    function test_executeWithPolicyRejectsWrongChainId() public {
        bytes32[] memory pubs = publicInputs;
        pubs[1] = bytes32(uint256(1));
        vm.expectRevert(ZkPolicySafeModule.ChainIdMismatch.selector);
        module.executeWithPolicy(
            ACCOUNT, proof, pubs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call
        );
    }

    function test_executeWithPolicyRejectsSafeCallFailed() public {
        vm.deal(ACCOUNT, 0);
        vm.expectRevert(ZkPolicySafeModule.SafeCallFailed.selector);
        module.executeWithPolicy(
            ACCOUNT, proof, publicInputs, TARGET, VALUE, "", EXPIRY, Enum.Operation.Call
        );
    }

    function _deploySafe(address owner) internal returns (Safe deployed) {
        Safe singleton = new Safe();
        SafeProxyFactory factory = new SafeProxyFactory();
        address[] memory owners = new address[](1);
        owners[0] = owner;
        bytes memory initializer = abi.encodeWithSelector(
            Safe.setup.selector,
            owners,
            1,
            address(0),
            "",
            address(0),
            address(0),
            0,
            address(0)
        );
        SafeProxy proxy = factory.createProxyWithNonce(address(singleton), initializer, 0);
        deployed = Safe(payable(address(proxy)));
    }

    function _installSafeAtAccount(address account, address owner) internal returns (Safe installed) {
        Safe temp = _deploySafe(owner);
        vm.etch(account, address(temp).code);
        vm.copyStorage(address(temp), account);
        installed = Safe(payable(account));
    }
}
