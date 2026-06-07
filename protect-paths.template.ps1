# PreToolUse hook: block edits/writes to protected files and folders.
# Stops an agent from touching files that should only change deliberately
# (lockfiles, generated code, CI config, this hook itself, etc.).
#
# Install: copy to `.claude/hooks/protect-paths.ps1`, then wire it up in
# `.claude/settings.json` (see claude-settings.snippet.json in this template set).
# Edit the $protected list below for your project.

$ErrorActionPreference = 'Stop'

# Glob-ish patterns (regex) for paths that must not be edited by the agent.
$protected = @(
    '(^|[\\/])\.git[\\/]',
    '(^|[\\/])\.github[\\/]workflows[\\/]',
    '(^|[\\/])\.claude[\\/]hooks[\\/]',
    'package-lock\.json$',
    'pnpm-lock\.yaml$',
    'poetry\.lock$',
    'lefthook\.yml$',
    '\.gitleaks\.toml$'
)

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $payload = $raw | ConvertFrom-Json
} catch {
    exit 0  # can't parse — stay out of the way
}

# Only guard tools that write files.
$tool = [string]$payload.tool_name
if ($tool -notin @('Edit', 'Write', 'NotebookEdit', 'MultiEdit')) { exit 0 }

$path = [string]$payload.tool_input.file_path
if ([string]::IsNullOrWhiteSpace($path)) { exit 0 }

foreach ($pattern in $protected) {
    if ($path -match $pattern) {
        $reason = @"
Refused: '$path' is a protected path (matches '$pattern').
These files change only by deliberate human decision, not automatically.
If this edit is genuinely intended, make it yourself or update the protected
list in .claude/hooks/protect-paths.ps1 first.
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
    }
}

exit 0
