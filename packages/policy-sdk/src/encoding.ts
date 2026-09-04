import { keccak_256 } from "@noble/hashes/sha3.js";
import { BN254_FR, bytes32ToField, parseDecimalOrHex, toField } from "./field.js";

export type Address = `0x${string}`;
export type Hex = `0x${string}`;

const ADDRESS_RE = /^0x[0-9a-fA-F]{40}$/;
const HEX_RE = /^0x(?:[0-9a-fA-F]{2})*$/;
const BYTES32_RE = /^0x[0-9a-fA-F]{64}$/;

export function normalizeHex(value: string, label: string): Hex {
  if (!HEX_RE.test(value)) {
    throw new TypeError(`${label} must be 0x-prefixed even-length hex, got ${value}`);
  }
  return `0x${value.slice(2).toLowerCase()}`;
}

export function encodeAddress(value: string, label = "address"): bigint {
  if (!ADDRESS_RE.test(value)) {
    throw new TypeError(`${label} must be a 20-byte 0x-address, got ${value}`);
  }
  return toField(BigInt(value.toLowerCase()), label);
}

export function encodeAddressHex(value: string, label = "address"): Address {
  encodeAddress(value, label);
  return `0x${value.slice(2).toLowerCase()}`;
}

export function encodeUint(value: bigint | string, label: string): bigint {
  const parsed = typeof value === "string" ? parseDecimalOrHex(value, label) : value;
  return toField(parsed, label);
}

export function encodeBytes32(value: string, label: string): bigint {
  if (!BYTES32_RE.test(value)) {
    throw new TypeError(`${label} must be a 32-byte 0x-hex string, got ${value}`);
  }
  return bytes32ToField(BigInt(value.toLowerCase()), label);
}

export function hexToBytes(value: string, label = "hex"): Uint8Array {
  const hex = normalizeHex(value, label).slice(2);
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = Number.parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

export function bytesToHex(bytes: Uint8Array): Hex {
  return `0x${Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("")}`;
}

/** keccak256 of the complete calldata. Empty calldata is keccak256(""). */
export function hashCalldata(calldata: string): Hex {
  const digest = keccak_256(hexToBytes(calldata, "calldata"));
  return bytesToHex(digest);
}

export function hashCalldataField(calldata: string): bigint {
  return encodeBytes32(hashCalldata(calldata), "calldataHash");
}

export function keccak256Utf8(text: string): Hex {
  return bytesToHex(keccak_256(new TextEncoder().encode(text)));
}

/** Domain tag hashed into `POLICY_DOMAIN`. Change only with a version bump. */
export const POLICY_DOMAIN_TAG = "zk-agent-guard.policy.v1";

/** Poseidon2 domain separator: keccak256(tag) reduced into BN254_Fr. */
export const POLICY_DOMAIN = bytes32ToField(
  BigInt(keccak256Utf8(POLICY_DOMAIN_TAG)),
  "POLICY_DOMAIN",
);

export const EMPTY_CALLDATA_HASH = hashCalldata("0x");

export { BN254_FR };
