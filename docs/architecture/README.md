# Architecture notes

This document describes the expected Safe Module boundaries. Safe release and
ModuleManager API are pinned in [ADR 0004](../decisions/0004-pin-safe-v1.4.1.md).

詳細:

- [policy specification](policy-spec.md) — proof が bind する transaction と policy
- [proof system](proof-system.md) — Noir / UltraHonk / generated verifier の固定事項
- [Safe Module design](safe-module.md) — migration 後の execution boundary

## Conceptual flow

1. Safe owners define a permission policy outside the agent's control.
2. The system commits to that policy and registers the commitment for that Safe
   through an owner-authorized Safe transaction.
3. The agent proposes a Safe action.
4. A prover produces evidence that the action satisfies the committed policy.
5. `ZkPolicySafeModule` checks the evidence and binds it to the exact execution
   context.
6. The enabled module asks the Safe to execute only after successful
   verification.

## Candidate components

- **Policy representation** — the constraints the owner delegates.
- **Policy commitment** — a stable reference to the policy without necessarily
  exposing all policy data.
- **Action representation** — the normalized operation to authorize.
- **Prover** — produces the policy-compliance proof.
- **Verifier** — validates the proof and its public inputs.
- **Safe Module** — enforces verification before invoking the Safe module API.
- **Safe** — holds funds and performs the final operation only for an enabled
  module.
- **Owner controls** — Safe-owner transactions that create, replace, revoke, or
  expire permissions.

## Security invariants to preserve

- The agent cannot change the policy commitment accepted for a Safe.
- A proof for one action, Safe, chain, policy, or validity window cannot be
  reused for another.
- The module invokes the Safe only after proof verification and context
  validation succeed; every failure path is closed.
- Policy updates and revocations require Safe-owner authority, not merely an
  EOA selected by an agent or module caller.
- The module is enabled on the Safe before it can cause execution, and the
  module checks that it is still enabled where the Safe interface permits.
- Private policy data is not leaked through public inputs, logs, errors, or test
  fixtures beyond the privacy guarantee the project explicitly chooses.
- No off-chain success response can bypass the on-chain execution-boundary
  check.

## Open architecture decisions

[policy-spec](policy-spec.md) と test vector（version 2）で次を正本化した（Plan 0001 Step 3）。

- native ETH transfer のみを扱う。
- calldata は空（empty calldata）に限定する。
- Safe operation は `Call` のみを使う（public input には含めず、execution boundary で固定）。
- public input の `account` は Safe address（`account == safe`）。8 入力の順序は変更しない。
- private witness は `maxValue` + 単一の `allowedTarget` + `policySalt` に限定する。
- policy commitment は Poseidon2 で計算する。
- proving system は UltraHonk（既存の proof binding、8 public input の順序）を使う。
- 最初の demo 環境は Anvil とする。

[ADR 0004](../decisions/0004-pin-safe-v1.4.1.md) で決定済み:

- target Safe contract version: `v1.4.1`（commit `bf943f80fec5ac647159d26161446ac5d716a294`）。
- `ZkPolicySafeModule` が呼ぶ ModuleManager API（`enableModule`／`disableModule`／`execTransactionFromModule`／`isModuleEnabled`、初版は `Call` のみ）。

follow-up ADR で固定するまでの未決定事項は次の2点である。

- Safe owner が行う policy の設定・更新・revoke lifecycle の具体的な方式（我々の module 上の関数名など）。
- policy 変更時に nonce をどう扱うか（据え置く、リセットする等）。

Each selection must state its threat-model assumptions and be captured in
[`docs/decisions`](../decisions/README.md).

## Imported baseline and target boundary

The imported `PolicyAccount` is a reference implementation for proof-to-call
binding. It is not the target custody architecture. The Safe Module target is:

```text
agent proposal
  -> user-controlled prover with private policy
  -> UltraHonk proof bound to Safe + operation
  -> ZkPolicySafeModule.executeWithPolicy(...)
  -> public-input and nonce checks
  -> generated HonkVerifier.verify(...)
  -> Safe.execTransactionFromModule(...)
  -> Safe action
```

The migration keeps the circuit statement and encoding stable wherever the Safe
action can be represented by the existing binding. Any extension beyond native
ETH transfer—such as operation type, ERC-20 semantics, or multi-send—requires a
new ADR, new vectors, and a coordinated circuit/verifier update.
