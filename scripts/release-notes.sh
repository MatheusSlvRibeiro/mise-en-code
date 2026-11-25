#!/usr/bin/env bash
# Print release notes in Markdown, from the commits since the last tag, grouped by type.
# Run it inside the repository. Set GITHUB_REPOSITORY (owner/name) to add a compare link.
# Usage: scripts/release-notes.sh [<new-version>]   (without the "v")
set -eo pipefail

new_version="${1:-}"
# An empty repository has nothing to release.
if ! git rev-parse --verify -q HEAD >/dev/null; then exit 0; fi

last_tag="$(git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' 2>/dev/null || true)"
range="HEAD"
if [ -n "$last_tag" ]; then range="$last_tag..HEAD"; fi

breaking_items=""
feat_items=""
fix_items=""
perf_items=""
other_items=""

# add <variable-name> <line>: append a bullet to one of the lists above.
add() { printf -v "$1" '%s- %s\n' "${!1}" "$2"; }

while IFS= read -r -d '' message; do
  # git ends each record with a newline, so the next message starts with a blank line.
  message="${message#"${message%%[!$'\n']*}"}"
  subject="${message%%$'\n'*}"
  type=""
  scope=""
  breaking=0
  description="$subject"
  if [[ "$subject" =~ ^([a-z]+)(\(([^\)]*)\))?(!)?:\ (.*)$ ]]; then
    type="${BASH_REMATCH[1]}"
    scope="${BASH_REMATCH[3]}"
    description="${BASH_REMATCH[5]}"
    if [ -n "${BASH_REMATCH[4]}" ]; then breaking=1; fi
  fi
  if grep -qE '^BREAKING[ -]CHANGE:' <<<"$message"; then breaking=1; fi

  line="$description"
  if [ -n "$scope" ]; then line="**$scope:** $description"; fi

  if [ "$breaking" = 1 ]; then
    add breaking_items "$line"
  elif [ "$type" = feat ]; then
    add feat_items "$line"
  elif [ "$type" = fix ]; then
    add fix_items "$line"
  elif [ "$type" = perf ]; then
    add perf_items "$line"
  else
    add other_items "$line"
  fi
done < <(git log --no-merges --format='%B%x00' "$range")

section() { # section <title> <items>
  if [ -n "$2" ]; then
    printf '## %s\n\n%s\n' "$1" "$2"
  fi
}

section "Breaking changes" "$breaking_items"
section "Features" "$feat_items"
section "Fixes" "$fix_items"
section "Performance" "$perf_items"
section "Other changes" "$other_items"

if [ -n "$last_tag" ] && [ -n "$new_version" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
  echo "**Full changelog:** https://github.com/$GITHUB_REPOSITORY/compare/$last_tag...v$new_version"
fi
