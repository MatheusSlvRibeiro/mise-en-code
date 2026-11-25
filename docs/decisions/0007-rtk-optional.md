# 0007. One installer, with RTK optional

Status: Accepted
Date: 2026-11-24

## Context

RTK is a command-line proxy that shortens the output of common commands before it reaches the model. A hook (`rtk hook claude`) rewrites each Bash command to `rtk <command>`. On the maintainer's machine, `rtk gain` reports 3.3 million tokens saved, 47% of the input, over 6,773 commands.

It also has costs that this harness ran into:

- The output is condensed, not raw. A `grep -v` inside a pipeline that built a PR body returned RTK's summary instead of the filtered lines, and corrupted the body. `rtk proxy <command>` runs a command unfiltered.
- It can hide data, not only shorten it. `git log` through RTK 0.41.0 left out the merge commit of the first promotion, so a branch that was up to date looked one commit behind. `rtk proxy git log` showed it.
- The hook changes a command after Claude Code's automatic permission check. Twice the check refused to evaluate the rewritten call and asked for it to be sent again unchanged.
- It is an external binary with its own license and installer. This repository is public, and its users may not have it.

RTK rewrites commands, so the harness's own hooks see `rtk git diff` and not `git diff`. `block-main-push.sh` already handled that. `readonly-bash.sh` did not: it blocked `rtk git diff`, which the `reviewer` agent needs.

The installer started as a script that only linked files. Adding options for dependencies and RTK first produced a second script next to it. Two scripts that overlap are harder to explain than one script with questions.

## Decision

No skill, agent, or hook requires RTK. See 0002.

- `readonly-bash.sh` judges the command under an `rtk` or `rtk proxy` prefix, so a rewritten safe command passes and `rtk proxy git push` is still blocked. This is tested.
- `wf-verify-done` tells the agent to run a command with `rtk proxy` when it must parse or pipe the exact output.
- There is one installer, `install.sh`. It does these things, in order:
  1. Checks the dependencies (`git`, `gh`, `jq`, and `shellcheck` for running the checks locally) and offers to install the missing ones. It does not add package repositories, so `gh` on apt is left to the user.
  2. Offers RTK. It comes from Homebrew when available. Otherwise the script downloads RTK's official install script to a temporary file, prints its path and size, and runs it only after a yes. Registering RTK's hook is a separate question: the script shows `rtk init -g --dry-run` first, backs up `settings.json`, and points to `rtk init -g --uninstall` for undoing it.
  3. Links every skill, agent, and hook into `~/.claude/`. This step never asks: it only creates symlinks and never replaces anything that is not already a link to this repository. If a path is taken, it is skipped and the exit code is 1.
  4. Offers to register `block-main-push.sh` and `lint-on-edit.sh` in `settings.json`. It shows the diff first, backs the file up with a timestamp, adds an entry only when no hook with the same command exists, and leaves every other entry (RTK's hook, for example) as it is. It does nothing when `jq` is missing, when `settings.json` is not valid JSON, or when the hook scripts are not linked, because a hook that points to a missing file fails on every tool call. `readonly-bash.sh` is not registered: only the `reviewer` agent uses it.
- Every question defaults to no, and no terminal input counts as no. So `./install.sh < /dev/null`, or a run in CI, only links files.
- `--yes` answers the questions. It does not cover RTK: only `--with-rtk` or a typed yes does. `--dry-run` lists what would happen and changes nothing.

## Consequences

- One command, one explanation. A user who wants only the links answers no to the questions, or runs without a terminal.
- Linking and the questions share one script, so a hook is never registered before its script is linked.
- The installer is tested against stub tools (`scripts/test-install.sh`) that record the commands they receive. Declining installs nothing, `--yes` never installs RTK, a dry run changes nothing, and a taken path is left alone. This does not test a real package manager or the real RTK script.
- What `rtk init -g` changes was not read from RTK's documentation here. The installer relies on its `--dry-run` preview, the settings backup, and `--uninstall`.
- This changes one consequence recorded in 0003: `install.sh` used to only link the hook scripts and leave `settings.json` to the user. It can now register them, after asking.
- The order in which Claude Code runs several hooks on the same call is not documented in what was read. The `rtk` prefix handling in `readonly-bash.sh` makes the harness correct either way.
- Output from RTK-wrapped commands can differ from the raw command. Skills and scripts that parse output must not assume the raw form.

## Alternatives considered

- **Make RTK a requirement.** Rejected: it breaks 0002 and ties a public harness to an external binary.
- **Do not mention RTK.** Rejected: the maintainer uses it everywhere, so the interaction with the harness's hooks needed to be handled and recorded.
- **Two scripts: a links-only `install.sh` and a guided `install-all.sh`.** Tried first. Rejected: the guided script ended up calling the other, and two entry points need a paragraph to say which to use.
