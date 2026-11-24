# 0008. install-all.sh does not install MemPalace or OpenSpace

Status: Accepted
Date: 2026-11-24

## Context

The previous version of this harness required two tools beyond the repository: MemPalace, a memory that saves your sessions and searches them later, and OpenSpace, which evolves skills automatically. Looking at them again for the installer showed problems that the old setup had hidden:

- **The old setup registered no MCP server at all.** It wrote `~/.claude/mcp.json`, which Claude Code (version 2.1.251 here) does not read: `claude mcp list` does not show those servers, and `~/.claude.json` has none. The entry also ran `mempalace mcp`, which only prints help; the server is `mempalace-mcp`. The supported way is `claude mcp add --scope user`. Registering MemPalace that way was tested in a throwaway home and `claude mcp get` reported it connected.
- **MemPalace stores your session transcripts** in a local palace. Its documentation says nothing leaves the machine unless you opt in. Its auto-save hooks block the model every 15 messages to make it save. That is a ritual in every session, which this harness set out to remove. The package's publisher could not be confirmed beyond the PyPI and GitHub pages pointing at each other. The old setup also downloaded its hook scripts from a moving `master` branch; the installed CLI now offers `mempalace hook run`, which needs no download.
- **OpenSpace rewrites skills on its own.** Its documentation does not say how to turn that off or require approval, and it gives no setup for Claude Code. Its repository address now shows a different repository (`AgentPilot`), and the install method changed to a clone and a virtual environment. Pointed at `~/.claude/skills`, it could change files in this repository through the symlinks `install.sh` creates. 0002 already rejected skills that rewrite themselves.

The maintainer is also considering a knowledge base built from an Obsidian vault, with a vector index for retrieval, and wants to see the options before choosing a memory tool.

## Decision

`install-all.sh` offers RTK (0007) and nothing else of this kind. It does not install MemPalace or OpenSpace. This is not a judgment that they are bad; the harness does not need either, and the first question about memory is still open.

If a memory tool is added later:

- Register MCP servers with `claude mcp add --scope user`, never by writing `~/.claude/mcp.json`.
- Use the tool's own hook command instead of downloading scripts from a branch.
- Ask separately about hooks that block or rewrite a session, default no, and say what they do.
- Never point a tool that edits skills at a directory containing symlinks into this repository.

## Consequences

- Cross-session state stays in `feature_list.json`, `progress.md`, and commits, as 0002 says.
- Someone who wants MemPalace or OpenSpace installs them by hand, with the caveats above.
- The Obsidian option is not designed here. Options exist that index a vault into a local vector store and expose search over MCP; evaluating them is a separate piece of work.
- Not verified here: the PyPI publisher of MemPalace, what OpenSpace's skill evolution can be configured to do, and the hook behavior of either in a real session beyond the one stop-hook call tested.

## Alternatives considered

- **Offer both behind questions, as asked at first.** Rejected for now: OpenSpace's Claude Code setup is undocumented and it conflicts with 0002, and MemPalace's hooks conflict with the no-ritual rule.
- **Offer MemPalace with the MCP only.** Possible later. Deferred until the Obsidian option has been looked at, so the choice is made once.
