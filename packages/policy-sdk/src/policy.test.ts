import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import {
  EMPTY_CALLDATA_HASH,
  POLICY_DOMAIN,
  POLICY_DOMAIN_TAG,
  PUBLIC_INPUT_ORDER,
  SAFE_OPERATION_CALL,
  commitPolicy,
  encodeAddressHex,
  encodeUint,
  evaluatePolicy,
  fieldToHex,
  hashCalldata,
  poseidon2HashFields,
  publicInputFields,
} from "./index.js";
import type { PrivatePolicy, TransactionProposal } from "./types.js";

type SafeOperation = {
  to: string;
  value: string;
  data: string;
  operation: "Call";
  operationEnum: number;
};

type VectorFile = {
  version: number;
  encoding: {
    account: string;
    safeOperation: {
      operation: "Call";
      operationEnum: number;
      data: string;
    };
    publicInputOrder: string[];
  };
  constants: {
    domainTag: string;
    domain: string;
    emptyCalldataHash: string;
    emptyCalldataHashField: string;
    poseidon2_1_2_3: string;
    poseidon2_1_2_3_4_5: string;
    safeOperationCall: number;
  };
  policy: {
    maxValue: string;
    allowedTarget: string;
    policySalt: string;
    policyCommitment: string;
  };
  vectors: Array<{
    id: string;
    expect: "allow" | "reject";
    reason?: "value_exceeds_max" | "target_not_allowed";
    transaction: {
      chainId: string;
      account: string;
      target: string;
      value: string;
      calldata: string;
      operation: "Call";
      nonce: string;
      expiry: string;
    };
    safeOperation: SafeOperation;
    expected: {
      satisfiesPolicy: boolean;
      calldataHash: string;
      publicInputs?: string[];
    };
  }>;
};

const vectorsPath = join(dirname(fileURLToPath(import.meta.url)), "../test-vectors/policy.json");
const fixtures = JSON.parse(readFileSync(vectorsPath, "utf8")) as VectorFile;

const policy: PrivatePolicy = {
  maxValue: encodeUint(fixtures.policy.maxValue, "maxValue"),
  allowedTarget: encodeAddressHex(fixtures.policy.allowedTarget, "allowedTarget"),
  policySalt: encodeUint(fixtures.policy.policySalt, "policySalt"),
};

function proposalOf(tx: VectorFile["vectors"][number]["transaction"]): TransactionProposal {
  return {
    chainId: encodeUint(tx.chainId, "chainId"),
    account: encodeAddressHex(tx.account, "account"),
    target: encodeAddressHex(tx.target, "target"),
    value: encodeUint(tx.value, "value"),
    calldata: tx.calldata as `0x${string}`,
    nonce: encodeUint(tx.nonce, "nonce"),
    expiry: encodeUint(tx.expiry, "expiry"),
  };
}

test("Poseidon2 matches Noir stdlib digest for [1,2,3,4,5]", () => {
  assert.equal(fieldToHex(poseidon2HashFields([1n, 2n, 3n, 4n, 5n])), fixtures.constants.poseidon2_1_2_3_4_5);
});

test("Poseidon2 [1,2,3] is locked", () => {
  assert.equal(fieldToHex(poseidon2HashFields([1n, 2n, 3n])), fixtures.constants.poseidon2_1_2_3);
});

test("domain tag and empty calldata hash are locked", () => {
  assert.equal(POLICY_DOMAIN_TAG, fixtures.constants.domainTag);
  assert.equal(fieldToHex(POLICY_DOMAIN), fixtures.constants.domain);
  assert.equal(EMPTY_CALLDATA_HASH, fixtures.constants.emptyCalldataHash);
  assert.equal(hashCalldata("0x"), fixtures.constants.emptyCalldataHash);
});

test("Safe Call binding metadata is locked", () => {
  assert.equal(fixtures.version, 2);
  assert.deepEqual(fixtures.encoding.publicInputOrder, [...PUBLIC_INPUT_ORDER]);
  assert.match(fixtures.encoding.account, /Safe address/);
  assert.equal(fixtures.encoding.safeOperation.operation, "Call");
  assert.equal(fixtures.encoding.safeOperation.operationEnum, SAFE_OPERATION_CALL);
  assert.equal(fixtures.encoding.safeOperation.data, "0x");
  assert.equal(fixtures.constants.safeOperationCall, SAFE_OPERATION_CALL);
  assert.equal(SAFE_OPERATION_CALL, 0);
});

test("policy commitment is locked", () => {
  assert.equal(fieldToHex(commitPolicy(policy)), fixtures.policy.policyCommitment);
});

test("changing policySalt changes the commitment", () => {
  const other = commitPolicy({ ...policy, policySalt: policy.policySalt + 1n });
  assert.notEqual(other, commitPolicy(policy));
});

for (const vector of fixtures.vectors) {
  test(`vector ${vector.id}`, () => {
    const proposal = proposalOf(vector.transaction);
    const check = evaluatePolicy(policy, proposal);
    assert.equal(check.ok, vector.expected.satisfiesPolicy);
    if (check.ok) {
      assert.equal(vector.expected.satisfiesPolicy, true);
    } else {
      assert.equal(check.reason, vector.reason);
    }
    assert.equal(vector.transaction.operation, "Call");
    assert.equal(vector.transaction.calldata, "0x");
    assert.equal(vector.safeOperation.operation, "Call");
    assert.equal(vector.safeOperation.operationEnum, SAFE_OPERATION_CALL);
    assert.equal(vector.safeOperation.data, "0x");
    assert.equal(vector.safeOperation.to, vector.transaction.target);
    assert.equal(vector.safeOperation.value, vector.transaction.value);
    assert.equal(hashCalldata(vector.transaction.calldata), vector.expected.calldataHash);
    if (vector.expected.publicInputs) {
      const fields = publicInputFields(policy, proposal).map((value) => fieldToHex(value));
      assert.deepEqual(fields, vector.expected.publicInputs);
      assert.equal(fields.length, PUBLIC_INPUT_ORDER.length);
    }
  });
}
