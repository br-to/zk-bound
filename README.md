# zk-bound

Proof-bound permissions for AI wallets.

`zk-bound` is the Safe Module-focused successor to
[`zk-agent-guard`](https://github.com/br-to/zk-agent-guard). An AI agent may
propose a wallet action, but a Safe executes it only when a zero-knowledge proof
binds that exact action to an owner-defined policy.

The cryptographic policy layer is deliberately retained: Noir circuit, Policy
SDK encoding, Poseidon2 commitment, UltraHonk verifier, proof binding, nonce,
replay, expiry, test vectors, and the prompt-injection demo. The execution
boundary is being migrated from a standalone `PolicyAccount` to a
`ZkPolicySafeModule`.

## Start here

- [Project brief](docs/product/project-brief.md) — purpose, hypotheses, scope,
  and success criteria
- [Safe Module architecture](docs/architecture/README.md) — current boundaries,
  invariants, and open technical questions
- [Safe Module migration plan](docs/plans/0001-safe-module-migration.md) —
  staged implementation path from the imported baseline
- [Documentation index](docs/README.md) — where durable project knowledge lives
- [Contributing workflow](docs/development/workflow.md) — how humans and agents
  make changes

## Repository status

The `zk-agent-guard` baseline is imported at commit `e80f873`. It remains an
executable reference while Safe integration is built and verified. `PolicyAccount`
must not become the production execution path; see
[ADR 0002](docs/decisions/0002-adopt-safe-module-execution-boundary.md).

## Quick start (baseline)

```sh
git submodule update --init --recursive
pnpm install
pnpm check
pnpm test
```

The exact Noir and Barretenberg versions for circuit and live-proof work are
fixed in [`scripts/toolchain.env`](scripts/toolchain.env). See
[`contracts/README.md`](contracts/README.md) and the migration plan before
running the Anvil demo: its scripts still exercise the legacy account until the
Safe path replaces them.

## 使用ツール / ライブラリ

Versions below are taken only from repo pins (`scripts/toolchain.env`,
`package.json`, `contracts/foundry.toml`, `.gitmodules`, and
[ADR 0004](docs/decisions/0004-pin-safe-v1.4.1.md)). Unpinned tools are named
without a guessed version.

### Proof / circuit

| Tool | Version | Source |
| --- | --- | --- |
| Noir (`nargo`) | `1.0.0-beta.22` | [`scripts/toolchain.env`](scripts/toolchain.env) (`NOIR_VERSION`) |
| Barretenberg (`bb`) | `5.0.0-nightly.20260522` | [`scripts/toolchain.env`](scripts/toolchain.env) (`BB_VERSION`) |

Noir and Barretenberg must stay in lockstep; see the comments in
`scripts/toolchain.env`.

### Contracts

| Tool / library | Version | Source |
| --- | --- | --- |
| Solidity (`solc`) | `0.8.30` | [`contracts/foundry.toml`](contracts/foundry.toml) (`solc_version`) |
| [forge-std](https://github.com/foundry-rs/forge-std) | (submodule; no tag pin in the sources above) | [`.gitmodules`](.gitmodules) → `contracts/lib/forge-std` |
| [safe-smart-account](https://github.com/safe-global/safe-smart-account) | `v1.4.1` (commit `bf943f80fec5ac647159d26161446ac5d716a294`; NPM `@safe-global/safe-contracts@1.4.1`) | [ADR 0004](docs/decisions/0004-pin-safe-v1.4.1.md), [`.gitmodules`](.gitmodules) → `contracts/lib/safe-smart-account` |

### TypeScript

| Tool / library | Version | Source |
| --- | --- | --- |
| Node.js | `>=22` | [`package.json`](package.json) (`engines.node`) |
| pnpm | `10.31.0` | [`package.json`](package.json) (`packageManager`) |
| TypeScript | `^5.9.3` | [`package.json`](package.json) (`devDependencies`) |
| ESLint | `^9.39.1` | [`package.json`](package.json) (`devDependencies`) |
| Prettier | `^3.7.4` | [`package.json`](package.json) (`devDependencies`) |

Workspace packages (`@zk-bound/policy-sdk`, `@zk-bound/demo`) are defined under `packages/` and `apps/`; their runtime deps are not duplicated here because this section is limited to the root `package.json` pin list above.

### Anvil / Foundry tools

| Tool | Version | Source |
| --- | --- | --- |
| Foundry (`forge` / `cast` / `anvil`) | (used by scripts; no version pin in the sources above) | [`package.json`](package.json) scripts `test:contracts`, `demo:anvil` |

## License

No license has been selected. Until that decision is recorded and a license is
added, all rights are reserved.
