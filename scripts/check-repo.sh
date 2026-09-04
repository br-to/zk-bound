#!/usr/bin/env bash
# 依存 package を要求しない repository-level の安全チェック。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

required=(
  AGENTS.md
  CLAUDE.md
  CONTRIBUTING.md
  SECURITY.md
  docs/README.md
  docs/architecture/README.md
  docs/decisions/README.md
  docs/decisions/0000-template.md
  docs/development/workflow.md
  docs/plans/README.md
  docs/plans/0000-template.md
)

for path in "${required[@]}"; do
  if [ ! -f "$path" ]; then
    echo "missing required repository file: $path" >&2
    exit 1
  fi
done

if ! grep -Fq 'AGENTS.md' CLAUDE.md; then
  echo 'CLAUDE.md must point to AGENTS.md' >&2
  exit 1
fi

# HonkVerifier.sol は bb が生成する成果物で、既存生成物の whitespace は検査対象外。
git diff --check -- . ':(exclude)contracts/src/verifier/HonkVerifier.sol'
git diff --cached --check -- . ':(exclude)contracts/src/verifier/HonkVerifier.sol'

while IFS= read -r script; do
  bash -n "$script"
done < <(find scripts -type f -name '*.sh' -print)

if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  echo '.env must not be tracked; use .env.example instead' >&2
  exit 1
fi

echo 'repository checks passed'
