param(
  [string]$RepoSlug = $env:AI_AGENT_CONFIG_REPO,
  [string]$Ref = $env:AI_AGENT_CONFIG_REF
)

$ErrorActionPreference = "Stop"

$InstallDir = ".claude-agents"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$DefaultRepoSlug = if ($RepoSlug) { $RepoSlug } else { "enact-on/ai-agent-config" }
$DefaultRef = if ($Ref) { $Ref } else { "main" }
$RawBaseUrl = "https://raw.githubusercontent.com/$DefaultRepoSlug/$DefaultRef"

$SourceMode = "remote"
$SourceRoot = $null

if ((Test-Path (Join-Path $RepoRoot "agents")) -and (Test-Path (Join-Path $RepoRoot "workflows"))) {
  $SourceMode = "local"
  $SourceRoot = $RepoRoot
}

if ($SourceMode -eq "remote" -and $DefaultRepoSlug -eq "your-org/ai-agent-config") {
  throw @"
install.ps1 is still pointing at the placeholder repository slug: your-org/ai-agent-config

Use one of these options:
  1. `$env:AI_AGENT_CONFIG_REPO = 'my-org/ai-agent-config'; .\install.ps1
  2. .\install.ps1 -RepoSlug my-org/ai-agent-config
  3. Run the installer from a local clone or submodule of ai-agent-config.
"@
}

function Fetch-ToFile {
  param(
    [string]$SourcePath,
    [string]$Destination
  )

  $targetParent = Split-Path -Parent $Destination
  if ($targetParent) {
    New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
  }

  if ($SourceMode -eq "local") {
    Copy-Item -LiteralPath (Join-Path $SourceRoot $SourcePath) -Destination $Destination -Force
    return
  }

  try {
    Invoke-WebRequest -Uri "$RawBaseUrl/$SourcePath" -OutFile $Destination
  } catch {
    throw "Failed to download $SourcePath from $RawBaseUrl. Check that AI_AGENT_CONFIG_REPO and AI_AGENT_CONFIG_REF point to a real public repository and ref."
  }
}

function Copy-AgentDir {
  param([string]$SourceDir)

  $TargetDir = Join-Path $InstallDir "agents\$SourceDir"
  New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

  if ($SourceMode -eq "local") {
    Get-ChildItem -LiteralPath (Join-Path $SourceRoot "agents\$SourceDir") -Filter *.md | ForEach-Object {
      Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $TargetDir $_.Name) -Force
    }
    return
  }

  switch ($SourceDir) {
    "common" {
      Fetch-ToFile "agents/common/team-lead-orchestrator.md" (Join-Path $TargetDir "team-lead-orchestrator.md")
      Fetch-ToFile "agents/common/code-implementer.md" (Join-Path $TargetDir "code-implementer.md")
      Fetch-ToFile "agents/common/code-reviewer.md" (Join-Path $TargetDir "code-reviewer.md")
      Fetch-ToFile "agents/common/security-auditor.md" (Join-Path $TargetDir "security-auditor.md")
    }
    "laravel" {
      Fetch-ToFile "agents/laravel/laravel-fullstack-dev.md" (Join-Path $TargetDir "laravel-fullstack-dev.md")
      Fetch-ToFile "agents/laravel/laravel-backend-architect.md" (Join-Path $TargetDir "laravel-backend-architect.md")
    }
    "nextjs" {
      Fetch-ToFile "agents/nextjs/nextjs-fullstack-dev.md" (Join-Path $TargetDir "nextjs-fullstack-dev.md")
      Fetch-ToFile "agents/nextjs/nodejs-backend-dev.md" (Join-Path $TargetDir "nodejs-backend-dev.md")
    }
    "mobile" {
      Fetch-ToFile "agents/mobile/react-native-dev.md" (Join-Path $TargetDir "react-native-dev.md")
      Fetch-ToFile "agents/mobile/expo-dev.md" (Join-Path $TargetDir "expo-dev.md")
    }
  }
}

function Get-DetectedStacks {
  $stacks = New-Object System.Collections.Generic.List[string]

  if (Test-Path "composer.json") {
    $stacks.Add("laravel")
  }

  if ((Test-Path "next.config.js") -or (Test-Path "next.config.mjs") -or (Test-Path "next.config.ts")) {
    $stacks.Add("nextjs")
  }

  if (Test-Path "package.json") {
    $packageJson = Get-Content "package.json" -Raw
    if ($packageJson -match '"next"') {
      $stacks.Add("nextjs")
    }
  }

  if (Test-Path "app.json") {
    $appJson = Get-Content "app.json" -Raw
    if ($appJson -match '"expo"') {
      $stacks.Add("expo")
    }
  }

  if ((Test-Path "android") -or (Test-Path "ios")) {
    $stacks.Add("reactnative")
  }

  if ($stacks.Count -eq 0) {
    return @("common")
  }

  return $stacks | Select-Object -Unique
}

New-Item -ItemType Directory -Force -Path (Join-Path $InstallDir "agents") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $InstallDir "config") | Out-Null
New-Item -ItemType Directory -Force -Path ".github/workflows" | Out-Null

$DetectedStacks = Get-DetectedStacks

Copy-AgentDir "common"

$MobileNeeded = $false
foreach ($Stack in $DetectedStacks) {
  switch ($Stack) {
    "laravel" { Copy-AgentDir "laravel" }
    "nextjs" { Copy-AgentDir "nextjs" }
    "reactnative" { $MobileNeeded = $true }
    "expo" { $MobileNeeded = $true }
  }
}

if ($MobileNeeded) {
  Copy-AgentDir "mobile"
}

$DetectedStacks | Set-Content -Path (Join-Path $InstallDir "config/stacks.txt")

$InstallSource = @(
  "AI_AGENT_SOURCE_MODE=$SourceMode"
  "AI_AGENT_CONFIG_REPO=$DefaultRepoSlug"
  "AI_AGENT_CONFIG_REF=$DefaultRef"
)

if ($SourceMode -eq "local") {
  $InstallSource += "AI_AGENT_SOURCE_ROOT=$SourceRoot"
}

$InstallSource | Set-Content -Path (Join-Path $InstallDir "config/install-source.env")

@(
  "claude-comment-assistant.yml",
  "claude-assignment-router.yml",
  "security-audit.yml"
) | ForEach-Object {
  $WorkflowPath = ".github/workflows/$_"
  if (-not (Test-Path $WorkflowPath)) {
    Fetch-ToFile "workflows/$_" $WorkflowPath
  }
}

Fetch-ToFile "scripts/update.sh" "update-ai-agents.sh"
Fetch-ToFile "scripts/update.ps1" "update-ai-agents.ps1"

Write-Host "Installed ai-agent-config into $InstallDir"
Write-Host "Detected stacks:"
$DetectedStacks | ForEach-Object { Write-Host " - $_" }
