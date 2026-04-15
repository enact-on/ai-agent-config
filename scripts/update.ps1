$ErrorActionPreference = "Stop"

$SourceEnv = ".claude-agents/config/install-source.env"
if (-not (Test-Path $SourceEnv)) {
  throw "Missing .claude-agents/config/install-source.env. Run install.ps1 first."
}

$Values = @{}
Get-Content $SourceEnv | ForEach-Object {
  if ($_ -match "^(.*?)=(.*)$") {
    $Values[$matches[1]] = $matches[2]
  }
}

if ($Values["AI_AGENT_SOURCE_MODE"] -eq "local" -and $Values["AI_AGENT_SOURCE_ROOT"]) {
  powershell -ExecutionPolicy Bypass -File (Join-Path $Values["AI_AGENT_SOURCE_ROOT"] "scripts/install.ps1")
  exit 0
}

$Repo = $Values["AI_AGENT_CONFIG_REPO"]
$Ref = $Values["AI_AGENT_CONFIG_REF"]
iwr "https://raw.githubusercontent.com/$Repo/$Ref/scripts/install.ps1" -UseBasicParsing | iex
