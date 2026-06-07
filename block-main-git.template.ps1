# PreToolUse hook: refuse `git commit` / `git push` while on the `main` branch.
# Enforces REPO_RULES.md "branch before any change". Reads the tool-call JSON on
# stdin, allows everything except a commit/push made from main.
#
# Install: copy to `.claude/hooks/block-main-git.ps1` in your repo, then wire it up
# in `.claude/settings.json` (see block-main-git.settings-snippet.json in this set).

$ErrorActionPreference = 'Stop'

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $payload = $raw | ConvertFrom-Json
} catch {
    # Can't parse input — don't get in the way.
    exit 0
}

$cmd = [string]$payload.tool_input.command
if ([string]::IsNullOrWhiteSpace($cmd)) { exit 0 }

# Is this a git commit or git push? Scan per command segment so chained calls
# like `git add . && git commit` are caught, while `git log` / messages that merely
# contain the word "commit" are not.
$isCommitOrPush = $cmd -match '\bgit\b[^&|;]*\b(commit|push)\b'
if (-not $isCommitOrPush) { exit 0 }

# Resolve the current branch. Prefer the repo the command targets via `-C <path>`,
# else fall back to the hook's working directory.
$repoPath = $null
if ($cmd -match 'git\s+-C\s+"([^"]+)"') { $repoPath = $Matches[1] }
elseif ($cmd -match "git\s+-C\s+'([^']+)'") { $repoPath = $Matches[1] }
elseif ($cmd -match 'git\s+-C\s+(\S+)') { $repoPath = $Matches[1] }

try {
    if ($repoPath) { $branch = (git -C $repoPath rev-parse --abbrev-ref HEAD 2>$null) }
    else { $branch = (git rev-parse --abbrev-ref HEAD 2>$null) }
} catch {
    exit 0  # not a git repo / git unavailable — stay out of the way
}

$branch = ($branch | Out-String).Trim()
if ($branch -ne 'main') { exit 0 }

$reason = @"
Refused: you are on 'main' and REPO_RULES.md requires branching before any commit or push.
Create a branch first, then re-run:
  git switch -c <type>/<short-desc>   # e.g. feat/add-export, fix/null-on-empty-input
Then commit/push on that branch and open a PR.
"@

$out = @{
    hookSpecificOutput = @{
        hookEventName            = 'PreToolUse'
        permissionDecision       = 'deny'
        permissionDecisionReason = $reason
    }
} | ConvertTo-Json -Compress -Depth 5

Write-Output $out
exit 0
