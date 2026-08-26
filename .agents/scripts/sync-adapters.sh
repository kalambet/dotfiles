#!/bin/sh
set -eu

mode=${1:---check}
case "$mode" in
  --check|--apply) ;;
  *) echo "usage: $0 [--check|--apply]" >&2; exit 2 ;;
esac

agents_root=${AGENTS_ROOT:-"$HOME/.agents"}
exec ruby "$agents_root/scripts/generate_adapters.rb" \
  "$agents_root/adapters.yaml" "$mode"
