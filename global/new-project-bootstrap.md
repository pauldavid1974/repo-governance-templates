<!-- CANONICAL "new project" bootstrap instruction.
     This same block is installed into each agent's GLOBAL (user-level) config so that any
     agent, in any folder, governs a new project automatically before writing code.
     Edit it here, then re-copy to the per-agent locations listed in this folder's README. -->

# Starting a new project — auto-governance bootstrap

**Applies only when BOTH are true:** (a) the user is asking to start or build a **new** project,
and (b) the current folder has **no `AGENTS.md`** file. If `AGENTS.md` already exists, the
project is already governed — just read and follow it; do **not** re-scaffold. Never run this
for questions, or in a folder that is clearly an existing project.

When it applies, do this **before** writing any project code:

1. **Scaffold governance.** Run:

   ```powershell
   pwsh -NoProfile -File "C:\pauls_apps\repo-governance-templates\new-governed-repo.ps1" -Target . -Name "<short project name>"
   ```

   It copies the rule files + hooks and runs `git init` and `lefthook install`. It skips files
   that already exist, so it is safe.

2. **Write the project brief (PRD).** Interview the user — the problem, the goal, target users,
   scope in/out, hard constraints, security/privacy needs, success criteria, risks — and write
   their answers into `PRD.md`. Ask, don't assume.

3. **Fill governance from the brief.** Use the PRD answers to replace the `<PLACEHOLDER>`s in
   `AGENTS.md` and `REPO_RULES.md` (what the project is, the hard constraints, etc.).

4. **First commit, by the rules.** Branch first (never `main`); commit `.gitignore` first, then
   the governance files and `PRD.md`, using Conventional Commit messages. Open a PR if there is
   a remote; otherwise stop after committing.

Then proceed with the user's actual task, governed by `AGENTS.md`.
