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

ruby -ryaml -e '
  root = ARGV.fetch(0)
  names = {}
  Dir.glob(File.join(root, "*", "SKILL.md")).sort.each do |path|
    text = File.read(path)
    match = text.match(/\A---\s*\n(.*?)\n---/m) or abort("missing frontmatter: #{path}")
    data = YAML.safe_load(match[1])
    name = data.fetch("name")
    description = data.fetch("description")
    dir = File.basename(File.dirname(path))
    abort("name mismatch: #{path}") unless name == dir
    abort("invalid name: #{name}") unless name.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
    abort("description too long: #{name}") unless (1..1024).cover?(description.length)
    abort("duplicate skill: #{name}") if names[name]
    names[name] = path
  end
  puts "validated #{names.length} skills"
' "$agents_root/skills" || failures=$((failures + 1))

if [ "$failures" -ne 0 ]; then
  echo "$failures verification check(s) failed" >&2
  exit 1
fi

echo "setup verification passed"
