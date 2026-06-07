# Reusable Repo Governance Templates

Drop-in files that give any new project clean git hygiene from day one —
branch-first workflow, Conventional Commits, PR-only merges, secrets discipline, and a
hook that physically blocks commits on `main`.

## What's in here

| File | Goes where (in the new repo) | Purpose |
|------|------------------------------|---------|
| `CLAUDE.template.md` | `CLAUDE.md` (repo root) | Short always-on rules Claude loads every session |
| `REPO_RULES.template.md` | `REPO_RULES.md` (repo root) | Full rationale: branching, commits, PRs, secrets, `.gitignore` |
| `block-main-git.template.ps1` | `.claude/hooks/block-main-git.ps1` | Hook that denies `git commit`/`git push` on `main` |
| `block-main-git.settings-snippet.json` | merge into `.claude/settings.json` | Wires the hook up |

## How to set up a new project (5 steps)

1. Copy `CLAUDE.template.md` → `CLAUDE.md` and `REPO_RULES.template.md` → `REPO_RULES.md`
   at the new repo's root. Fill in every `<PLACEHOLDER>`, delete sections you don't need.
2. Copy `block-main-git.template.ps1` → `.claude/hooks/block-main-git.ps1`.
3. Merge `block-main-git.settings-snippet.json` into `.claude/settings.json` (create it if
   absent). If you also use Cursor, copy the hook to `.cursor/hooks/` too.
4. Commit `.gitignore` **first** (the starter is in `REPO_RULES.md §2`), then everything else.
5. Tell me "set up this repo using my templates" in the new project and I'll do steps 1–4
   for you and tailor the placeholders to whatever we're building.

## Notes

- The hook is PowerShell (Windows). On macOS/Linux the same logic works as a small bash
  script — ask me to convert it if you move platforms.
- These are *templates*, not live config — editing them here never affects an existing repo.
  Each project gets its own filled-in copy.
