[English](README.md) | [Português](README.pt-BR.md)

# mise-en-code

Everything in its place before your coding agent starts cooking.

*Mise en place* is the kitchen habit of preparing and arranging every ingredient before cooking. `mise-en-code` does the same for [Claude Code](https://claude.com/claude-code): a small, opinionated harness that sets up conventions, guardrails, and session state before the agent writes a line of code.

It targets Django + DRF, React + Vite + TypeScript, and GitHub workflows.

## Principles

- **Flat skills.** One directory per skill under `skills/`, prefixed by domain: `wf-` (workflow), `be-` (backend), `fe-` (frontend), `test-`.
- **Hooks over prose.** A rule with a yes/no answer is enforced by a Claude Code hook or a CI check, not by a sentence in a prompt.
- **Small context.** `AGENTS.md` stays around 60 lines. Every line must prevent a real mistake.
- **State in files.** Cross-session state lives in `feature_list.json`, `progress.md`, and commits. No MCP server is required.
- **Decisions on record.** Architectural choices are ADRs in `docs/decisions/`.

## Layout

```
skills/       one flat directory per skill, each with a SKILL.md
agents/       subagents with a pinned model and minimal tools
hooks/        shell scripts for Claude Code hooks
scripts/      check.sh, the structure checks that CI runs
templates/    feature_list.json and progress.md for your own projects
docs/decisions/   ADRs
```

## Install

```bash
git clone https://github.com/MatheusSlvRibeiro/mise-en-code
cd mise-en-code
./install.sh
```

`install.sh` is the only installer. It checks the dependencies (`git`, `gh`, `jq`) and offers to install what is missing, offers [RTK](#optional-rtk), links the skills, agents, and hooks, and offers to register the hooks. Every question defaults to no, and with no terminal it only links files. `--yes` answers the questions, `--dry-run` only lists what it would do, and RTK needs `--with-rtk` or a typed yes.

The linking step symlinks every skill into `~/.claude/skills/`, every agent into `~/.claude/agents/`, and every hook into `~/.claude/hooks/`. It is safe to run again, and it never overwrites something that is not already a link to this repo.

Hooks only run once they are registered. `install.sh` offers to do it for you: it shows the change to `~/.claude/settings.json`, backs the file up, adds the `block-main-push` and `lint-on-edit` hooks, and leaves your other hooks (RTK's, for example) untouched. To do it by hand, copy the entries you want from [`settings.example.json`](settings.example.json). Restart Claude Code afterwards.

## Optional: RTK

[RTK](https://github.com/rtk-ai/rtk) shortens command output before it reaches the model, which saves tokens. Nothing here requires it. If you use it, run `rtk gain` to confirm you have the right package, and use `rtk proxy <command>` when you need the exact, unfiltered output. See [ADR 0007](docs/decisions/0007-rtk-optional.md).

## Status

Work is tracked in [`feature_list.json`](feature_list.json) and [`progress.md`](progress.md). Status moves `pending` → `implemented` → `verified`, and only the maintainer sets `verified`.

## License

[MIT](LICENSE)
