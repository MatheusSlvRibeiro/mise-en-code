#!/usr/bin/env bash
# Claude Code PostToolUse hook (matcher: Edit|Write|MultiEdit).
# Lints the edited file. Exit 2 sends the linter output back to the agent.
# Skips silently when the project has no linter for the file type.
set -eo pipefail

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$file" ] && [ -f "$file" ] || exit 0
project="${CLAUDE_PROJECT_DIR:-$PWD}"

run() {
  local out
  if ! out=$("$@" 2>&1); then
    printf 'Lint failed for %s:\n%s\n' "$file" "$out" >&2
    exit 2
  fi
}

case "$file" in
  *.py)
    command -v ruff >/dev/null 2>&1 || exit 0
    run ruff check "$file"
    ;;
  *.ts | *.tsx | *.js | *.jsx)
    eslint="$project/node_modules/.bin/eslint"
    [ -x "$eslint" ] || exit 0
    cd "$project"
    run "$eslint" "$file"
    ;;
esac
