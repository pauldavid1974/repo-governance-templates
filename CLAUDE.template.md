# Operating rules — <PROJECT_NAME>

> **How to use this template:** Copy it to your new repo's root as `CLAUDE.md`. Replace every
> `<PLACEHOLDER>` and delete what doesn't apply. Claude Code reads this file at the start of
> every session — it's the single source of truth for how to work here. The full rationale
> lives in `REPO_RULES.md`. Keep this file short: a bloated `CLAUDE.md` gets ignored.

This file is your standing instructions. Read it as rules, not background.

## What this project is

<One or two lines: what it does and its intended shape — e.g. "a single Python CLI under
`src/`", "a small Electron app", "a library, stdlib only".>

## How to run it

- Install: `<command>`
- Run: `<command>`
- Test: `<command>`
- Lint / format: `<command>`

> Only list commands you can't guess. If there's nothing non-obvious, say so.

## Git is automatic — you own it, don't ask

Handle the entire git workflow yourself, without asking the user about any of it. Permissions
for these commands are pre-granted in `.claude/settings.json`, so you are never prompted.

1. **Branch first, always.** Before changing anything, `git switch -c <type>/<short-desc>`
   (`feat/`, `fix/`, `docs/`, `chore/`, `refactor/`). A hook blocks commits/pushes on `main`,
   so this isn't optional.
2. **Commit as you go.** After each logical change, stage and commit with a
   [Conventional Commits](https://www.conventionalcommits.org) message
   (`feat`/`fix`/`docs`/`chore`/`refactor`/`test`/`perf`); imperative subject ≤ 72 chars; body
   explains *why*. One logical change per commit.
3. **Push the branch.** Push to the remote as you commit (first push sets upstream).
4. **Open a PR when the work is done and verified.** Use `gh pr create` with a description of
   what changed, why, and how it was tested.
5. **Stop there. Do NOT merge into `main`** — landing on `main` is the one deliberate step left
   to a human. Don't ask about it; just leave the PR open.
6. **No remote?** Branch and commit locally; skip push and PR.

A Stop hook auto-commits and pushes any leftover changes when a turn ends, as a safety net so
work is never lost — but commit deliberately with good messages rather than relying on it.

## Plan before you code

- For anything beyond a one-line edit, write a short plan first — which files change, what's
  out of scope, how you'll prove it works — and confirm the approach before implementing.
- For a real feature, copy `SPEC.template.md` to `SPEC.md` and fill it in; the spec is the
  thing to agree on, not the code. Keep it updated as decisions change.
- Without an explicit plan and scope, you'll fill the gaps with guesses and build the wrong
  thing. Track multi-step work with a task list (in-progress → done).

## While working

- One logical change per branch/PR. A fix and a refactor are two branches.
- Match the existing style and comment density. Don't reformat untouched code.
- Pin dependencies and justify any new one in the PR. Respect the hard constraints in
  `REPO_RULES.md`: <one-line reminder — e.g. "local-only, no telemetry, pinned deps">.
- Never put a secret (key, token, password) in code, config, or a commit message. The secret
  scanner blocks commits that contain one — fix the cause, don't route around it.

## Before ending a turn

- **Prove it works.** Show evidence, not just a claim of success: the test output, the command
  you ran and what it returned, or a screenshot. If you can't verify it, it isn't done.
- **Update `WORKLOG.md`.** Append a dated entry: what changed, which branch, what's next, any
  open decisions. This is the project's memory between sessions — unwritten means lost.

## Guardrails (enforced automatically)

`.claude/settings.json` wires up hooks that don't depend on you remembering the rules:
- Commit/push on `main` is blocked (`.claude/hooks/block-main-git.ps1`).
- Edits to protected files are blocked (`.claude/hooks/protect-paths.ps1`).
- Leftover work is auto-committed/pushed at end of turn (`.claude/hooks/auto-commit.ps1`).
- The secret scan (`lefthook.yml` + `.gitleaks.toml`) blocks commits containing credentials.

Don't disable or work around a guardrail to get unblocked — fix the underlying cause.

## Quick reference

- Full rules: `REPO_RULES.md`
- Plan/spec template: `SPEC.md`
- Running log: `WORKLOG.md`
- <Design doc / debug playbook: `<path>`>
