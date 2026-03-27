#Requires -Version 5.1
<#
.SYNOPSIS
  MASH — Multi-Agent Software Harness installer (Windows / PowerShell)
.DESCRIPTION
  Install:  iex (irm 'https://raw.githubusercontent.com/dmarchevsky/mash/main/install.ps1')
  Flags:    -Force      skip version check
            -Claude     install Claude Code support only
            -OpenCode   install opencode support only
#>
param(
  [switch]$Force,
  [switch]$Claude,
  [switch]$OpenCode
)

$ErrorActionPreference = 'Stop'

$MASH_ZIP     = 'https://github.com/dmarchevsky/mash/archive/refs/heads/main.zip'
$MARKER_START = '<!-- MASH -->'
$MARKER_END   = '<!-- /MASH -->'

$TargetDir    = $PWD.Path
$FlagClaude   = $Claude.IsPresent
$FlagOpenCode = $OpenCode.IsPresent

# --- Helpers ---

function Write-Info { param($msg) Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-Ok   { param($msg) Write-Host "  v  $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  !  $msg" -ForegroundColor Yellow }

function Die {
  param($msg)
  Write-Host "  x  $msg" -ForegroundColor Red
  exit 1
}

# --- Step 1: Validate ---

Write-Host "`nMASH Installer`n" -ForegroundColor White

if (-not (Test-Path (Join-Path $TargetDir '.git'))) {
  Die "Not a git repo: $TargetDir"
}

# --- Step 2: Download ---

$TmpDir  = Join-Path ([System.IO.Path]::GetTempPath()) "mash-$(([System.Guid]::NewGuid()).ToString('N'))"
$ZipPath = Join-Path $TmpDir 'mash.zip'
New-Item -ItemType Directory -Path $TmpDir | Out-Null

try {
  Write-Info "Downloading MASH framework..."
  Invoke-WebRequest -Uri $MASH_ZIP -OutFile $ZipPath -UseBasicParsing
  Expand-Archive -Path $ZipPath -DestinationPath $TmpDir
  $MashSrc = Join-Path $TmpDir 'mash-main'
  if (-not (Test-Path $MashSrc)) {
    Die "Unexpected archive structure. Expected 'mash-main' folder."
  }
} catch {
  Die "Failed to download MASH. Check your internet connection. $_"
}

# --- Step 3: Version check ---

$NewVersion = 'unknown'
$VersionFile = Join-Path $MashSrc 'VERSION'
if (Test-Path $VersionFile) {
  $NewVersion = (Get-Content $VersionFile -Raw).Trim()
}

$InstalledVersion = ''
$InstalledVersionFile = Join-Path $TargetDir 'skills' 'mash' 'VERSION'
if (Test-Path $InstalledVersionFile) {
  $InstalledVersion = (Get-Content $InstalledVersionFile -Raw).Trim()
}

if ($InstalledVersion) {
  if ($InstalledVersion -eq $NewVersion -and -not $Force) {
    Write-Ok "Already up to date (v$NewVersion)"
    Write-Host ''
    Remove-Item $TmpDir -Recurse -Force
    exit 0
  }
  if ($InstalledVersion -ne $NewVersion) {
    Write-Info "Updating from v$InstalledVersion to v$NewVersion"
    $InstalledMinor = $InstalledVersion -replace '\.\d+$', ''
    $NewMinor       = $NewVersion -replace '\.\d+$', ''
    $MigrationsDir  = Join-Path $MashSrc 'migrations'
    if ($InstalledMinor -ne $NewMinor -and (Test-Path $MigrationsDir)) {
      Get-ChildItem $MigrationsDir -Filter '*.md' | ForEach-Object {
        Write-Warn "Migration notes available: $($_.Name)"
      }
    }
  }
} else {
  Write-Info "Installing MASH v$NewVersion"
}

# --- Step 3b: Detect AI clients ---

$HasClaude   = $null -ne (Get-Command 'claude'   -ErrorAction SilentlyContinue)
$HasOpenCode = $null -ne (Get-Command 'opencode' -ErrorAction SilentlyContinue)

$InstallClaude   = $false
$InstallOpenCode = $false

if ($FlagClaude -or $FlagOpenCode) {
  $InstallClaude   = $FlagClaude
  $InstallOpenCode = $FlagOpenCode
} elseif ($HasClaude -and -not $HasOpenCode) {
  $InstallClaude = $true
} elseif (-not $HasClaude -and $HasOpenCode) {
  $InstallOpenCode = $true
} elseif ($HasClaude -and $HasOpenCode) {
  Write-Host ''
  Write-Host 'Both Claude Code and opencode are installed. Install MASH for:'
  Write-Host '  1) Claude Code only'
  Write-Host '  2) opencode only'
  Write-Host '  3) Both'
  $choice = Read-Host 'Choice [3]'
  if (-not $choice) { $choice = '3' }
  switch ($choice) {
    '1'     { $InstallClaude = $true }
    '2'     { $InstallOpenCode = $true }
    default { $InstallClaude = $true; $InstallOpenCode = $true }
  }
} else {
  Die "Neither 'claude' nor 'opencode' found in PATH. Install one of them first."
}

# --- Step 4: Copy framework files (always overwrite) ---

Write-Info "Installing framework files..."

$SkillsDest = Join-Path $TargetDir 'skills' 'mash'
New-Item -ItemType Directory -Path $SkillsDest -Force | Out-Null
Get-ChildItem (Join-Path $MashSrc 'skills' 'mash') | ForEach-Object {
  Copy-Item $_.FullName $SkillsDest -Recurse -Force
}
Write-Ok 'skills/mash/'

if ($InstallClaude) {
  $ClaudeCommands = Join-Path $TargetDir '.claude' 'commands'
  New-Item -ItemType Directory -Path $ClaudeCommands -Force | Out-Null
  Copy-Item (Join-Path $MashSrc 'commands' 'mash.md') (Join-Path $ClaudeCommands 'mash.md') -Force
  Write-Ok '.claude/commands/mash.md'
}

if ($InstallOpenCode) {
  $OpenCodeSkills = Join-Path $TargetDir '.opencode' 'skills' 'mash'
  New-Item -ItemType Directory -Path $OpenCodeSkills -Force | Out-Null
  Copy-Item (Join-Path $MashSrc 'opencode-skills' 'mash' 'SKILL.md') (Join-Path $OpenCodeSkills 'SKILL.md') -Force
  Write-Ok '.opencode/skills/mash/SKILL.md'

  $OpenCodeCmds = Join-Path $TargetDir '.opencode' 'commands'
  New-Item -ItemType Directory -Path $OpenCodeCmds -Force | Out-Null
  Copy-Item (Join-Path $MashSrc 'opencode-commands' 'mash.md') (Join-Path $OpenCodeCmds 'mash.md') -Force
  Write-Ok '.opencode/commands/mash.md'

  $OpenCodeJson = Join-Path $TargetDir 'opencode.json'
  if (-not (Test-Path $OpenCodeJson)) {
    Copy-Item (Join-Path $MashSrc 'opencode.json') $OpenCodeJson
    Write-Ok 'opencode.json'
  } else {
    Write-Ok 'opencode.json already exists — skipped'
  }
}

if (Test-Path $VersionFile) {
  Copy-Item $VersionFile (Join-Path $TargetDir 'skills' 'mash' 'VERSION') -Force
  Write-Ok "VERSION (v$NewVersion)"
}

# --- Step 5: Create scaffolding (only if missing) ---

$CreatedScaffolding = $false

foreach ($dir in @('.mash', '.mash/plan', '.mash/plan/features', '.mash/dev', 'src', 'tests')) {
  $full = Join-Path $TargetDir $dir
  if (-not (Test-Path $full)) {
    New-Item -ItemType Directory -Path $full | Out-Null
    Write-Ok "Created $dir/"
    $CreatedScaffolding = $true
  }
}

# Add .gitkeep to empty dirs
foreach ($dir in @('.mash/plan/features', '.mash/dev', 'src', 'tests')) {
  $full = Join-Path $TargetDir $dir
  if (-not (Get-ChildItem $full -Force)) {
    New-Item -ItemType File -Path (Join-Path $full '.gitkeep') | Out-Null
  }
}

if (-not $CreatedScaffolding) {
  Write-Ok 'Scaffolding already exists — skipped'
}

# --- Step 6: CLAUDE.md section (insert or replace) ---

$ClaudeMd = Join-Path $TargetDir 'CLAUDE.md'

$MashSection = @'
<!-- MASH -->
# MASH — Multi-Agent Software Harness

This project uses the MASH framework for planning and implementation.

## Conventions

- **`.mash/plan/`** is the source of truth for all specs, features, and architecture decisions.
- **`src/`** contains application source code.
- **`tests/`** contains test files.
- Feature specs live in `.mash/plan/features/` with YAML frontmatter tracking status.
- Working copies for implementation live in `.mash/dev/`.
- `.mash/plan/progress.md` is the main status tracker.
- The MASH skill (`skills/mash/SKILL.md`) manages planning and delegates implementation to isolated sub-agents via the Agent tool.

## Workflow

1. `mash init` — iteratively define your project (architecture + project).
2. `mash plan` — interactively create features with clarifying questions.
3. `mash dev [feature-ids]` — implement and test features via sub-agents (dev-persona then qa-persona).
4. `mash update` — check for and install framework updates.
5. `mash status` — show current progress.
6. MASH never writes code directly — it spawns sub-agents.
<!-- /MASH -->
'@

if (Test-Path $ClaudeMd) {
  $content = [System.IO.File]::ReadAllText($ClaudeMd)
  if ($content.Contains($MARKER_START)) {
    if ($content.Contains($MARKER_END)) {
      # Replace existing section between markers
      $pattern    = '(?s)' + [regex]::Escape($MARKER_START) + '.*?' + [regex]::Escape($MARKER_END)
      $newContent = [regex]::Replace($content, $pattern, $MashSection.Trim())
      [System.IO.File]::WriteAllText($ClaudeMd, $newContent)
      Write-Ok 'CLAUDE.md MASH section updated'
    } else {
      # Old format without end marker — remove old section and append new
      $idx = $content.IndexOf($MARKER_START)
      $newContent = $content.Substring(0, $idx).TrimEnd() + "`n`n" + $MashSection.Trim() + "`n"
      [System.IO.File]::WriteAllText($ClaudeMd, $newContent)
      Write-Ok 'CLAUDE.md MASH section replaced (migrated to new format)'
    }
  } else {
    [System.IO.File]::AppendAllText($ClaudeMd, "`n" + $MashSection.Trim() + "`n")
    Write-Ok 'Appended MASH section to CLAUDE.md'
  }
} else {
  [System.IO.File]::WriteAllText($ClaudeMd, $MashSection.Trim() + "`n")
  Write-Ok 'Created CLAUDE.md with MASH section'
}

# --- Step 7: .gitignore ---

$Gitignore = Join-Path $TargetDir '.gitignore'
if (-not (Test-Path $Gitignore)) {
  New-Item -ItemType File -Path $Gitignore | Out-Null
}

$gitignoreEntries = @('.mash/dev/', '.mash/worktrees/')
$existing         = @(Get-Content $Gitignore -ErrorAction SilentlyContinue)
$addedEntries     = $false

foreach ($entry in $gitignoreEntries) {
  if ($existing -notcontains $entry) {
    Add-Content $Gitignore $entry
    $addedEntries = $true
  }
}

if ($addedEntries) {
  Write-Ok 'Added MASH entries to .gitignore'
} else {
  Write-Ok '.gitignore already has MASH entries — skipped'
}

# --- Step 8: Done ---

Remove-Item $TmpDir -Recurse -Force

if ($InstalledVersion -and $InstalledVersion -ne $NewVersion) {
  Write-Host "`nMASH updated to v$NewVersion." -ForegroundColor Green
  Write-Host ''
} else {
  Write-Host "`nMASH v$NewVersion installed successfully." -ForegroundColor Green
  if ($InstallClaude -and $InstallOpenCode) {
    Write-Host 'Run /mash init in Claude Code or ask MASH to initialize your project in opencode.'
  } elseif ($InstallOpenCode) {
    Write-Host 'Ask MASH to initialize your project in opencode (e.g. "mash init").'
  } else {
    Write-Host 'Run /mash init in Claude Code to get started.'
  }
  Write-Host ''
}
