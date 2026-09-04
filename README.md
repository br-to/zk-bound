# zk-bound

Proof-bound permissions for AI wallets.

`zk-bound` explores a simple safety boundary: an AI agent may propose wallet
actions, but execution is permitted only when the action is accompanied by
proof that it satisfies an owner-defined policy.

The project is in its discovery and architecture phase. The problem statement
is deliberate; the protocol, proving system, chain, and application stack are
not selected yet.

## Start here

- [Project brief](docs/product/project-brief.md) — purpose, hypotheses, scope,
  and success criteria
- [Architecture notes](docs/architecture/README.md) — current boundaries and
  open technical questions
- [Documentation index](docs/README.md) — where durable project knowledge lives
- [Contributing workflow](docs/development/workflow.md) — how humans and agents
  make changes

## Repository status

There is no production implementation yet. Before implementation begins, turn
the relevant open questions into explicit decisions and record them in
[`docs/decisions`](docs/decisions/README.md).

## License

No license has been selected. Until that decision is recorded and a license is
added, all rights are reserved.
