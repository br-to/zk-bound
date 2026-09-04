import { commitPolicyHex, encodeAddressHex, encodeUint, evaluatePolicy } from "@zk-bound/policy-sdk";
import type { TransactionProposal } from "@zk-bound/policy-sdk";
import { loadPolicy, loadVectors } from "./policy-fixture.js";

const fixtures = loadVectors();
const policy = loadPolicy(fixtures);

const commitment = commitPolicyHex(policy);
console.log("policyCommitment", commitment);
console.log("matches locked vector", commitment === fixtures.policy.policyCommitment);

for (const vector of fixtures.vectors) {
  const proposal: TransactionProposal = {
    chainId: encodeUint(vector.transaction.chainId, "chainId"),
    account: encodeAddressHex(vector.transaction.account, "account"),
    target: encodeAddressHex(vector.transaction.target, "target"),
    value: encodeUint(vector.transaction.value, "value"),
    calldata: vector.transaction.calldata,
    nonce: encodeUint(vector.transaction.nonce, "nonce"),
    expiry: encodeUint(vector.transaction.expiry, "expiry"),
  };
  const check = evaluatePolicy(policy, proposal);
  const verdict = check.ok ? "ALLOW" : `REJECT (${check.reason})`;
  const matched = check.ok === (vector.expect === "allow");
  console.log(`${matched ? "ok" : "FAIL"}  ${vector.id}: ${verdict}`);
}
