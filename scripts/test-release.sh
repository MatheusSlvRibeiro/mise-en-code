#!/usr/bin/env bash
# Tests next-version.sh and release-notes.sh against throwaway Git repositories.
set -eo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
base="$(mktemp -d)"
trap 'rm -rf "$base"' EXIT
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  failures=$((failures + 1))
}

# git inside the throwaway repo, with an identity and without hooks or signing.
g() { git -C "$repo" -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@"; }

new_repo() {
  repo="$(mktemp -d "$base/r.XXXXXX")"
  git -C "$repo" init -q -b main
}

c() { g commit -q --allow-empty -m "$1"; } # c <message>; "\n" in the message is a real newline
cm() { g commit -q --allow-empty -m "$(printf '%b' "$1")"; }

next() { (cd "$repo" && "$root/scripts/next-version.sh"); }
notes() { (cd "$repo" && GITHUB_REPOSITORY=o/r "$root/scripts/release-notes.sh" "$@"); }

expect_version() { # expect_version <label> <want>  (want "" means no release)
  local got
  got="$(next)"
  if [ "$got" = "$2" ]; then pass "$1"; else fail "$1 (want '$2', got '$got')"; fi
}

# --- no tag yet -------------------------------------------------------------
new_repo
c "chore: first commit"
expect_version "no tag, any commit: 0.1.0" "0.1.0"

new_repo
expect_version "no tag, no commits: nothing" ""

# --- 0.x --------------------------------------------------------------------
new_repo; c "chore: base"; g tag v0.1.0
expect_version "no commits since the tag: nothing" ""

c "docs: update the readme (#1)"; c "chore: tidy"; c "ci: tweak"; c "test: more"; c "refactor: split"; c "style: format"
expect_version "docs, chore, ci, test, refactor, style: nothing" ""

c "Update the readme"
expect_version "a subject without a type: nothing" ""

c "fix: a bug (#2)"
expect_version "fix: patch" "0.1.1"

c "perf: faster"
expect_version "fix and perf: still patch" "0.1.1"

c "feat: a feature (#3)"
expect_version "feat after fix: minor wins" "0.2.0"

new_repo; c "chore: base"; g tag v0.1.0; c "feat(skills): add a skill (#4)"
expect_version "feat with a scope: minor" "0.2.0"

new_repo; c "chore: base"; g tag v0.4.2; c "feat!: rename a skill"
expect_version "0.x: feat! stays below 1.0.0" "0.5.0"

new_repo; c "chore: base"; g tag v0.4.2; c "fix(ci)!: change the trigger"
expect_version "0.x: fix(scope)! counts as breaking, minor" "0.5.0"

new_repo; c "chore: base"; g tag v0.4.2; cm "docs: change the layout\n\nBREAKING CHANGE: the layout moved"
expect_version "0.x: BREAKING CHANGE footer counts, minor" "0.5.0"

new_repo; c "chore: base"; g tag v0.4.2; cm "fix: a bug\n\nBREAKING-CHANGE: hyphenated footer"
expect_version "0.x: BREAKING-CHANGE footer counts, minor" "0.5.0"

new_repo; c "chore: base"; g tag v0.4.2; cm "fix: a bug\n\nthis is not a BREAKING CHANGE: footer, it is prose"
expect_version "prose that mentions the footer mid-line does not count" "0.4.3"

# The decisive commit is not the newest one. git log lists newest first, so these catch a parser
# that reads only the first record.
new_repo; c "chore: base"; g tag v0.1.0; c "feat: older feature"; c "docs: newer docs"; c "chore: newer chore"
expect_version "an older feat still counts after newer docs and chore" "0.2.0"

new_repo; c "chore: base"; g tag v0.1.0; c "fix: older fix"; c "docs: newer docs"; c "ci: newer ci"
expect_version "an older fix still counts after newer docs and ci" "0.1.1"

new_repo; c "chore: base"; g tag v1.0.0; c "feat!: older breaking change"; c "fix: newer fix"; c "docs: newer docs"
expect_version "an older breaking change still wins over newer fixes" "2.0.0"

new_repo; c "chore: base"; g tag v1.0.0; cm "feat: older, with a footer\n\nBREAKING CHANGE: x"; c "fix: newer"; c "docs: newer"
expect_version "an older BREAKING CHANGE footer still wins" "2.0.0"

# --- 1.x and later ----------------------------------------------------------
new_repo; c "chore: base"; g tag v1.2.3; c "fix: x"
expect_version "1.x: fix" "1.2.4"

new_repo; c "chore: base"; g tag v1.2.3; c "feat: x"
expect_version "1.x: feat" "1.3.0"

new_repo; c "chore: base"; g tag v1.2.3; c "feat!: x"
expect_version "1.x: feat! is major" "2.0.0"

new_repo; c "chore: base"; g tag v1.2.3; cm "fix: x\n\nBREAKING CHANGE: y"
expect_version "1.x: BREAKING CHANGE footer is major" "2.0.0"

new_repo; c "chore: base"; g tag v1.9.9; c "feat: x"
expect_version "minor resets patch and rolls over 9 correctly" "1.10.0"

# --- tags and merges --------------------------------------------------------
new_repo; c "chore: base"; g tag v0.1.0; g tag latest; g tag v0.1.0-rc1; c "fix: x"
expect_version "tags that are not vX.Y.Z are ignored" "0.1.1"

new_repo; c "chore: base"; g tag v0.1.0; c "fix: old"; g tag v0.1.1; c "docs: only docs since the last tag"
expect_version "counts only commits after the newest tag" ""

# The promotion shape: preview has commits, main gets a merge commit with an uninformative title.
new_repo; c "chore: base"; g tag v0.1.0
g checkout -q -b preview; c "feat: from preview (#5)"; c "docs: also from preview"
g checkout -q main; g merge -q --no-ff preview -m "chore(release): promote preview to main"
expect_version "promotion merge commit: the commits it brings decide" "0.2.0"

new_repo; c "chore: base"; g tag v0.1.0
g checkout -q -b preview; c "docs: only docs"; c "chore: only chores"
g checkout -q main; g merge -q --no-ff preview -m "feat: a merge title that must be ignored"
expect_version "promotion merge commit: its own title is ignored" ""

# --- release notes ----------------------------------------------------------
new_repo; c "chore: base"; g tag v0.1.0
c "feat(skills): add a skill (#10)"; c "fix: repair a thing (#11)"; c "perf: go faster"
c "docs: explain (#12)"; cm "refactor!: drop the old layout\n\nBREAKING CHANGE: moved"
out="$(notes 0.2.0)"
has() { grep -qF -- "$1" <<<"$out"; }
if has "## Breaking changes" && has "- drop the old layout"; then pass "notes: breaking section"; else fail "notes: breaking section"; fi
if has "## Features" && has "- **skills:** add a skill (#10)"; then pass "notes: features, with the scope in bold"; else fail "notes: features"; fi
if has "## Fixes" && has "- repair a thing (#11)"; then pass "notes: fixes"; else fail "notes: fixes"; fi
if has "## Performance" && has "- go faster"; then pass "notes: performance"; else fail "notes: performance"; fi
if has "## Other changes" && has "- explain (#12)"; then pass "notes: other changes (docs)"; else fail "notes: other changes"; fi
if has "- base"; then fail "notes: commits before the tag are not listed"; else pass "notes: commits before the tag are not listed"; fi
if has "compare/v0.1.0...v0.2.0"; then pass "notes: compare link"; else fail "notes: compare link"; fi
order="$(grep -n '^## ' <<<"$out" | sed 's/.*## //' | tr '\n' ',')"
if [ "$order" = "Breaking changes,Features,Fixes,Performance,Other changes," ]; then pass "notes: sections in a fixed order"; else fail "notes: order ($order)"; fi

new_repo; c "chore: base"; g tag v0.1.0; c "fix: only a fix"
out="$(notes 0.1.1)"
if has "## Fixes" && ! has "## Features" && ! has "## Breaking changes"; then pass "notes: empty sections are omitted"; else fail "notes: empty sections are omitted"; fi

new_repo; c "feat: very first"
out="$(notes 0.1.0)"
if has "- very first" && ! has "compare/"; then pass "notes: no tag yet lists everything and has no compare link"; else fail "notes: first release"; fi

# --- the workflow's own run step, with a fake gh -----------------------------
# Extract the real `run:` block from release.yml, so the test runs what Actions will run.
run_block="$(awk '/^        run: \|$/ {on=1; next} on && /^          / {sub(/^          /, ""); print; next} on {exit}' "$root/.github/workflows/release.yml")"
if [ -z "$run_block" ]; then fail "workflow: could not extract the run block"; fi

run_workflow() { # runs the block in $repo with scripts/ copied in and a gh that logs its arguments
  mkdir -p "$repo/scripts" "$repo/fakebin"
  cp "$root/scripts/next-version.sh" "$root/scripts/release-notes.sh" "$repo/scripts/"
  # shellcheck disable=SC2016  # the fake gh's text stays literal; only the repo path is filled in
  printf '#!/bin/sh\necho "gh $*" >> "%s/gh.log"\nwhile [ $# -gt 0 ]; do\n  if [ "$1" = --notes-file ]; then cp "$2" "%s/notes.copy"; fi\n  shift\ndone\n' "$repo" "$repo" >"$repo/fakebin/gh"
  chmod +x "$repo/fakebin/gh"
  : >"$repo/gh.log"
  (cd "$repo" && PATH="$repo/fakebin:$PATH" RUNNER_TEMP="$repo" GITHUB_SHA="$(git rev-parse HEAD)" GITHUB_REPOSITORY=o/r bash -e -c "$run_block") >"$repo/wf.out" 2>&1
}

new_repo; c "chore: base"; c "feat: first feature (#1)"
run_workflow
if grep -qE '^gh release create v0\.1\.0 --target [0-9a-f]{40} --title v0\.1\.0 --notes-file .* --latest$' "$repo/gh.log"; then
  pass "workflow: the first promotion creates release v0.1.0"; else fail "workflow: first release ($(cat "$repo/gh.log"))"; fi
if grep -qF -- "- first feature (#1)" "$repo/notes.copy"; then pass "workflow: the notes file reaches gh"; else fail "workflow: notes file"; fi

new_repo; c "chore: base"; g tag v0.1.0; c "docs: only docs"
run_workflow
if [ ! -s "$repo/gh.log" ] && grep -q "No releasable commit" "$repo/wf.out"; then
  pass "workflow: nothing to release makes no gh call"; else fail "workflow: nothing to release"; fi

new_repo; c "chore: base"; g tag v0.3.0; c "fix: a bug"
run_workflow
if grep -q '^gh release create v0\.3\.1 ' "$repo/gh.log"; then pass "workflow: a fix after v0.3.0 releases v0.3.1"; else fail "workflow: patch release"; fi

[ "$failures" = 0 ] || { echo "$failures release test(s) failed"; exit 1; }
echo "all release tests passed"
