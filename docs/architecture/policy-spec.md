# Policy specification

## Canonical transaction binding

既存 circuit と SDK は、次の 8 public input をこの順序で扱う。

```text
TransactionBinding {
  chainId: uint256
  account: address
  target: address
  value: uint256
  calldataHash: bytes32
  nonce: uint256
  expiry: uint64
}
```

Safe Module 版では `account` は Safe address を表す。初版は native ETH transfer に限定するため `data` は空、Safe operation は `Call` で固定する。operation type、ERC-20 semantic、multisend を導入する場合は binding と circuit を拡張し、ADR・vector・verifier を同じ変更で更新する。

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
account: address   // Safe address
target: address
value: uint256
calldataHash: bytes32
nonce: uint256
expiry: uint64
```

`ZkPolicySafeModule` は受け取った Safe operation と public input を直接照合する。これにより proof を別 Safe、別 chain、別 target、別 value、別 calldata、別 nonce、別 expiry に転用できない。

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

既存の domain tag `zk-agent-guard.policy.v1`、Poseidon2 input ordering、test vector は commitment compatibility のため変更しない。package や repository の名称変更は、proof statement を変える理由にならない。
