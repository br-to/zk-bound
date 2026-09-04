import {
  encodeAddress,
  encodeAddressHex,
  encodeBytes32,
  encodeUint,
  hashCalldata,
} from "./encoding.js";
import { commitPolicy } from "./commitment.js";
import type {
  PolicyCheck,
  PrivatePolicy,
  PublicInputs,
  TransactionBinding,
  TransactionProposal,
} from "./types.js";

export function bindTransaction(proposal: TransactionProposal): TransactionBinding {
  return {
    chainId: encodeUint(proposal.chainId, "chainId"),
    account: encodeAddressHex(proposal.account, "account"),
    target: encodeAddressHex(proposal.target, "target"),
    value: encodeUint(proposal.value, "value"),
    calldataHash: hashCalldata(proposal.calldata),
    nonce: encodeUint(proposal.nonce, "nonce"),
    expiry: encodeUint(proposal.expiry, "expiry"),
  };
}

export function evaluatePolicy(policy: PrivatePolicy, proposal: TransactionProposal): PolicyCheck {
  const maxValue = encodeUint(policy.maxValue, "maxValue");
  const allowedTarget = encodeAddress(policy.allowedTarget, "allowedTarget");
  const value = encodeUint(proposal.value, "value");
  const target = encodeAddress(proposal.target, "target");

  if (value > maxValue) {
    return { ok: false, reason: "value_exceeds_max" };
  }
  if (target !== allowedTarget) {
    return { ok: false, reason: "target_not_allowed" };
  }
  return { ok: true };
}

export function publicInputs(policy: PrivatePolicy, proposal: TransactionProposal): PublicInputs {
  const binding = bindTransaction(proposal);
  return {
    policyCommitment: commitPolicy(policy),
    chainId: binding.chainId,
    account: binding.account,
    target: binding.target,
    value: binding.value,
    calldataHash: binding.calldataHash,
    nonce: binding.nonce,
    expiry: binding.expiry,
  };
}

/** Field values in `PUBLIC_INPUT_ORDER` for the circuit / verifier. */
export function publicInputFields(policy: PrivatePolicy, proposal: TransactionProposal): bigint[] {
  const inputs = publicInputs(policy, proposal);
  return [
    inputs.policyCommitment,
    inputs.chainId,
    encodeAddress(inputs.account, "account"),
    encodeAddress(inputs.target, "target"),
    inputs.value,
    encodeBytes32(inputs.calldataHash, "calldataHash"),
    inputs.nonce,
    inputs.expiry,
  ];
}
