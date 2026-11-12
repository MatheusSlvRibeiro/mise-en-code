# Progress

## Current state

Phases 1 and 2 are done and verified: foundation files and the three workflow skills. The `preview` branch exists. The `protect-main` ruleset allows only merge commits, and `protect-preview` allows only squash. No hooks or agents exist yet.

## Last session

Created `preview` and the two rulesets, and updated `wf-git-flow` for the preview flow.

## Next step

Start Phase 3 (Enforcement) on a branch from `preview`. After the CI job has run once on a PR, propose a `required_status_checks` rule for `check.sh` on both rulesets.

## Open issues

- `notes.md` (the user's conventions) stays untracked on purpose. It still says branches start from `main` and that PRs are squash-only; the skills follow the preview flow.
