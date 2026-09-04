/** BN254 scalar field (Barretenberg / Noir `Field`). */
export const BN254_FR =
  21888242871839275222246405745257275088548364400416034343698204186575808495617n;

export function assertInField(value: bigint, label: string): bigint {
  if (value < 0n) {
    throw new RangeError(`${label} must be non-negative, got ${value}`);
  }
  if (value >= BN254_FR) {
    throw new RangeError(`${label} must be < BN254_Fr, got ${value}`);
  }
  return value;
}

export function toField(value: bigint, label: string): bigint {
  return assertInField(value, label);
}

export function bytes32ToField(bytes32: bigint, label: string): bigint {
  if (bytes32 < 0n || bytes32 >= 1n << 256n) {
    throw new RangeError(`${label} must fit in 32 bytes, got ${bytes32}`);
  }
  return bytes32 % BN254_FR;
}

export function fieldToHex(value: bigint): `0x${string}` {
  assertInField(value, "field");
  return `0x${value.toString(16).padStart(64, "0")}`;
}

export function parseDecimalOrHex(value: string, label: string): bigint {
  const trimmed = value.trim();
  if (trimmed.startsWith("0x") || trimmed.startsWith("0X")) {
    if (!/^0x[0-9a-fA-F]+$/i.test(trimmed)) {
      throw new TypeError(`${label} is not valid hex: ${value}`);
    }
    return BigInt(trimmed);
  }
  if (!/^[0-9]+$/.test(trimmed)) {
    throw new TypeError(`${label} is not a decimal or hex integer: ${value}`);
  }
  return BigInt(trimmed);
}
