#!/bin/sh
set -eu

source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target_dir="${CODEX_HOME:-$HOME/.codex}/skills/mimic-research-explorer"

mkdir -p "$target_dir"
cp -R "$source_dir/SKILL.md" "$source_dir/agents" "$source_dir/references" "$target_dir/"
printf 'Installed skill to %s\n' "$target_dir"
