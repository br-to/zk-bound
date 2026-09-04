import { writeFileSync } from "node:fs";
import {
  encodeAddress,
  encodeAddressHex,
  encodeUint,
  evaluatePolicy,
  fieldToHex,
  hashCalldataField,
  publicInputFields,
} from "@zk-agent-guard/policy-sdk";
import type { PrivatePolicy, TransactionProposal } from "@zk-agent-guard/policy-sdk";
import { ALLOWED_TARGET, ALLOW_VALUE_WEI, ATTACKER, CHAIN_ID, EXPIRY, STEAL_VALUE_WEI } from "./constants.js";
import { loadPolicy, loadVectors } from "./policy-fixture.js";

type Mode = "allow-prover" | "reject-prover" | "write-prover" | "check";

function arg(name: string): string {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1 || idx + 1 >= process.argv.length) {
    throw new Error(`missing --${name}`);
  }
  return process.argv[idx + 1] ?? "";
}

function optionalArg(name: string): string | undefined {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1 || idx + 1 >= process.argv.length) {
    return undefined;
  }
  return process.argv[idx + 1];
}

function modeFromArgv(): Mode {
  const mode = process.argv[2];
  if (
    mode === "allow-prover" ||
    mode === "reject-prover" ||
    mode === "write-prover" ||
    mode === "check"
  ) {
    return mode;
  }
  throw new Error("usage: anvil.ts <write-prover|allow-prover|reject-prover|check> --account 0x...");
}

function proposalFrom(
  account: string,
  target: string,
  valueWei: string,
  nonce: bigint,
): TransactionProposal {
  return {
    chainId: CHAIN_ID,
    account: encodeAddressHex(account, "account"),
    target: encodeAddressHex(target, "target"),
    value: encodeUint(valueWei, "value"),
    calldata: "0x",
    nonce,
    expiry: EXPIRY,
  };
}

function writeProverToml(
  path: string,
  policy: PrivatePolicy,
  proposal: TransactionProposal,
  commitment: bigint,
): void {
  const body = [
    `max_value = "${policy.maxValue.toString()}"`,
    `allowed_target = "${policy.allowedTarget}"`,
    `policy_salt = "${policy.policySalt.toString()}"`,
    `policy_commitment = "${fieldToHex(commitment)}"`,
    `chain_id = "${proposal.chainId.toString()}"`,
    `account = "${proposal.account}"`,
    `target = "${proposal.target}"`,
    `value = "${proposal.value.toString()}"`,
    `calldata_hash = "${fieldToHex(hashCalldataField(proposal.calldata))}"`,
    `nonce = "${proposal.nonce.toString()}"`,
    `expiry = "${proposal.expiry.toString()}"`,
    "",
  ].join("\n");
  writeFileSync(path, body);
}

function emitProver(
  policy: PrivatePolicy,
  proposal: TransactionProposal,
  proverPath: string,
  extra: Record<string, unknown>,
): void {
  const check = evaluatePolicy(policy, proposal);
  const inputs = publicInputFields(policy, proposal);
  writeProverToml(proverPath, policy, proposal, inputs[0] ?? 0n);
  console.log(JSON.stringify({
    ...extra,
    ok: check.ok,
    reason: check.ok ? null : check.reason,
    target: proposal.target,
    value: proposal.value.toString(),
    publicInputs: inputs.map((field) => fieldToHex(field)),
    valueExceedsMax: proposal.value > encodeUint(policy.maxValue, "maxValue"),
    targetAllowed:
      encodeAddress(proposal.target, "target") === encodeAddress(policy.allowedTarget, "allowedTarget"),
  }));
}

function main(): void {
  const mode = modeFromArgv();
  const fixtures = loadVectors();
  const policy = loadPolicy(fixtures);
  const account = arg("account");
  const nonce = BigInt(optionalArg("nonce") ?? "0");
  const proverPath = optionalArg("prover") ?? "";

  if (mode === "write-prover") {
    if (!proverPath) {
      throw new Error("missing --prover");
    }
    emitProver(
      policy,
      proposalFrom(account, arg("target"), arg("value"), nonce),
      proverPath,
      { role: "prover" },
    );
    return;
  }

  if (mode === "allow-prover") {
    if (!proverPath) {
      throw new Error("missing --prover");
    }
    emitProver(
      policy,
      proposalFrom(account, ALLOWED_TARGET, ALLOW_VALUE_WEI, nonce),
      proverPath,
      { role: "agent", id: "allow-native-transfer", expect: "allow" },
    );
    return;
  }

  if (mode === "reject-prover") {
    if (!proverPath) {
      throw new Error("missing --prover");
    }
    emitProver(
      policy,
      proposalFrom(account, ATTACKER, STEAL_VALUE_WEI, nonce),
      proverPath,
      { role: "agent", id: "prompt-injection-drain", expect: "reject" },
    );
    return;
  }

  const proposal = proposalFrom(account, ALLOWED_TARGET, ALLOW_VALUE_WEI, nonce);
  const check = evaluatePolicy(policy, proposal);
  console.log(JSON.stringify({ ok: check.ok, reason: check.ok ? null : check.reason }));
}

main();
