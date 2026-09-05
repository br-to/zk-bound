import type { Address, Hex } from "./encoding.js";

export type { Address, Hex };

export type PrivatePolicy = {
  maxValue: bigint;
  allowedTarget: Address;
  policySalt: bigint;
};

/**
 * Canonical binding fields. `account` is the Safe address (`account == safe`);
 * the field name is kept for circuit / verifier compatibility.
 * Safe operation type is fixed to Call and is not part of this binding.
 */
export type TransactionBinding = {
  chainId: bigint;
  /** Safe address that will execute (`account == safe`). */
  account: Address;
  target: Address;
  value: bigint;
  calldataHash: Hex;
  nonce: bigint;
  expiry: bigint;
};

export type TransactionProposal = {
  chainId: bigint;
  /** Safe address that will execute (`account == safe`). */
  account: Address;
  target: Address;
  value: bigint;
  /** Initial Safe path: empty calldata only. */
  calldata: Hex;
  nonce: bigint;
  expiry: bigint;
};

export type PublicInputs = {
  policyCommitment: bigint;
  chainId: bigint;
  /** Safe address that will execute (`account == safe`). */
  account: Address;
  target: Address;
  value: bigint;
  calldataHash: Hex;
  nonce: bigint;
  expiry: bigint;
};

/**
 * Circuit / verifier public-input order. Solidity must pass the same sequence.
 * Safe Module keeps this 8-slot order; `account` means the Safe address.
 * `Enum.Operation.Call` is enforced at the execution boundary, not here.
 *
 * 0 policyCommitment
 * 1 chainId
 * 2 account  (Safe address)
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

/** Safe v1.4.1 `Enum.Operation.Call`; fixed for the initial native ETH path. */
export const SAFE_OPERATION_CALL = 0;

export type PolicyViolation = "value_exceeds_max" | "target_not_allowed";

export type PolicyCheck =
  | { ok: true }
  | { ok: false; reason: PolicyViolation };
