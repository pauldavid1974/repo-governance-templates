# Global agent setup (auto-governance for new projects)

These instructions make **any** agent govern a new project automatically: you open an empty
folder, state your task, and the agent scaffolds governance + writes the PRD before coding.

The instruction lives once in [`new-project-bootstrap.md`](new-project-bootstrap.md) and is
installed into each agent's **global (user-level) config**. Three of the four are plain files
you can write; Cursor's is set in its UI.

| Agent | Where the global instruction goes | How |
|-------|-----------------------------------|-----|
| Claude Code | `C:\Users\<you>\.claude\CLAUDE.md` | Append the bootstrap block. |
| Codex | `C:\Users\<you>\.codex\AGENTS.md` | Create the file with the bootstrap block. |
| Antigravity | `C:\Users\<you>\.gemini\GEMINI.md` | Create the file with the bootstrap block. (Also used by Gemini CLI.) |
| Cursor | Settings → Rules → **User Rules** | Paste the bootstrap block (Cursor stores user rules in-app, not as a file). |

## Notes

- **It activates only after `new-governed-repo.ps1` exists at the path it references** —
  i.e. once this template branch is merged into `main` at
  `C:\pauls_apps\repo-governance-templates`.
- **Safe by design:** the block only fires for a *new* project in a folder with no `AGENTS.md`,
  and the scaffold script skips files that already exist. Existing projects are untouched.
- **Permissions:** the first scaffold in a project may ask the agent's permission to run the
  script — that's the secure default. To make it promptless in Claude Code, add an allow rule
  for the script to `C:\Users\<you>\.claude\settings.json`.
- To change the instruction, edit `new-project-bootstrap.md` here and re-copy to the locations
  above.
