---
name: wf-verify-done
description: Checks that a task is really finished before reporting it done. Use before saying a task is complete, marking a feature `implemented`, or opening a PR.
---

# Verify done

1. Run the project's real checks: tests, linter, type-check, build. Use the commands the project defines.
2. Read the output. A check passes only if you saw it pass.
3. Confirm that every file or path the change refers to exists.
4. Report the result as it is: failures with their output, and any check you could not run, with the reason.
5. Only if everything passed, mark the feature `implemented` in `feature_list.json`.

Never set `verified`. Only the user does.
