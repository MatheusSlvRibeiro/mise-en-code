#!/usr/bin/env bash
# Symlink every skill and agent from this repo into ~/.claude/. Safe to re-run.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_dir="${CLAUDE_DIR:-$HOME/.claude}"

link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok       $dest"
  elif [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "skipped  $dest (exists and is not a link to this repo)" >&2
    skipped=1
  else
    ln -s "$src" "$dest"
    echo "linked   $dest"
  fi
}

skipped=0
mkdir -p "$claude_dir/skills" "$claude_dir/agents"

for dir in "$repo"/skills/*/; do
  [ -d "$dir" ] || continue
  link "${dir%/}" "$claude_dir/skills/$(basename "$dir")"
done

for file in "$repo"/agents/*.md; do
  [ -f "$file" ] || continue
  link "$file" "$claude_dir/agents/$(basename "$file")"
done

exit "$skipped"
