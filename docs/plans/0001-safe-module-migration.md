# Plan 0001: proof 付き実行を Safe Module へ移行する

- 状態: active
- 担当: maintainers
- 最終更新: 2026-09-05
- 関連 ADR: [ADR 0002](../decisions/0002-adopt-safe-module-execution-boundary.md)、[ADR 0003](../decisions/0003-constrain-policy-values-to-u128-range.md)、[ADR 0004](../decisions/0004-pin-safe-v1.4.1.md)

## 到達点

ETH を保有する Safe が、有効化済み `ZkPolicySafeModule` を経由してポリシー適合の native ETH transfer を実行できる。エージェントは操作を提出できても、ポリシー違反・改ざん・replay・期限切れ・別 Safe 向けの操作を実行させられない。

## スコープ

含めるもの:

- empty calldata を伴う native ETH transfer と Safe の `Call` operation;
- バージョン固定した公式 Safe コントラクト／テスト fixture;
- Safe ごとの policy commitment と nonce;
- Safe owner が承認した policy の設定・置換・revoke;
- proof/public input binding と UltraHonk verification;
- 正常系・拒否系の統合テスト; および
- prompt injection の物語を保つ Safe ベース Anvil demo。

後回しにするもの:

- ERC-20 semantic decoding、任意 calldata、delegatecall、multisend、batch;
- 累積支出、Merkle allowlist、UI、production key management、mainnet; および
- 監査済みという主張。

## 手順

1. **CLOSED: range constraint を修正し、verifier を再生成する。** [ADR 0003](../decisions/0003-constrain-policy-values-to-u128-range.md) により `value`／`max_value` に `assert_max_bit_size::<128>()` を追加（[PR #2](https://github.com/br-to/zk-bound/pull/2)）。固定 toolchain で `HonkVerifier.sol` と `allow.proof.bin` を再生成し on-chain verify が通ることを確認（[PR #3](https://github.com/br-to/zk-bound/pull/3); `nargo` 6/6・`forge` 7/7）。commitment 入力と public-input 順序は変わっていないため、Policy SDK encoding と test vector はそのまま有効。旧「SDK／vectors／fixture 未同期」記述は誤りで、Step 1 は main 上で閉じている。
2. **DONE（ADR）: Safe release、依存元、module API、公式テスト fixture を ADR で固定する。** [ADR 0004](../decisions/0004-pin-safe-v1.4.1.md) で `v1.4.1`（commit `bf943f80…`）、`@safe-global/safe-contracts@1.4.1`、ModuleManager API、公式 fixture 方針を accepted。forge dep／submodule の install と `ZkPolicySafeModule` 実装は後続工程。
3. **DONE: `safe` と対応 operation を policy spec と test vector に定義する。** ([PR #6](https://github.com/br-to/zk-bound/pull/6)) `account` は Safe address（`account == safe`）を意味し、Safe operation は empty calldata + `Enum.Operation.Call` に固定。既存の 8 public input 順序と hex は維持（vector version 2 はメタデータ追加のみ）。module 実装は含まない。
4. **DONE: configuration、revoke、context check、verifier 呼び出し、Safe ごとの nonce、event、fail-closed な module 実行を実装する。** ([PR #7](https://github.com/br-to/zk-bound/pull/7))
5. PARTIAL thin extras — enabled module 成功、無効 module 拒否、設定変更、target/value/calldata 改ざん、別 Safe／chain、replay、expiry、不正 input、不正 proof、Safe 実行失敗をテストする。
6. **DONE: deploy/execute script と Anvil demo を Safe 経路へ置き換える。** (PR #10)
7. Safe 経路がテスト・demo ともに同等になってから `PolicyAccount` を別 PR で削除する。

## 受入条件

- 実際の Safe が enabled module を通じて許可済み native ETH transfer を実行する。
- 有効な proof を replay、期限切れ、別 Safe、変更済み target/value/calldata/chain に転用できない。
- policy の設定・置換・revoke は Safe owner が承認した transaction だけで可能である。
- allow/reject demo が固定ツールチェーンの clean checkout から動く。
- SDK、Solidity、circuit、repository check が通る。

## リスクとロールバック

- 推測で Safe interface を実装せず、公式 source と version を固定してから実装する。
- nonce は Safe 実行と同一 transaction で消費し、Safe call の失敗をテストする。
- configuration caller は Safe 自身に限定し、owner 承認済み Safe transaction を通す。
- 初版 module は circuit が証明する操作意味論に限定する。
- Safe parity が取れるまでは `PolicyAccount` を reference／rollback 経路として保持する。

## 検証

```sh
./scripts/check-repo.sh
pnpm check
pnpm test
cd circuits/policy && nargo check
pnpm demo:anvil
```
