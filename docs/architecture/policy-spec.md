# Policy specification

## Canonical transaction binding

既存 circuit と SDK は、次の 8 public input をこの順序で扱う。順序・個数・意味は Safe Module 移行後も維持する。

```text
TransactionBinding {
  chainId: uint256
  account: address   // MUST equal the Safe that will execute
  target: address
  value: uint256
  calldataHash: bytes32
  nonce: uint256
  expiry: uint64
}
```

| 公開入力 | Safe Module での意味 |
| --- | --- |
| `policyCommitment` | その Safe に登録された active policy commitment |
| `chainId` | 実行する chain の ID |
| `account` | **Safe address**（`account == safe`）。旧 `PolicyAccount` 自身の address と同じスロットを再利用する |
| `target` | `execTransactionFromModule` の `to` |
| `value` | `execTransactionFromModule` の `value`（wei） |
| `calldataHash` | `keccak256(data) % BN254_Fr`。初版の `data` は空 |
| `nonce` | その Safe 向け module nonce |
| `expiry` | 実行期限（比較は execution boundary） |

フィールド名 `account` は circuit／SDK／verifier compatibility のため変更しない。意味上は常に Safe address を指す。

## Safe operation（初版）

Safe `v1.4.1` の `Enum.Operation` のうち、初版が許可する操作は次だけである。

```text
SafeOperation {
  to: target                    // public input `target`
  value: value                  // public input `value`
  data: 0x                      // empty calldata only
  operation: Call               // Enum.Operation.Call == 0
}
```

制約:

- `operation` は **public input に含めない**。circuit は Call 固定の意味論だけを証明する。
- execution boundary（将来の `ZkPolicySafeModule`）は `Enum.Operation.Call` 以外を **fail closed** で拒否する。
- `data` は空バイト列のみ。非空 calldata、`DelegateCall`、multisend、batch は初版スコープ外。
- binding の `account` は、module が `execTransactionFromModule` を呼ぶ対象 Safe と一致しなければならない。別 Safe 向け proof の転用を防ぐ。

operation type、ERC-20 semantic、multisend を導入する場合は binding と circuit を拡張し、ADR・vector・verifier を同じ変更で更新する。

`calldataHash` は calldata 全体の `keccak256(data) % BN254_Fr`。SDK、Noir、Solidity で field order、endianness、address の 160-bit 表現を一致させ、test vector を正本にする。

## Private witness

```text
PrivatePolicy {
  maxValue: uint256
  allowedTarget: address
  policySalt: field
}
```

初版の allowlist は 1 address。複数宛先は policy に Merkle root を含め、target の membership path を private witness にする拡張として扱う。

## Public inputs

```text
policyCommitment: field
chainId: uint256
account: address   // Safe address; account == safe
target: address
value: uint256
calldataHash: bytes32
nonce: uint256
expiry: uint64
```

`ZkPolicySafeModule` は受け取った Safe operation（`to`／`value`／`data`／`Call`）と public input を直接照合する。これにより proof を別 Safe、別 chain、別 target、別 value、別 calldata、別 nonce、別 expiry、別 operation type に転用できない。

## Circuit constraints

```text
policyCommitment == Poseidon(domain, maxValue, allowedTarget, policySalt)
value < 2^128
maxValue < 2^128
value <= maxValue
target == allowedTarget
```

`value` と `maxValue` は circuit で明示的に `u128` 範囲（`< 2^128`）に制約される
（[ADR 0003](../decisions/0003-constrain-policy-values-to-u128-range.md)）。native
ETH transfer が扱う wei 額に対して `2^128` は現実的な制限にならない。この
range constraint がないと `Field as u128` cast が上位 bit を切り捨て、
`2^128` 以上の値を上限比較で truncate してしまう。

`expiry` の比較は execution boundary の `block.timestamp <= expiry` に置く。circuit は expiry を binding に含め、値の差し替えを防ぐ。replay は Safe ごとの on-chain nonce と binding により防ぐ。

## Compatibility rule

既存の domain tag `zk-agent-guard.policy.v1`、Poseidon2 input ordering、8 public input の順序、test vector の commitment／public-input hex は commitment compatibility のため変更しない。package や repository の名称変更、および `account` の意味を Safe address に固定することは、proof statement を変える理由にならない。
