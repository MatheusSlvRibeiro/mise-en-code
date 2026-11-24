#!/usr/bin/env bash
# Repository structure checks. Run locally before opening a PR; CI runs the same script.
# Set BASE_REF (e.g. preview) to also check that README changes are paired.
set -eo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
failures=0
fail() {
  echo "FAIL $1"
  failures=$((failures + 1))
}

frontmatter() { # frontmatter <file> <key>
  awk -v key="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    index($0, key ": ") == 1 { print substr($0, length(key) + 3); exit }
  ' "$1"
}

# Skills: flat, named after their directory, with a domain prefix and a description.
while IFS= read -r nested; do
  fail "nested skill is not allowed: $nested"
done < <(find skills -mindepth 3 -name SKILL.md 2>/dev/null)

while IFS= read -r stray; do
  fail "skills/ must contain only skill directories: $stray"
done < <(find skills -mindepth 1 -maxdepth 1 -not -type d 2>/dev/null)

for dir in skills/*/; do
  [ -d "$dir" ] || continue
  dir="${dir%/}"
  name="$(basename "$dir")"
  file="$dir/SKILL.md"
  if [ ! -f "$file" ]; then
    fail "$dir has no SKILL.md"
    continue
  fi
  [ "$(frontmatter "$file" name)" = "$name" ] || fail "$file: name must equal the directory name '$name'"
  [ -n "$(frontmatter "$file" description)" ] || fail "$file: missing description"
  [[ "$name" =~ ^(wf|be|fe|test)- ]] || fail "$dir: name must start with wf-, be-, fe-, or test-"
done

# JSON state files.
for json in feature_list.json templates/feature_list.json settings.example.json; do
  jq -e . "$json" >/dev/null 2>&1 || fail "$json is not valid JSON"
done
for json in feature_list.json templates/feature_list.json; do
  jq -e '[.features[].status] | all(IN("pending", "implemented", "verified"))' "$json" >/dev/null 2>&1 ||
    fail "$json: status must be pending, implemented, or verified"
done

# Agent entry files.
[ "$(wc -l <AGENTS.md)" -le 60 ] || fail "AGENTS.md has more than 60 lines"
[ "$(cat CLAUDE.md)" = "@AGENTS.md" ] || fail "CLAUDE.md must contain only @AGENTS.md"

# READMEs: both start with the language switch, and change together.
switch='[English](README.md) | [Português](README.pt-BR.md)'
for readme in README.md README.pt-BR.md; do
  [ "$(head -n 1 "$readme")" = "$switch" ] || fail "$readme: first line must be the language switch"
done
if [ -n "${BASE_REF:-}" ]; then
  changed="$(git diff --name-only "origin/$BASE_REF"...HEAD)"
  en=0
  pt=0
  grep -qx 'README.md' <<<"$changed" && en=1
  grep -qx 'README.pt-BR.md' <<<"$changed" && pt=1
  [ "$en" = "$pt" ] || fail "README.md and README.pt-BR.md must change in the same PR"
fi

# Agents: named after the file, a pinned model, explicit tools, no write tools,
# and any hook script they reference exists in hooks/.
for file in agents/*.md; do
  [ -f "$file" ] || continue
  name="$(basename "$file" .md)"
  [ "$(frontmatter "$file" name)" = "$name" ] || fail "$file: name must equal the file name '$name'"
  [ -n "$(frontmatter "$file" description)" ] || fail "$file: missing description"
  [[ "$(frontmatter "$file" model)" =~ ^(haiku|sonnet|opus)$ ]] || fail "$file: model must be haiku, sonnet, or opus"
  tools="$(frontmatter "$file" tools)"
  [ -n "$tools" ] || fail "$file: tools must be listed explicitly"
  if [[ "$tools" =~ (Edit|Write|NotebookEdit) ]]; then
    fail "$file: agents must not have write tools"
  fi
  while IFS= read -r hook; do
    [ -f "hooks/$hook" ] || fail "$file: references missing hooks/$hook"
  done < <(grep -oE '\.claude/hooks/[A-Za-z0-9._-]+\.sh' "$file" | sed 's|.*/||')
done

# Decision records: every ADR is listed in the index and has a valid Status line.
[ -f docs/decisions/README.md ] || fail "docs/decisions/README.md is missing"
for adr in docs/decisions/[0-9][0-9][0-9][0-9]-*.md; do
  [ -f "$adr" ] || continue
  grep -qF "$(basename "$adr")" docs/decisions/README.md 2>/dev/null ||
    fail "docs/decisions/README.md does not list $(basename "$adr")"
  grep -qE '^Status: (Proposed|Accepted|Superseded by [0-9]{4})$' "$adr" ||
    fail "$adr: needs a line 'Status: Proposed', 'Accepted', or 'Superseded by NNNN'"
done

# Shell scripts.
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck install.sh hooks/*.sh scripts/*.sh skills/*/*.sh || fail "shellcheck reported problems"
elif [ -n "${CI:-}" ]; then
  fail "shellcheck is not installed"
else
  echo "SKIP shellcheck (not installed locally; CI runs it)"
fi

./scripts/test-hooks.sh >/dev/null || fail "hook tests failed (run scripts/test-hooks.sh)"
./scripts/test-install.sh >/dev/null || fail "install tests failed (run scripts/test-install.sh)"
./scripts/test-release.sh >/dev/null || fail "release tests failed (run scripts/test-release.sh)"

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
