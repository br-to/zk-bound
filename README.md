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

## License

No license has been selected. Until that decision is recorded and a license is
added, all rights are reserved.
