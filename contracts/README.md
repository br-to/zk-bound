# Contracts

この directory には、Noir policy proof を EVM で検証するための Solidity 実装を置く。

## 現在の baseline

- `src/verifier/HonkVerifier.sol` は固定した Barretenberg から生成した UltraHonk verifier。手で編集しない。
- `src/PolicyAccount.sol` は `zk-agent-guard` から取り込んだ独自 smart account の reference 実装。
- `test/fixtures/allow.proof.bin` は reference 実装を検証する allow proof fixture。

`PolicyAccount` は production の実行経路ではない。Safe Module への移行方針は [ADR 0002](../docs/decisions/0002-adopt-safe-module-execution-boundary.md)、具体的な工程は [Plan 0001](../docs/plans/0001-safe-module-migration.md) を参照する。

## Baseline の検証

```sh
git submodule update --init --recursive
forge test --root contracts
```

`HonkVerifier.sol` と live proof は `scripts/toolchain.env` の `nargo` と `bb` の組み合わせに固定されている。circuit を変更した場合は、同じ toolchain で verifier と fixture proof を同時に再生成する。

## Safe Module 実装時の条件

- Safe version と ModuleManager API は [ADR 0004](../docs/decisions/0004-pin-safe-v1.4.1.md) で `v1.4.1` に固定済み。依存追加（`forge install safe-global/safe-smart-account@v1.4.1` 等）は実装 PR で行う。
- 初版は circuit が証明する native ETH transfer / empty calldata / `Call` だけに限定する。
- policy configuration と revoke は Safe owner が承認した Safe transaction を通す。
- Safe address、chain ID、target、value、calldata hash、nonce、expiry を proof と execution の両方で bind する。
- integration test は pinned tag の公式 Safe contract（`SafeProxyFactory` + `Safe.setup`）を使う。
