#!/usr/bin/env bash
# Print the next version (without the "v") computed from the Conventional Commits since the
# last tag, or print nothing when there is nothing to release. Run it inside the repository.
#
# Rules (see ADR 0009):
#   no tag yet                       -> 0.1.0
#   feat                             -> minor
#   fix, perf                        -> patch
#   breaking (type! or a BREAKING CHANGE: line) -> major, but minor while the major is 0
#   any other type, or no type       -> no release by itself
set -eo pipefail

# An empty repository has nothing to release.
if ! git rev-parse --verify -q HEAD >/dev/null; then exit 0; fi

last_tag="$(git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' 2>/dev/null || true)"
range="HEAD"
if [ -n "$last_tag" ]; then range="$last_tag..HEAD"; fi

major=0
minor=0
patch=0
if [ -n "$last_tag" ]; then
  IFS=. read -r major minor patch <<<"${last_tag#v}"
fi

level=0 # 0 none, 1 patch, 2 minor, 3 major
commits=0
# %B is the whole message; a NUL ends each commit. Merge commits are skipped: the commits they
# bring in are what count, and a promotion merge commit has a title that carries no meaning.
while IFS= read -r -d '' message; do
  # git ends each record with a newline, so the next message starts with a blank line.
  message="${message#"${message%%[!$'\n']*}"}"
  commits=$((commits + 1))
  subject="${message%%$'\n'*}"
  type=""
  breaking=0
  if [[ "$subject" =~ ^([a-z]+)(\([^\)]*\))?(!)?:\  ]]; then
    type="${BASH_REMATCH[1]}"
    if [ -n "${BASH_REMATCH[3]}" ]; then breaking=1; fi
  fi
  if grep -qE '^BREAKING[ -]CHANGE:' <<<"$message"; then breaking=1; fi

  if [ "$breaking" = 1 ]; then
    if [ "$major" = 0 ]; then bump=2; else bump=3; fi
  elif [ "$type" = feat ]; then
    bump=2
  elif [ "$type" = fix ] || [ "$type" = perf ]; then
    bump=1
  else
    bump=0
  fi
  if [ "$bump" -gt "$level" ]; then level="$bump"; fi
done < <(git log --no-merges --format='%B%x00' "$range")

if [ -z "$last_tag" ]; then
  if [ "$commits" -gt 0 ]; then echo "0.1.0"; fi
  exit 0
fi

case "$level" in
  3) echo "$((major + 1)).0.0" ;;
  2) echo "$major.$((minor + 1)).0" ;;
  1) echo "$major.$minor.$((patch + 1))" ;;
esac
