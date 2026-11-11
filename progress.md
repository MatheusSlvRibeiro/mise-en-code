# Progress

## Current state

Phases 1 and 2 are done: foundation files and the three workflow skills (`wf-git-flow`, `wf-verify-done`, `wf-session-handoff`). Phase 2 is in review. No hooks or agents exist yet.

## Last session

Wrote the Phase 2 skills on branch `phase-2-workflow` and opened its PR.

## Next step

After the Phase 2 PR is merged, start Phase 3 (Enforcement). After the CI job has run once on a PR, propose a `required_status_checks` rule for `check.sh` on the `protect-main` ruleset.

## Open issues

- `NOTES.md` (the user's conventions) is not in the repo yet. The Phase 2 skills use only the conventions stated in the task; revisit them when `NOTES.md` arrives. Needed for Phase 4.
