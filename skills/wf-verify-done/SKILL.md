---
name: wf-verify-done
description: Checks that a task is really finished before reporting it done. Use before saying a task is complete, marking a feature `implemented`, or opening a PR.
---

# Verify done

1. Run the project's real checks: tests, linter, type-check, build. Use the commands the project defines.
2. Read the output. A check passes only if you saw it pass.
3. If the change affects a user-facing flow, start the app and test that flow in the browser.
4. Confirm that every file or path the change refers to exists.
5. Report the result as it is: failures with their output, and any check you could not run, with the reason.
6. Review your own diff for these usual mistakes:
   - a new dependency you added without asking
   - a model change without its migration, created and applied
   - files changed outside the task's scope
   - a new file where editing an existing one would do
   - `any`, or a disabled lint rule, instead of a real fix
7. Only if everything passed, mark the feature `implemented` in `feature_list.json`.

Never set `verified`. Only the user does.
