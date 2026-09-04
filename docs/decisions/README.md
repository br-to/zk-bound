# Architecture decision records

An ADR captures a consequential decision, its context, and its consequences.

## Lifecycle

- `proposed` — under review; do not rely on it as a committed constraint.
- `accepted` — the current decision.
- `superseded` — replaced by a later ADR, linked from both records.
- `deprecated` — no longer recommended, with no direct replacement.

Create records from `0000-template.md` using the next four-digit number. Keep
accepted records immutable except for status and cross-links.

| ADR | Status | Decision |
| --- | --- | --- |
| [0001](0001-repository-operating-model.md) | accepted | Repository operating model |
| [0002](0002-adopt-safe-module-execution-boundary.md) | accepted | Safe Module execution boundary |
