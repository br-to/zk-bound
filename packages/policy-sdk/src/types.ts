import type { Address, Hex } from "./encoding.js";

export type { Address, Hex };

export type PrivatePolicy = {
  maxValue: bigint;
  allowedTarget: Address;
  policySalt: bigint;
};

export type TransactionBinding = {
  chainId: bigint;
  account: Address;
  target: Address;
  value: bigint;
  calldataHash: Hex;
  nonce: bigint;
  expiry: bigint;
};

export type TransactionProposal = {
  chainId: bigint;
  account: Address;
  target: Address;
  value: bigint;
  calldata: Hex;
  nonce: bigint;
  expiry: bigint;
};

export type PublicInputs = {
  policyCommitment: bigint;
  chainId: bigint;
  account: Address;
  target: Address;
  value: bigint;
  calldataHash: Hex;
  nonce: bigint;
  expiry: bigint;
};

/**
 * Circuit / verifier public-input order. Solidity must pass the same sequence.
 *
 * 0 policyCommitment
 * 1 chainId
 * 2 account
 * 3 target
 * 4 value
 * 5 calldataHash  (bytes32 reduced mod BN254_Fr)
 * 6 nonce
 * 7 expiry
 */
export const PUBLIC_INPUT_ORDER = [
  "policyCommitment",
  "chainId",
  "account",
  "target",
  "value",
  "calldataHash",
  "nonce",
  "expiry",
] as const;

export type PolicyViolation = "value_exceeds_max" | "target_not_allowed";

export type PolicyCheck =
  | { ok: true }
  | { ok: false; reason: PolicyViolation };
