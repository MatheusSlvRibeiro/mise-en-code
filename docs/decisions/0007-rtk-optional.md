# 0007. RTK is optional, and install-all.sh installs it only on request

Status: Accepted
Date: 2026-11-24

## Context

RTK is a command-line proxy that shortens the output of common commands before it reaches the model. A hook (`rtk hook claude`) rewrites each Bash command to `rtk <command>`. On the maintainer's machine, `rtk gain` reports 3.3 million tokens saved, 47% of the input, over 6,773 commands.

It also has costs that this harness ran into:

- The output is condensed, not raw. A `grep -v` inside a pipeline that built a PR body returned RTK's summary instead of the filtered lines, and corrupted the body. `rtk proxy <command>` runs a command unfiltered.
- The hook changes a command after Claude Code's automatic permission check. Twice the check refused to evaluate the rewritten call and asked for it to be sent again unchanged.
- It is an external binary with its own license and installer. This repository is public, and its users may not have it.

RTK rewrites commands, so the harness's own hooks see `rtk git diff` and not `git diff`. `block-main-push.sh` already handled that. `readonly-bash.sh` did not: it blocked `rtk git diff`, which the `reviewer` agent needs.

## Decision

- No skill, agent, or hook requires RTK. See 0002.
- `readonly-bash.sh` judges the command under an `rtk` or `rtk proxy` prefix, so a rewritten safe command passes and `rtk proxy git push` is still blocked. This is tested.
- `wf-verify-done` tells the agent to run a command with `rtk proxy` when it must parse or pipe the exact output.
- `install-all.sh` is a second installer, next to `install.sh`. It checks the dependencies (`git`, `gh`, `jq`, and `shellcheck` for running the checks locally), offers to install the missing ones, offers RTK, and then runs `install.sh`. Rules:
  - Nothing is installed without a yes. No terminal input counts as no.
  - `--yes` answers the dependency questions. It does not cover RTK; only `--with-rtk` or a typed yes does.
  - `--dry-run` lists the commands and runs none.
  - RTK comes from Homebrew when available. Otherwise the script downloads RTK's official install script to a temporary file, prints its path and size, and runs it only after a yes.
  - Registering RTK's hook is a separate question. The script shows `rtk init -g --dry-run` first, backs up `settings.json`, and points to `rtk init -g --uninstall` for undoing it.
  - It does not add package repositories. `gh` on apt, which needs GitHub's repository, is left to the user.
- `install.sh` stays what it was: it only links files and installs nothing.

## Consequences

- A user who wants the token savings has one guided path. A user who does not is unaffected.
- The installer is tested against stub tools (`scripts/test-install-all.sh`) that record the commands they receive. Declining installs nothing, `--yes` never installs RTK, and a dry run changes nothing. This does not test a real package manager or the real RTK script.
- What `rtk init -g` changes was not read from RTK's documentation here. The installer relies on its `--dry-run` preview, the settings backup, and `--uninstall`.
- The order in which Claude Code runs several hooks on the same call is not documented in what was read. The `rtk` prefix handling in `readonly-bash.sh` makes the harness correct either way.
- Output from RTK-wrapped commands can differ from the raw command. Skills and scripts that parse output must not assume the raw form.

## Alternatives considered

- **Make RTK a requirement.** Rejected: it breaks 0002 and ties a public harness to an external binary.
- **Do not mention RTK.** Rejected: the maintainer uses it everywhere, so the interaction with the harness's hooks needed to be handled and recorded.
- **Install RTK from `install.sh`.** Rejected: `install.sh` only links files, which is why it is safe to run without thought.
