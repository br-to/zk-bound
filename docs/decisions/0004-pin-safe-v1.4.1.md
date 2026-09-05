# ADR 0004: Safe smart account を v1.4.1 に固定する

- Status: accepted
- Date: 2026-09-05
- Deciders: maintainers

## Context

[ADR 0002](0002-adopt-safe-module-execution-boundary.md) は実行境界を `ZkPolicySafeModule` に移すことを決めたが、target Safe release と module API は follow-up ADR に残していた。[Plan 0001](../plans/0001-safe-module-migration.md) Step 2 は、推測で Safe interface を実装する前に公式 source と version を固定することを要求する。

本 ADR はその pin だけを行い、module 実装や forge 依存の追加は後続 PR に委ねる。

## Decision

### Release pin

初版 Safe Module 統合は次の公式 release に固定する。

| 項目 | 値 |
| --- | --- |
| Official repo | [safe-global/safe-smart-account](https://github.com/safe-global/safe-smart-account)（歴史的には `safe-contracts`） |
| Tag | `v1.4.1` |
| Commit | `bf943f80fec5ac647159d26161446ac5d716a294` |
| NPM（当該 tag） | `@safe-global/safe-contracts@1.4.1` |
| Foundry | `forge install safe-global/safe-smart-account@v1.4.1`（または同 tag／commit の git submodule） |

`v1.5.0` 以降で NPM package 名は `@safe-global/safe-smart-account` に改名された。本 pin では **v1.4.1 時点の package 名・version**（`@safe-global/safe-contracts@1.4.1`）を使う。`main` や untagged commit は使わない。

選定理由: 1.4.0／1.4.1 は Ackee による監査を受け広くデプロイされており、必要な ModuleManager API が安定している。

### Module API pin（`ModuleManager.sol` at v1.4.1）

実装とテストは次の公式シグネチャに合わせる（出典: tag `v1.4.1` の `contracts/base/ModuleManager.sol`）。

- `enableModule(address module)` / `disableModule(address prevModule, address module)` — `SelfAuthorized`（`authorized` modifier）。Safe owner が承認した Safe transaction 経由でのみ呼ぶ。
- `execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation) returns (bool success)` — enabled module のみ。`modules[msg.sender] != address(0)`（および sentinel 除外）を require する。
- `execTransactionFromModuleReturnData(...)` も存在するが、初版は `execTransactionFromModule` を使う。
- `isModuleEnabled(address module) view returns (bool)`
- `Enum.Operation { Call, DelegateCall }`（`contracts/common/Enum.sol`）。初版は `Call` のみ。
- Native ETH transfer は empty `data` と `Operation.Call` で表現する。

### Official fixtures / test baseline

- 依存・fixture は pinned tag の `Safe.sol`／`SafeL2.sol`、`SafeProxyFactory.sol`、`CompatibilityFallbackHandler.sol` など公式 contracts を使う。
- テスト Safe のデプロイは、同 tag の `SafeProxyFactory` + `Safe.setup` に従う（Safe 自身の `test/` と同様）。
- 任意の address catalog として `@safe-global/safe-deployments`（1.4.1 対応）を使ってよいが、Anvil unit test には必須ではない。
- `colinnielsen/safe-tools` など非公式 wrapper を pinned official source として扱わない。

### 本 ADR のスコープ外

- `ZkPolicySafeModule.sol` の実装
- 本 PR での forge dep／submodule 追加（pin の文書化のみ。install は実装 PR）
- circuit、SDK、verifier、proof fixture の変更

## Consequences

- module 実装前に Safe version と ModuleManager API が固定される（ADR 0002 の follow-up を閉じる）。
- forge／NPM 依存の追加は後続実装 PR で、本 ADR の tag／commit／package に従う。
- Safe 側の enable／disable／exec API は決まったが、**我々の module 上の** policy configure／replace／revoke の具体的な関数名と、policy 変更時の nonce 扱い（reset vs keep）は Safe が強制しないため、引き続き open とする。
- 非公式 Safe helper や unpinned `main` を integration baseline にしない。

## Alternatives considered

- **Safe `v1.5.x` / `@safe-global/safe-smart-account`**: 新しい package 名だが、初版は監査実績とデプロイ実績のある 1.4.1 を優先する。必要になったら別 ADR で上げる。
- **`main` や untagged commit**: 再現性と監査境界が崩れるため採用しない。
- **非公式 wrapper（例: safe-tools）を公式 source とみなす**: interface の正本が不明確になるため採用しない。公式 repo の tag を正とする。

## References

- [safe-global/safe-smart-account `v1.4.1`](https://github.com/safe-global/safe-smart-account/tree/v1.4.1)（commit `bf943f80fec5ac647159d26161446ac5d716a294`）
- [`ModuleManager.sol` at v1.4.1](https://github.com/safe-global/safe-smart-account/blob/v1.4.1/contracts/base/ModuleManager.sol)
- [`Enum.sol` at v1.4.1](https://github.com/safe-global/safe-smart-account/blob/v1.4.1/contracts/common/Enum.sol)
- [ADR 0002](0002-adopt-safe-module-execution-boundary.md)
- [Plan 0001](../plans/0001-safe-module-migration.md)
- [`docs/architecture/safe-module.md`](../architecture/safe-module.md)
