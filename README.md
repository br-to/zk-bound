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
running the Anvil demo on the Safe module path.
PolicyAccount scripts remain as reference until Step 7.

## Tools & libraries

Pinned versions come from [`scripts/toolchain.env`](scripts/toolchain.env),
root / workspace `package.json` files, [`contracts/foundry.toml`](contracts/foundry.toml),
[`.gitmodules`](.gitmodules), and
[ADR 0004](docs/decisions/0004-pin-safe-v1.4.1.md).

### Proof / circuit

| Item | Value | Source / notes |
| --- | --- | --- |
| Noir (`nargo`) | `1.0.0-beta.22` | `NOIR_VERSION` in `scripts/toolchain.env` |
| Barretenberg (`bb`) | `5.0.0-nightly.20260522` | `BB_VERSION`; UltraHonk; keep in lockstep with `nargo` |
| Circuit | `circuits/policy` | Poseidon2 policy commitment |
| Verifier | `contracts/src/verifier/HonkVerifier.sol` | generated UltraHonk verifier (do not hand-edit) |

### Contracts / execution boundary

| Item | Value | Source / notes |
| --- | --- | --- |
| Foundry (`forge`) | — | Solidity build / test / script under `contracts/` |
| solc | `0.8.30` | `solc_version` in `contracts/foundry.toml` |
| forge-std | git submodule | `contracts/lib/forge-std` (see `.gitmodules`) |
| Safe smart account | `v1.4.1` | [ADR 0004](docs/decisions/0004-pin-safe-v1.4.1.md); submodule `contracts/lib/safe-smart-account` |
| `ZkPolicySafeModule` | `contracts/src/ZkPolicySafeModule.sol` | Safe Module migration target |
| `PolicyAccount` | `contracts/src/PolicyAccount.sol` | imported baseline; migration reference only (not the production path) |

### TypeScript

| Item | Value | Source / notes |
| --- | --- | --- |
| Node.js | `>=22` | root `engines.node` |
| pnpm | `10.31.0` | root `packageManager` |
| TypeScript | `^5.9.3` | root `devDependencies` |
| ESLint | `^9.39.1` | root `devDependencies` |
| Prettier | `^3.7.4` | root `devDependencies` |
| `@zk-bound/policy-sdk` | workspace `0.1.0` | deps: `@noble/hashes` `^2.4.0`, `@zkpassport/poseidon2` `^0.6.2` |
| `@zk-bound/demo` | workspace `0.1.0` | local demo package (`apps/demo`) |

### Local execution

- Foundry **Anvil** via `pnpm demo:anvil` (`scripts/anvil-e2e.sh`) for baseline live-proof E2E.
  See [`contracts/README.md`](contracts/README.md) and the migration plan for which
  execution path the script currently exercises.

## License

No license has been selected. Until that decision is recorded and a license is
added, all rights are reserved.
