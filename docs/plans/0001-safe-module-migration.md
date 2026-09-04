# Plan 0001: proof 付き実行を Safe Module へ移行する

- 状態: active
- 担当: maintainers
- 最終更新: 2026-09-04
- 関連 ADR: [ADR 0002](../decisions/0002-adopt-safe-module-execution-boundary.md)

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

1. **Blocker: range constraint を修正し、verifier を再生成する。** 現行 circuit の `Field as u128` 比較は上位 bit を切り詰めるため、`2^128 + x` を `x` として扱えた（[Noir の Field cast に関する公式説明](https://noir-lang.org/docs/guides/thinking_in_circuits)）。[ADR 0003](../decisions/0003-constrain-policy-values-to-u128-range.md) により、`maxValue` と `value` に `assert_max_bit_size::<128>()` を追加して `u128` 範囲を明示的に制約する方針を採用した（native ETH transfer が扱う wei 額に対して `2^128` は制限にならないため、uint256 全域の limb decomposition は現時点で見送る）。circuit source と `2^128` 境界・`u128::MAX` 境界の否定・肯定テストは追加済み。**残作業**: Poseidon2 commitment、Policy SDK encoding、test vector、proof fixture、generated verifier は旧 circuit のまま同期していない。固定 toolchain (`nargo`/`bb`) でこれらを再生成し、固定 toolchain による `bb` の on-chain verification が通るまで後続工程を開始しない。
2. Safe release、依存元、module API、公式テスト fixture を ADR で固定する。
3. `safe` と対応 operation を policy spec と test vector に定義する。意味が同じなら既存の 8 public input の順序を保つ。
4. configuration、revoke、context check、verifier 呼び出し、Safe ごとの nonce、event、fail-closed な module 実行を実装する。
5. enabled module 成功、無効 module 拒否、設定変更、target/value/calldata 改ざん、別 Safe／chain、replay、expiry、不正 input、不正 proof、Safe 実行失敗をテストする。
6. deploy／execute script と Anvil demo を Safe 経路へ置き換える。
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
