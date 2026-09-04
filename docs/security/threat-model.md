# Threat model

## 保護対象

- Safe が保有する資金
- Safe owner の権限
- 秘密 policy（上限、allowlist、salt）
- proof を作る user-controlled prover environment

## Trust assumptions

- Safe、module、verifier、circuit の deploy 済みコードが正しい。
- Safe owner と policy prover environment は侵害されていない。
- chain の block timestamp は通常の Ethereum の範囲で信頼する。

## 攻撃者の能力

- agent に prompt injection を与え、任意の Safe operation を提案させる。
- agent runtime を侵害し、proposal の改ざん・再送を行う。
- public proof、transaction、event を収集して replay を試みる。
- on-chain data から policy の内容を推測しようとする。

## 期待する防御

| 攻撃 | 必要な防御 | 受入条件 |
| --- | --- | --- |
| attacker 宛の全額送金 proposal | value / target constraint | proof を生成できない、または module が Safe を呼ばない |
| 正常 proof の別操作への転用 | complete transaction binding | target、value、calldata、nonce の変更で revert |
| 正常 proof の replay | Safe + chain ID + nonce binding | 同じ proof の再実行が revert |
| expiry 後の送信 | on-chain timestamp check | execution が revert |
| policy の復元 | hiding commitment | policy plaintext が event、calldata、public input にない |
| policy 設定の乗っ取り | Safe-owner authorization | 任意 EOA／agent が設定変更できない |

## PoC の対象外

- prover device の malware と秘密 policy の窃取
- Safe owner key の漏えい
- Safe、verifier、circuit の実装バグ
- MEV、censorship、chain reorg
- allowlisted contract 自体が悪意を持つ場合の事業上のリスク
