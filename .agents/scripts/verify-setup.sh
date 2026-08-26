#!/bin/sh
set -eu

agents_root=${AGENTS_ROOT:-"$HOME/.agents"}
failures=0

check() {
  if "$@"; then
    return 0
  fi
  echo "failed: $*" >&2
  failures=$((failures + 1))
}

check test -f "$agents_root/AGENTS.md"
check test -d "$agents_root/skills"
check test -d "$agents_root/prompts"
check test -L "$HOME/.claude/skills"
check test "$(readlink "$HOME/.claude/skills")" = "../.agents/skills"
check "$agents_root/scripts/sync-adapters.sh" --check

uv run --script "$agents_root/scripts/generate_adapters.py" \
  "$agents_root/adapters.yaml" --validate-skills || failures=$((failures + 1))

if [ "$failures" -ne 0 ]; then
  echo "$failures verification check(s) failed" >&2
  exit 1
fi

echo "setup verification passed"
