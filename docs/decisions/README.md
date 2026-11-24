# Decision records

An ADR records a decision, why it was made, and what it costs. Write one before building on a decision, and never edit an accepted one to change its meaning: add a new ADR and mark the old one `Superseded by NNNN`.

Start from [template.md](template.md). Number records in order (`0006-short-title.md`) and add each one to the table below. `scripts/check.sh` fails the PR if a record is missing from this table or has no valid `Status:` line.

| Record | Decision | Status |
|---|---|---|
| [0001](0001-flat-skills.md) | Keep skills flat, with a domain prefix | Accepted |
| [0002](0002-no-mandatory-mcp.md) | No mandatory MCP dependencies; state lives in files | Accepted |
| [0003](0003-hooks-over-prose.md) | Enforce yes/no rules with hooks and CI, not prose | Accepted |
| [0004](0004-preview-main-flow.md) | Work flows through `preview` into `main` | Accepted |
| [0005](0005-cookie-jwt-auth.md) | Authenticate SPAs with JWT in httpOnly cookies | Accepted |
| [0006](0006-agent-models-and-tools.md) | Pin a model and a minimal tool set for each agent | Accepted |
| [0007](0007-rtk-optional.md) | One installer, with RTK optional | Accepted |
| [0008](0008-memory-tools-not-installed.md) | `install.sh` does not install MemPalace or OpenSpace | Accepted |
| [0009](0009-versioning-with-tags.md) | Version with tags computed from the commit types | Accepted |
