import { poseidon2Hash } from "@zkpassport/poseidon2";
import { POLICY_DOMAIN, encodeAddress, encodeUint } from "./encoding.js";
import { fieldToHex } from "./field.js";
import type { PrivatePolicy } from "./types.js";

/**
 * Poseidon2 sponge used by `@zkpassport/poseidon2` / Aztec:
 * `iv = (input_len << 64) + (out_len - 1)`, rate = 3, t = 4.
 *
 * Do not use Noir 1.0.0-beta.22 `Poseidon2Hasher` for 4 inputs — that hasher
 * re-absorbs the first leftover slot instead of the tail, so `policySalt` would
 * be dropped. The circuit reimplements this sponge with `poseidon2_permutation`.
 */
export function poseidon2HashFields(inputs: readonly bigint[]): bigint {
  return poseidon2Hash([...inputs]);
}

export function commitPolicy(policy: PrivatePolicy): bigint {
  return poseidon2HashFields([
    POLICY_DOMAIN,
    encodeUint(policy.maxValue, "maxValue"),
    encodeAddress(policy.allowedTarget, "allowedTarget"),
    encodeUint(policy.policySalt, "policySalt"),
  ]);
}

export function commitPolicyHex(policy: PrivatePolicy): `0x${string}` {
  return fieldToHex(commitPolicy(policy));
}
