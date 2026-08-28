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
  cp -R "$source_root/prompts" "$source_root/commands" "$source_root/skills" "$root/agents/"
  printf '%s\n' '# Test instructions' > "$root/agents/AGENTS.md"
  printf '%s\n' '---' 'description: "Special: # safe"' '---' '' 'Special command.' \
    > "$root/agents/commands/special.md"
}

run_generator() {
  name=$1
  mode=$2
  root="$test_root/$name"
  AGENTS_ROOT="$root/agents" ADAPTER_HOME="$root/home" \
    uv run --script "$source_root/scripts/generate_adapters.py" \
    "$root/agents/adapters.yaml" "$mode"
}

run_config() {
  name=$1
  config=$2
  mode=$3
  root="$test_root/$name"
  AGENTS_ROOT="$root/agents" ADAPTER_HOME="$root/home" \
    uv run --script "$source_root/scripts/generate_adapters.py" "$config" "$mode"
}

run_validator() {
  name=$1
  root="$test_root/$name"
  AGENTS_ROOT="$root/agents" ADAPTER_HOME="$root/home" \
    uv run --script "$source_root/scripts/generate_adapters.py" \
    "$root/agents/adapters.yaml" --validate-skills
}

make_fixture first
make_fixture second
run_generator first --apply >/dev/null
run_generator first --check >/dev/null
run_validator first >/dev/null
run_generator second --apply >/dev/null

diff -r "$test_root/first/home" "$test_root/second/home" >/dev/null
cmp "$test_root/first/agents/generated-adapters.yaml" \
  "$test_root/second/agents/generated-adapters.yaml" >/dev/null
test "$(readlink "$test_root/first/home/.claude/CLAUDE.md")" = "../../agents/AGENTS.md"
test "$(readlink "$test_root/first/home/.claude/skills")" = "../../agents/skills"
test ! -e "$test_root/first/home/.claude/commands/research.md"
grep "^description: 'Special: # safe'$" \
  "$test_root/first/home/.config/opencode/commands/special.md" >/dev/null
if rg -F '<!-- Generated from ~/.agents; edit the canonical source instead. -->' \
  "$test_root/first/home" >/dev/null; then
  echo 'legacy marker remains in generated output' >&2
  exit 1
fi
grep '^Use the `research` skill' "$test_root/first/home/.codex/prompts/research.md" >/dev/null

mkdir -p "$test_root/first/home/.claude/commands"
printf '%s\n' collision > "$test_root/first/home/.claude/commands/oracle.md"
if run_generator first --check >/dev/null 2>&1; then
  echo 'ordinary adapter check missed a skill/command collision' >&2
  exit 1
fi
if run_validator first >/dev/null 2>&1; then
  echo 'skill/command collision check unexpectedly passed' >&2
  exit 1
fi
rm "$test_root/first/home/.claude/commands/oracle.md"
run_generator first --check >/dev/null

oracle="$test_root/first/home/.claude/agents/oracle.md"
grep '^tools: Read, Grep, Glob, WebSearch, WebFetch, Skill$' "$oracle" >/dev/null
grep -A3 '^permissions:$' "$test_root/first/home/.config/opencode/agents/oracle.md" | \
  grep '^  shell: deny$' >/dev/null
grep -A6 '^tools:$' "$test_root/first/home/.junie/agents/python-reviewer.md" | \
  grep '^\- shell$' >/dev/null

make_fixture unmanaged
mkdir -p "$test_root/unmanaged/home/.claude/agents"
printf '%s\n' unmanaged > "$test_root/unmanaged/home/.claude/agents/oracle.md"
if run_generator unmanaged --apply >/dev/null 2>&1; then
  echo 'unmanaged marker-free file was adopted' >&2
  exit 1
fi
test "$(cat "$test_root/unmanaged/home/.claude/agents/oracle.md")" = unmanaged
test ! -e "$test_root/unmanaged/agents/generated-adapters.yaml"

manifest="$test_root/first/agents/generated-adapters.yaml"
manifest_before=$(cksum "$manifest")
librarian="$test_root/first/home/.claude/agents/librarian.md"
librarian_before=$(cksum "$librarian")
printf '%s\n' edited >> "$oracle"
if run_generator first --apply >/dev/null 2>&1; then
  echo 'edited owned file was overwritten' >&2
  exit 1
fi
test "$manifest_before" = "$(cksum "$manifest")"
test "$librarian_before" = "$(cksum "$librarian")"
cp "$test_root/second/home/.claude/agents/oracle.md" "$oracle"

cp "$manifest" "$manifest.valid"
sed 's/version: 1/version: 2/' "$manifest.valid" > "$manifest"
if run_generator first --check >/dev/null 2>&1; then
  echo 'malformed manifest was accepted' >&2
  exit 1
fi
mv "$manifest.valid" "$manifest"

outside_config="$test_root/first/agents/adapters-outside.yaml"
sed "s#  claude: ~/.claude/agents#  claude: $test_root/outside#" \
  "$test_root/first/agents/adapters.yaml" > "$outside_config"
if run_config first "$outside_config" --check >/dev/null 2>&1; then
  echo 'target outside ADAPTER_HOME was accepted' >&2
  exit 1
fi
test ! -e "$test_root/outside/oracle.md"

rm "$manifest"
if run_generator first --check >/dev/null 2>&1; then
  echo 'missing manifest was not reported as drift' >&2
  exit 1
fi
run_generator first --apply >/dev/null
cmp "$manifest" "$test_root/second/agents/generated-adapters.yaml" >/dev/null

cp "$manifest" "$test_root/old-manifest.yaml"
cp "$oracle" "$test_root/old-oracle.md"
printf '%s\n' 'Canonical oracle change.' >> "$test_root/first/agents/prompts/oracle.md"
printf '%s\n' 'Canonical librarian change.' >> "$test_root/first/agents/prompts/librarian.md"
run_generator first --apply >/dev/null
cp "$oracle" "$test_root/desired-oracle.md"
cp "$manifest" "$test_root/desired-manifest.yaml"
cp "$test_root/old-manifest.yaml" "$manifest"
cp "$test_root/old-oracle.md" "$oracle"
run_generator first --apply >/dev/null
cmp "$oracle" "$test_root/desired-oracle.md" >/dev/null
cmp "$manifest" "$test_root/desired-manifest.yaml" >/dev/null

rm "$test_root/first/agents/prompts/librarian.md"
run_generator first --apply >/dev/null
test ! -e "$test_root/first/home/.claude/agents/librarian.md"
test ! -e "$test_root/first/home/.junie/agents/librarian.md"
test ! -e "$test_root/first/home/.config/opencode/agents/librarian.md"
if rg -F '/librarian.md:' "$manifest" >/dev/null; then
  echo 'stale manifest entries remain' >&2
  exit 1
fi
run_generator first --check >/dev/null

echo 'adapter behavioral tests passed'
