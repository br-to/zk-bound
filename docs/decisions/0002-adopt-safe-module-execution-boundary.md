# ADR 0002: authorization-gated execution を Safe Module に移す

- Status: accepted
- Date: 2026-09-04
- Deciders: maintainers

## Context

取り込んだ `zk-agent-guard` PoC は private spending policy を証明し、最後の `target.call` を行う最小 smart account として `PolicyAccount` を使う。暗号的な主張の検証には十分だが、利用者に資金を独自 account へ移すことを求める。

次版では既存の暗号層を保ったまま、すでに Safe が保有する資産に proof gate を適用する。

## Decision

`ZkPolicySafeModule` を意図した実行境界とする。module は proof と public input を policy commitment、Safe address、chain、target、value、calldata hash、nonce、expiry に bind し、UltraHonk proof を検証してから Safe module API を呼ぶ。

policy の設定、置換、revoke は Safe owner が承認した Safe transaction だけで行う。agent や任意 EOA に直接与えた権限へ依存してはならない。

既存の Noir circuit、Policy SDK canonical encoding、Poseidon2 commitment、UltraHonk verifier、proof fixture、test vector は compatibility baseline とする。旧 `PolicyAccount` standalone 経路は Plan 0001 Step 7 で削除済み。

## Consequences

- 資金は Safe custody に残り、module は制約付き実行経路になる。
- integration を主張する test／demo は、実際の Safe または version-pinned 公式 fixture を使う。
- target Safe version と module API は、module deploy 前に follow-up ADR で固定する。
- legacy Anvil script と README の導線は Safe parity 後に置き換えた（Plan 0001 Step 6–7）。旧 `PolicyAccount` と `Deploy.s.sol`／`Execute.s.sol` は Step 7 で削除済み。

## Alternatives considered

- `PolicyAccount` を user-facing account として維持: custom custody を主経路にするため採用しない。
- agent が通常の Safe owner transaction を送る: execution boundary で proof を強制できないため採用しない。
- circuit／SDK を先に作り直す: 初回 migration は実行層だけを差し替えられるため採用しない。

## References

- [`docs/architecture/README.md`](../architecture/README.md)
- [`docs/plans/0001-safe-module-migration.md`](../plans/0001-safe-module-migration.md)
- [`contracts/src/ZkPolicySafeModule.sol`](../../contracts/src/ZkPolicySafeModule.sol)
