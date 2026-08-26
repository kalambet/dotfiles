#!/bin/sh
set -eu

source_root=${1:-"$HOME/.agents"}
test_root=$(mktemp -d "${TMPDIR:-/tmp}/agent-adapters.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

make_fixture() {
  name=$1
  root="$test_root/$name"
  mkdir -p "$root/agents"
  cp "$source_root/adapters.yaml" "$root/agents/"
  cp -R "$source_root/prompts" "$source_root/commands" "$root/agents/"
  printf '%s\n' '# Test instructions' > "$root/agents/AGENTS.md"
}

run_generator() {
  name=$1
  mode=$2
  root="$test_root/$name"
  AGENTS_ROOT="$root/agents" ADAPTER_HOME="$root/home" \
    uv run --script "$source_root/scripts/generate_adapters.py" \
    "$root/agents/adapters.yaml" "$mode"
}

make_fixture first
make_fixture second
run_generator first --apply >/dev/null
run_generator first --check >/dev/null
run_generator second --apply >/dev/null

diff -r "$test_root/first/home" "$test_root/second/home" >/dev/null
test "$(readlink "$test_root/first/home/.claude/CLAUDE.md")" = "../../agents/AGENTS.md"

oracle="$test_root/first/home/.claude/agents/oracle.md"
grep '^tools: Read, Grep, Glob, WebSearch, WebFetch, Skill$' "$oracle" >/dev/null
grep -A3 '^permissions:$' "$test_root/first/home/.config/opencode/agents/oracle.md" | \
  grep '^  shell: deny$' >/dev/null
grep -A6 '^tools:$' "$test_root/first/home/.junie/agents/python-reviewer.md" | \
  grep '^\- shell$' >/dev/null

before=$(cksum "$test_root/first/home/.claude/agents/oracle.md")
rm "$test_root/first/home/.claude/agents/oracle.md"
printf '%s\n' unmanaged > "$test_root/first/home/.codex/AGENTS.md.tmp"
mv "$test_root/first/home/.codex/AGENTS.md.tmp" "$test_root/first/home/.codex/AGENTS.md"
if run_generator first --apply >/dev/null 2>&1; then
  echo 'collision preflight unexpectedly passed' >&2
  exit 1
fi
test ! -e "$test_root/first/home/.claude/agents/oracle.md"
after=$(cksum "$test_root/first/home/.claude/agents/librarian.md")
test -n "$before"
test -n "$after"

echo 'adapter behavioral tests passed'
