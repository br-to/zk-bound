import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { encodeAddressHex, encodeUint } from "@zk-agent-guard/policy-sdk";
import type { PrivatePolicy } from "@zk-agent-guard/policy-sdk";

export type VectorFile = {
  policy: {
    maxValue: string;
    allowedTarget: string;
    policySalt: string;
    policyCommitment: string;
  };
  vectors: Array<{
    id: string;
    expect: "allow" | "reject";
    transaction: {
      chainId: string;
      account: string;
      target: string;
      value: string;
      calldata: `0x${string}`;
      nonce: string;
      expiry: string;
    };
  }>;
};

export function loadVectors(): VectorFile {
  const vectorsPath = join(
    dirname(fileURLToPath(import.meta.url)),
    "../../../packages/policy-sdk/test-vectors/policy.json",
  );
  return JSON.parse(readFileSync(vectorsPath, "utf8")) as VectorFile;
}

export function loadPolicy(fixtures: VectorFile): PrivatePolicy {
  return {
    maxValue: encodeUint(fixtures.policy.maxValue, "maxValue"),
    allowedTarget: encodeAddressHex(fixtures.policy.allowedTarget, "allowedTarget"),
    policySalt: encodeUint(fixtures.policy.policySalt, "policySalt"),
  };
}
