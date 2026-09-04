# ADR 0003: `value` / `maxValue` を circuit で u128 範囲に制約する

- Status: accepted
- Date: 2026-09-04
- Deciders: maintainers

## Context

`circuits/policy/src/main.nr` の上限比較は `(value as u128) <= (max_value as u128)`
だった。Noir の `Field as u128` cast は上位 bit を切り捨てるだけで、range constraint
を追加しない。そのため `value` や `max_value` が `2^128` 以上の Field である場合、
`2^128 + x` は `x` として比較され、意図しない witness が上限比較を通過し得た。

`value` と `max_value` は Solidity 側では `uint256`（wei 建ての ETH 額）として
文書化されている。しかし本プロジェクトが初版で扱う native ETH transfer では、
`2^128` wei はイーサリアム上に存在しうる ETH の総量を天文学的に超える
（`2^128` wei ≒ 3.4 × 10^20 ETH。現実の ETH 総供給量は 1.2 × 10^8 ETH 程度）。
したがって `u128` は native ETH transfer の用途に対して現実的な制約にならない。

## Decision

`main.nr` で `value` と `max_value` それぞれに
`assert_max_bit_size::<128>()` を追加し、両者を明示的に `u128` 範囲
（`< 2^128`）に制約する。この制約が成立して初めて `as u128` cast は無損失になり、
既存の `(value as u128) <= (max_value as u128)` 比較が真の unsigned range check
になる。`2^128` 以上の `value` または `max_value` を含む witness は proof 生成
段階で reject される（fail closed）。

`uint256` 全域（`2^128` 以上）を正しく比較するための canonical limb
decomposition と recomposition constraint は、実際に必要になるまで導入しない。

## Consequences

- `value` と `max_value` は `[0, 2^128)` に制約される。native ETH transfer の
  用途では実質的な制限にならない。
- 旧 circuit で生成した proving key / verification key / `HonkVerifier.sol` /
  proof fixture は、この変更を反映していない。circuit を意図的に変更したため、
  `scripts/toolchain.env` に固定した `nargo` / `bb` で同時に再生成する必要が
  ある。本 PR の実行環境には `nargo` / `bb` が存在せず、再生成は未実施の
  ままである（Blocker。[proof-system.md](../architecture/proof-system.md) 参照）。
- `docs/architecture/policy-spec.md` に、現在の circuit が enforce する
  u128 上限を明記する。
- 将来 `2^128` 以上の value を扱う必要が生じた場合は、limb decomposition を
  追加する新しい ADR と、新しい test vector・verifier 再生成が必要になる。

## Alternatives considered

- **uint256 全域の canonical limb decomposition**（Plan 0001 が当初想定した
  修正）: 正しいが、native ETH transfer の用途では不要な複雑さと
  constraint 数の増加を持ち込む。現実的な必要性が生じるまで見送る。
- **`assert(value as u256 <= max_value as u256)` のような広い型への cast**:
  Noir の `Field` は BN254 scalar field（約 254 bit）であり、`u256` は
  circuit がネイティブに扱える範囲を超えるため、同種の truncation 問題を
  別の型で再導入するだけで解決にならない。

## References

- [`docs/architecture/policy-spec.md`](../architecture/policy-spec.md)
- [`docs/architecture/proof-system.md`](../architecture/proof-system.md)
- [`docs/plans/0001-safe-module-migration.md`](../plans/0001-safe-module-migration.md)
- [`circuits/policy/src/main.nr`](../../circuits/policy/src/main.nr)
