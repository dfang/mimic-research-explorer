#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM

# Run outside the project and use paths containing spaces.
mkdir -p "$test_dir/source skill"
cp -R "$project_dir/install.sh" "$project_dir/SKILL.md" "$project_dir/agents" "$project_dir/references" "$test_dir/source skill/"
cd "$test_dir"
CODEX_HOME="$test_dir/codex home" "$test_dir/source skill/install.sh"
target_dir="$test_dir/codex home/skills/mimic-research-explorer"
cmp "$project_dir/SKILL.md" "$target_dir/SKILL.md"
diff -r "$project_dir/agents" "$target_dir/agents"
diff -r "$project_dir/references" "$target_dir/references"
test ! -e "$target_dir/install.sh"

touch "$target_dir/local-file"
CODEX_HOME="$test_dir/codex home" "$test_dir/source skill/install.sh"
test -f "$target_dir/local-file"
diff -r "$project_dir/agents" "$target_dir/agents"
diff -r "$project_dir/references" "$target_dir/references"

HOME="$test_dir/default home" CODEX_HOME= "$test_dir/source skill/install.sh"
cmp "$project_dir/SKILL.md" "$test_dir/default home/.codex/skills/mimic-research-explorer/SKILL.md"
printf 'Installation checks passed\n'
