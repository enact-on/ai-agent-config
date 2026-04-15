#!/usr/bin/env bash

set -euo pipefail

if [[ ! -f ".claude-agents/config/install-source.env" ]]; then
  echo "Missing .claude-agents/config/install-source.env. Run install.sh first."
  exit 1
fi

# shellcheck disable=SC1091
source ".claude-agents/config/install-source.env"

if [[ "${AI_AGENT_SOURCE_MODE:-}" == "local" && -n "${AI_AGENT_SOURCE_ROOT:-}" ]]; then
  bash "${AI_AGENT_SOURCE_ROOT}/scripts/install.sh"
  exit 0
fi

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "https://raw.githubusercontent.com/${AI_AGENT_CONFIG_REPO}/${AI_AGENT_CONFIG_REF}/scripts/install.sh" | bash
  exit 0
fi

if command -v wget >/dev/null 2>&1; then
  wget -qO- "https://raw.githubusercontent.com/${AI_AGENT_CONFIG_REPO}/${AI_AGENT_CONFIG_REF}/scripts/install.sh" | bash
  exit 0
fi

echo "curl or wget is required to update ai-agent-config"
exit 1
