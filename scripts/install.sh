#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR=".claude-agents"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_SLUG_ARG="${1:-}"
REF_ARG="${2:-}"
DEFAULT_REPO_SLUG="${REPO_SLUG_ARG:-${AI_AGENT_CONFIG_REPO:-enact-on/ai-agent-config}}"
DEFAULT_REF="${REF_ARG:-${AI_AGENT_CONFIG_REF:-main}}"
RAW_BASE_URL="https://raw.githubusercontent.com/${DEFAULT_REPO_SLUG}/${DEFAULT_REF}"

SOURCE_MODE="remote"
SOURCE_ROOT=""

if [[ -d "${REPO_ROOT}/agents" && -d "${REPO_ROOT}/workflows" ]]; then
  SOURCE_MODE="local"
  SOURCE_ROOT="${REPO_ROOT}"
fi

if [[ "${SOURCE_MODE}" == "remote" && "${DEFAULT_REPO_SLUG}" == "your-org/ai-agent-config" ]]; then
  cat <<'EOF'
install.sh is still pointing at the placeholder repository slug: your-org/ai-agent-config

Use one of these options:
  1. Set AI_AGENT_CONFIG_REPO to your published repo, for example:
     AI_AGENT_CONFIG_REPO=my-org/ai-agent-config ./install.sh
  2. Pass the repo slug directly:
     ./install.sh my-org/ai-agent-config
  3. Run the installer from a local clone or submodule of ai-agent-config.
EOF
  exit 1
fi

fetch_to_file() {
  local source_path="$1"
  local destination="$2"

  mkdir -p "$(dirname "${destination}")"

  if [[ "${SOURCE_MODE}" == "local" ]]; then
    cp "${SOURCE_ROOT}/${source_path}" "${destination}"
    return
  fi

  if command -v curl >/dev/null 2>&1; then
    if ! curl -fsSL "${RAW_BASE_URL}/${source_path}" -o "${destination}"; then
      echo "Failed to download ${source_path} from ${RAW_BASE_URL}"
      echo "Check that AI_AGENT_CONFIG_REPO and AI_AGENT_CONFIG_REF point to a real public repository and ref."
      exit 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    if ! wget -qO "${destination}" "${RAW_BASE_URL}/${source_path}"; then
      echo "Failed to download ${source_path} from ${RAW_BASE_URL}"
      echo "Check that AI_AGENT_CONFIG_REPO and AI_AGENT_CONFIG_REF point to a real public repository and ref."
      exit 1
    fi
  else
    echo "curl or wget is required to fetch ai-agent-config"
    exit 1
  fi
}

copy_agent_dir() {
  local source_dir="$1"
  local target_dir="${INSTALL_DIR}/agents/${source_dir}"

  mkdir -p "${target_dir}"

  if [[ "${SOURCE_MODE}" == "local" ]]; then
    find "${SOURCE_ROOT}/agents/${source_dir}" -maxdepth 1 -type f -name '*.md' -print0 | while IFS= read -r -d '' file; do
      cp "${file}" "${target_dir}/$(basename "${file}")"
    done
    return
  fi

  case "${source_dir}" in
    common)
      fetch_to_file "agents/common/team-lead-orchestrator.md" "${target_dir}/team-lead-orchestrator.md"
      fetch_to_file "agents/common/code-implementer.md" "${target_dir}/code-implementer.md"
      fetch_to_file "agents/common/code-reviewer.md" "${target_dir}/code-reviewer.md"
      fetch_to_file "agents/common/security-auditor.md" "${target_dir}/security-auditor.md"
      ;;
    laravel)
      fetch_to_file "agents/laravel/laravel-fullstack-dev.md" "${target_dir}/laravel-fullstack-dev.md"
      fetch_to_file "agents/laravel/laravel-backend-architect.md" "${target_dir}/laravel-backend-architect.md"
      ;;
    nextjs)
      fetch_to_file "agents/nextjs/nextjs-fullstack-dev.md" "${target_dir}/nextjs-fullstack-dev.md"
      fetch_to_file "agents/nextjs/nodejs-backend-dev.md" "${target_dir}/nodejs-backend-dev.md"
      ;;
    mobile)
      fetch_to_file "agents/mobile/react-native-dev.md" "${target_dir}/react-native-dev.md"
      fetch_to_file "agents/mobile/expo-dev.md" "${target_dir}/expo-dev.md"
      ;;
  esac
}

mkdir -p "${INSTALL_DIR}/agents" "${INSTALL_DIR}/config" ".github/workflows"

if [[ "${SOURCE_MODE}" == "local" ]]; then
  mapfile -t detected_stacks < <("${SOURCE_ROOT}/scripts/detect-stack.sh")
else
  tmp_detect="$(mktemp)"
  fetch_to_file "scripts/detect-stack.sh" "${tmp_detect}"
  chmod +x "${tmp_detect}"
  mapfile -t detected_stacks < <("${tmp_detect}")
  rm -f "${tmp_detect}"
fi

copy_agent_dir "common"

mobile_needed=0
for stack in "${detected_stacks[@]}"; do
  case "${stack}" in
    laravel)
      copy_agent_dir "laravel"
      ;;
    nextjs)
      copy_agent_dir "nextjs"
      ;;
    reactnative|expo)
      mobile_needed=1
      ;;
  esac
done

if [[ "${mobile_needed}" -eq 1 ]]; then
  copy_agent_dir "mobile"
fi

printf '%s\n' "${detected_stacks[@]}" > "${INSTALL_DIR}/config/stacks.txt"

cat > "${INSTALL_DIR}/config/install-source.env" <<EOF
AI_AGENT_SOURCE_MODE=${SOURCE_MODE}
AI_AGENT_CONFIG_REPO=${DEFAULT_REPO_SLUG}
AI_AGENT_CONFIG_REF=${DEFAULT_REF}
EOF

if [[ "${SOURCE_MODE}" == "local" ]]; then
  cat >> "${INSTALL_DIR}/config/install-source.env" <<EOF
AI_AGENT_SOURCE_ROOT=${SOURCE_ROOT}
EOF
fi

for workflow in claude-comment-assistant.yml claude-assignment-router.yml security-audit.yml; do
  if [[ ! -f ".github/workflows/${workflow}" ]]; then
    fetch_to_file "workflows/${workflow}" ".github/workflows/${workflow}"
  fi
done

fetch_to_file "scripts/update.sh" "update-ai-agents.sh"
fetch_to_file "scripts/update.ps1" "update-ai-agents.ps1"
chmod +x "update-ai-agents.sh"

echo "Installed ai-agent-config into ${INSTALL_DIR}"
echo "Detected stacks:"
printf ' - %s\n' "${detected_stacks[@]}"
