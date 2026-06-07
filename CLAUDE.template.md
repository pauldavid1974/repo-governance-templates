# Operating Rules — <PROJECT_NAME>

> **How to use this template:** Copy it to your new repo's root as `CLAUDE.md`. Replace
> every `<PLACEHOLDER>` and delete what doesn't apply. This is the short, always-on
> version that loads into every session; the full rationale lives in `REPO_RULES.md`.

This file is loaded into every session. Read it as standing instructions, not background.

## Before any code or file change

1. **Branch first.** Never commit on `main`. Create `git switch -c <type>/<short-desc>`
   (`feat/`, `fix/`, `docs/`, `chore/`) *before* changing anything.
   <If you add the branch-guard hook, note: "A hook enforces this — commits/pushes on `main` are blocked.">
2. **Track the work.** For anything beyond a one-step edit, keep a task list and update it
   as you go (in_progress when starting, completed when done).

## While working

- Keep changes scoped to one logical thing. A fix and a refactor are two branches / two PRs.
- Follow the stack and constraints in `REPO_RULES.md`: <one-line reminder of the hard
  constraints — e.g. "pinned deps, no telemetry, local-only">.

## Before ending a turn

- **Update `WORKLOG.md`** whenever you finished or meaningfully advanced a task: append a
  dated entry (what changed, which branch, what's next, open decisions). This is the
  project's memory across sessions — if it isn't written down, the next session won't know it.
- Land changes on `main` through a PR, not a direct push.

## Quick reference

- Source of truth for rules: `REPO_RULES.md`
- <Build spec / design doc: `<path>`>
- <Debug playbook: `<path>`>
- <Branch guard hook: `.claude/hooks/block-main-git.ps1` (and `.cursor/...` if you use Cursor)>
