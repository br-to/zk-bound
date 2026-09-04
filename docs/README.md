# Documentation

Repository documentation is the durable source of project context. Decisions
made in issues, pull requests, chats, or coding sessions must be reflected here
when they affect future work.

## Map

| Area | Purpose |
| --- | --- |
| [`product/`](product/project-brief.md) | Product intent, scope, and success criteria |
| [`architecture/`](architecture/README.md) | System boundaries, constraints, and open questions |
| [`decisions/`](decisions/README.md) | Accepted and superseded architecture decision records |
| [`plans/`](plans/README.md) | Active plans for substantial, multi-step work |
| [`development/`](development/workflow.md) | Development and review workflow |

## Documentation rules

1. Describe the current truth in the relevant topic document.
2. Record a consequential choice and its tradeoffs as an ADR.
3. Create a plan for work that crosses components, introduces a migration, or
   is unlikely to fit in one focused pull request.
4. Update or remove stale documentation in the same change that makes it stale.
5. Link to repository paths instead of copying the same guidance into multiple
   files.

Git history preserves old text. Avoid keeping obsolete guidance in current
documents unless it remains useful and is clearly marked as historical.
