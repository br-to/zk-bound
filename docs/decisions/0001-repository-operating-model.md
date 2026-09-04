# ADR 0001: 持続するプロジェクト知識と agent 指示をリポジトリに置く

- Status: accepted
- Date: 2026-09-04
- Deciders: maintainers

## Context

`zk-bound` は人間と coding agent の両方で開発する。security assumption、toolchain coupling、protocol decision が prompt、issue comment、特定 agent の記憶だけにあると失われやすい。

## Decision

リポジトリを持続するプロジェクト文脈の正本とする。`AGENTS.md` を repository-wide の正本、`CLAUDE.md` を Claude Code の入口とし、product、architecture、decision、plan、workflow を `docs/` に置く。重要決定は ADR、複数工程の作業は計画書に残す。

## Consequences

- AI tool に依存しない、レビュー可能な正本ができる。
- 文書更新は実装の後回しではなく、同じ変更の一部になる。
- agent は architecture 変更前に repository context を読む必要がある。

## Alternatives considered

- tool 固有 prompt のみ: 他の contributor から見えず、内容が分岐するため採用しない。
- issue／PR のみ: 結論を見つけにくく、現在の状態を示せないため採用しない。

## References

- [`AGENTS.md`](../../AGENTS.md)
- [`docs/development/workflow.md`](../development/workflow.md)
