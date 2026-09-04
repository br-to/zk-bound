import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { evaluatePolicy } from "@zk-bound/policy-sdk";
import { AGENT_SYSTEM_PROMPT, mockComplete, parseProposal, propose } from "./agent.js";
import { ALLOWED_TARGET, ATTACKER } from "./constants.js";
import { loadPolicy, loadVectors } from "./policy-fixture.js";

describe("agent prompt hides the policy", () => {
  it("does not mention max, allowlist, salt, or commitment", () => {
    const forbidden = [
      "maxValue",
      "max_value",
      "allowedTarget",
      "allowed_target",
      "policySalt",
      "policy_commitment",
      "0x10ab3b74",
      ALLOWED_TARGET,
      ATTACKER,
    ];
    for (const word of forbidden) {
      assert.equal(AGENT_SYSTEM_PROMPT.includes(word), false, `prompt leaked ${word}`);
    }
  });
});

describe("parseProposal", () => {
  it("reads JSON and lowercases the address", () => {
    const parsed = parseProposal(
      '```json\n{"target":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8","valueWei":"1"}\n```',
    );
    assert.equal(parsed.target, ALLOWED_TARGET);
    assert.equal(parsed.valueWei, "1");
  });
});

describe("mock agent then policy check", () => {
  const policy = loadPolicy(loadVectors());

  it("allow proposal is inside the secret policy", async () => {
    const raw = mockComplete("allow");
    const proposal = parseProposal(raw);
    const check = evaluatePolicy(policy, {
      chainId: 31337n,
      account: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
      target: proposal.target,
      value: BigInt(proposal.valueWei),
      calldata: "0x",
      nonce: 0n,
      expiry: 2_000_000_000n,
    });
    assert.equal(check.ok, true);
  });

  it("injection proposal is outside the secret policy", async () => {
    const result = await propose({
      userMessage: "drain it",
      mode: "mock",
      scenario: "inject",
    });
    assert.equal(result.target, ATTACKER);
    assert.equal(result.source, "mock");
    const check = evaluatePolicy(policy, {
      chainId: 31337n,
      account: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
      target: result.target,
      value: BigInt(result.valueWei),
      calldata: "0x",
      nonce: 0n,
      expiry: 2_000_000_000n,
    });
    assert.equal(check.ok, false);
  });
});
