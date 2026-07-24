# Increments meeting_count.txt, commits the change, and pushes it to GitHub.
# Designed to be run from an iPhone Shortcut using "Run Script over SSH".

[CmdletBinding()]
param(
    # Lets you test the increment without creating a commit or pushing it.
    [switch]$NoPush
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$countFile = Join-Path $repo 'meeting_count.txt'
$lockFile = Join-Path $repo '.meeting-count.lock'

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    & git -C $repo @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed (exit code $LASTEXITCODE)."
    }
}

# Prevent two shortcut activations on this computer from using the same value.
try {
    New-Item -Path $lockFile -ItemType File -ErrorAction Stop | Out-Null
} catch {
    throw 'A meeting-counter update is already running. Wait a moment and try again.'
}

try {
    if (-not (Test-Path -LiteralPath $countFile)) {
        throw "Counter file not found: $countFile"
    }

    # Do not accidentally commit unrelated work when the shortcut runs unattended.
    $changes = @(git -C $repo status --porcelain --untracked-files=no)
    if ($LASTEXITCODE -ne 0) { throw 'Could not read the Git status.' }
    if ($changes.Count -gt 0) {
        throw "Repository has uncommitted changes. Commit or stash them before running the shortcut.`n$($changes -join "`n")"
    }

    $branch = (git -C $repo branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
        throw 'Could not determine the current Git branch.'
    }

    # Update first, so a change made from another machine is never overwritten.
    Invoke-Git pull --ff-only origin $branch

    $raw = (Get-Content -LiteralPath $countFile -Raw).Trim()
    if ($raw -notmatch '^\d+$') {
        throw "Counter must contain only a non-negative whole number; found '$raw'."
    }

    $current = [Int64]::Parse($raw, [Globalization.CultureInfo]::InvariantCulture)
    if ($current -eq [Int64]::MaxValue) { throw 'Counter has reached its maximum value.' }

    # Keep the existing zero padding (for example, 015 becomes 016).
    $next = ($current + 1).ToString("D$($raw.Length)", [Globalization.CultureInfo]::InvariantCulture)
    [System.IO.File]::WriteAllText($countFile, $next, [System.Text.ASCIIEncoding]::new())

    if ($NoPush) {
        Write-Output "Counter updated locally: $raw -> $next (not committed or pushed)."
        exit 0
    }

    Invoke-Git add -- meeting_count.txt
    Invoke-Git commit -m "Increment meeting counter to $next"
    Invoke-Git push origin $branch
    Write-Output "Meeting counter updated and pushed: $raw -> $next"
}
finally {
    Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
}
