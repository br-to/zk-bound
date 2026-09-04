# Proof system

## 決定済みの基盤

| 項目 | 選択 |
| --- | --- |
| circuit language | Noir |
| proving system | UltraHonk (Barretenberg `bb`) |
| verifier | `bb write_solidity_verifier` が生成する Solidity contract |
| policy commitment | Poseidon2 |
| verification | Safe Module が generated verifier を呼ぶ |

この選択は、circuit を更新する PoC 段階で circuit-specific ceremony を避け、EVM で verifier を実行できることを優先する。Groth16、STARK、別 proving system への変更は Safe migration と別の大きな決定であり、ADR を必要とする。

## 生成物の扱い

`contracts/src/verifier/HonkVerifier.sol` は generated artifact である。手編集しない。circuit を意図的に変更した場合は、`scripts/toolchain.env` に固定した `nargo` と `bb` で以下を同時に再生成する。

- verification key
- `HonkVerifier.sol`
- EVM proof fixture
- public input fixture と SDK test vector（意味が変わる場合）

別バージョンの `bb` で作った live proof と committed verifier は整合しないことがある。fixture test の成功だけで fresh proof の互換性を主張してはならない。

## ZK が隠すもの／隠さないもの

| Private witness | Public / 観測可能 |
| --- | --- |
| `maxValue` | Safe address、target、value |
| `allowedTarget` | `policyCommitment`、chain ID |
| `policySalt` | calldata hash、nonce、expiry |

`value` は public であり、上限値そのものは隠すが、観測された value から下限を推測できる。privacy claim はこの範囲を超えてはならない。
