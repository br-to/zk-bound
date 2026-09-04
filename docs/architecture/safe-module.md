# Safe Module design

この文書は ADR 0002 を実装へ落とすための境界を定義する。Safe release と正確な module interface は follow-up ADR で固定するまで仮定しない。

## 役割

`ZkPolicySafeModule` は custody wallet ではない。Safe が資金を保有し、module は proof が成功した operation だけを Safe module API に渡す。

```text
Safe owner transaction -> configure / replace / revoke policy
agent or relayer      -> submit proof + bound operation
module                -> validate binding + verify proof
Safe                  -> execute the permitted operation
```

## 必要な状態

Safe ごとに以下を管理する。

- active policy commitment
- next nonce
- configuration が active かどうか

policy の設定と revoke は `msg.sender == safe` を要求し、Safe owner が承認した Safe transaction によってのみ到達可能にする。module caller は agent、relayer、任意 EOA でよいが、policy を変更する権限は持たない。

## execute の順序

1. Safe と policy configuration が有効であることを確認する。
2. public input 数と commitment、chain ID、Safe、target、value、calldata hash、nonce、expiry を operation と照合する。
3. `block.timestamp` と expiry を照合する。
4. UltraHonk verifier を呼ぶ。
5. nonce を進め、同一 transaction 内で Safe module API を呼ぶ。
6. Safe execution が失敗した場合は transaction 全体を revert し、nonce も消費しない。

## 初版の制限

- native ETH transfer のみ
- empty calldata のみ
- `Call` のみ
- 1 operation ごとに 1 proof

module が任意 call、delegatecall、multisend を受けるように見えても、circuit がその意味を証明していない限り受け付けない。
