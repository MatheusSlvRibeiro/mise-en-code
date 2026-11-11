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
templates/    feature_list.json and progress.md for your own projects
docs/decisions/   ADRs
```

## Install

```bash
git clone https://github.com/MatheusSlvRibeiro/mise-en-code
cd mise-en-code
./install.sh
```

`install.sh` symlinks every skill into `~/.claude/skills/` and every agent into `~/.claude/agents/`. It is safe to run again, and it never overwrites something that is not already a link to this repo.

## Status

Work is tracked in [`feature_list.json`](feature_list.json) and [`progress.md`](progress.md). Status moves `pending` → `implemented` → `verified`, and only the maintainer sets `verified`.

## License

[MIT](LICENSE)
