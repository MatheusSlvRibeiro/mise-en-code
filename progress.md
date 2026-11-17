# Progress

## Current state

Phases 1–3 are verified. P7 (project board) is implemented and waits for the maintainer to verify it. Phase 4 (stack skills) is implemented and in review: `be-django-api`, `be-jwt-auth`, `fe-react-ui`, `fe-forms`, `fe-tailwind`, `test-pytest`, `test-vitest`. No ADRs or agents exist yet.

## Last session

Wrote the seven stack skills on branch `feat/stack-skills`. The Django, Vitest, zod, SCSS and Tailwind code in them was run in throwaway projects with current versions (Django 6.1, DRF 3.18, React 19, zod 4, Vite 8, Vitest 5, Tailwind 4, TypeScript 7) before it went into the skills.

## Next step

Start Phase 5 (ADRs): `docs/decisions/` with a template and the initial ADRs (flat skills, no mandatory MCP, hooks). Then Phase 6 (agents). Lint-config templates (`ruff`, `eslint`) are planned as a later item (P8), so rules a linter can enforce are not in the skills yet.

## Open issues

- Cookie auth is the standard for new projects; an existing project that uses a Bearer header (the reference Django project does) is not covered by `be-jwt-auth` and would need a separate decision.
- The reference Django project reads `DEBUG` as a raw string (`os.getenv('DEBUG')`), so `"False"` is truthy. `be-django-api` documents the safe form; the project itself is not changed here.
- Rules that a linter could enforce (default exports, `any`, inline styles, arbitrary Tailwind values, `fields = '__all__'`) are prose until P8.
- `notes.md` (the user's conventions) stays untracked on purpose.
- Not decided: the sprint cadence (iteration length and start day).
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
