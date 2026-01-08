#!/bin/bash

###############################################################################
# AI Agent Installation Script
#
# This script installs AI agents into a repository by:
# 1. Detecting the project's tech stack
# 2. Creating the .claude-agents directory structure
# 3. Downloading relevant agent configurations
# 4. Setting up GitHub workflows (non-destructive)
#
# Usage: curl -sSL https://raw.githubusercontent.com/enact-on/ai-agent-config/main/scripts/install.sh | bash
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_REPO="${CONFIG_REPO:-enact-on/ai-agent-config}"
CONFIG_BRANCH="${CONFIG_BRANCH:-main}"
CONFIG_DIR=".claude-agents"
GITHUB_WORKFLOWS_DIR=".github/workflows"
BASE_URL="https://raw.githubusercontent.com/$CONFIG_REPO/$CONFIG_BRANCH"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "This directory is not a git repository. Please run this script from within a git repository."
        exit 1
    fi
    log_success "Git repository detected"
}

# Detect tech stack
detect_stack() {
    log_info "Detecting project tech stack..."

    STACK=""

    # Check for Laravel
    if [ -f "composer.json" ]; then
        if grep -q '"laravel"' composer.json 2>/dev/null || \
           grep -q '"illuminate' composer.json 2>/dev/null; then
            STACK="$STACK,laravel"
            log_success "Detected: Laravel"
        else
            STACK="$STACK,laravel"
            log_success "Detected: PHP (composer.json found)"
        fi
    fi

    # Check for Next.js
    if [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ]; then
        STACK="$STACK,nextjs"
        log_success "Detected: Next.js"
    fi

    # Check for Node.js (general)
    if [ -f "package.json" ] && [[ ! "$STACK" =~ nextjs ]]; then
        if grep -q '"express"' package.json 2>/dev/null || \
           grep -q '"fastify"' package.json 2>/dev/null || \
           grep -q '"nestjs"' package.json 2>/dev/null; then
            STACK="$STACK,nodejs"
            log_success "Detected: Node.js Backend"
        fi
    fi

    # Check for Expo
    if [ -f "app.json" ] && grep -q "expo" app.json 2>/dev/null; then
        STACK="$STACK,expo"
        log_success "Detected: Expo"
    fi

    # Check for React Native
    if [ -d "android" ] || [ -d "ios" ]; then
        if [[ ! "$STACK" =~ expo ]]; then
            STACK="$STACK,reactnative"
            log_success "Detected: React Native"
        fi
    fi

    # Remove leading comma
    STACK="${STACK#,}"

    if [ -z "$STACK" ]; then
        log_warning "No recognized tech stack detected. Installing common agents only."
        STACK="common"
    else
        log_success "Final tech stack: $STACK"
    fi
}

# Download a single file
download_file() {
    local url="$1"
    local output="$2"

    if command -v curl > /dev/null 2>&1; then
        curl -sSL "$url" -o "$output"
    elif command -v wget > /dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        log_error "Neither curl nor wget is available. Please install one of them."
        return 1
    fi
}

# Create directory structure
create_structure() {
    log_info "Creating directory structure..."

    mkdir -p "$CONFIG_DIR/agents/common"
    mkdir -p "$CONFIG_DIR/agents/laravel"
    mkdir -p "$CONFIG_DIR/agents/nextjs"
    mkdir -p "$CONFIG_DIR/agents/mobile"

    log_success "Created .claude-agents directory"
}

# Download and copy agent configurations
download_agents() {
    local STACK="$1"

    log_info "Downloading agent configurations..."

    # Always download common agents
    log_info "Downloading common agents..."
    download_file "$BASE_URL/agents/common/team-lead-orchestrator.json" "$CONFIG_DIR/agents/common/team-lead-orchestrator.json"
    download_file "$BASE_URL/agents/common/code-implementer.json" "$CONFIG_DIR/agents/common/code-implementer.json"
    download_file "$BASE_URL/agents/common/code-reviewer.json" "$CONFIG_DIR/agents/common/code-reviewer.json"
    download_file "$BASE_URL/agents/common/security-auditor.json" "$CONFIG_DIR/agents/common/security-auditor.json"
    log_success "Downloaded common agents"

    # Download tech-specific agents based on detected stack
    IFS=',' read -ra STACK_ARRAY <<< "$STACK"
    for stack_item in "${STACK_ARRAY[@]}"; do
        stack_item=$(echo "$stack_item" | xargs)  # Trim whitespace

        case "$stack_item" in
            laravel)
                log_info "Downloading Laravel agents..."
                download_file "$BASE_URL/agents/laravel/laravel-fullstack-dev.json" "$CONFIG_DIR/agents/laravel/laravel-fullstack-dev.json"
                download_file "$BASE_URL/agents/laravel/laravel-backend-architect.json" "$CONFIG_DIR/agents/laravel/laravel-backend-architect.json"
                log_success "Downloaded Laravel agents"
                ;;
            nextjs|nodejs)
                log_info "Downloading Next.js/Node.js agents..."
                download_file "$BASE_URL/agents/nextjs/nextjs-fullstack-dev.json" "$CONFIG_DIR/agents/nextjs/nextjs-fullstack-dev.json"
                download_file "$BASE_URL/agents/nextjs/nodejs-backend-dev.json" "$CONFIG_DIR/agents/nextjs/nodejs-backend-dev.json"
                log_success "Downloaded Next.js/Node.js agents"
                ;;
            reactnative|expo)
                log_info "Downloading mobile agents..."
                download_file "$BASE_URL/agents/mobile/react-native-dev.json" "$CONFIG_DIR/agents/mobile/react-native-dev.json"
                download_file "$BASE_URL/agents/mobile/expo-dev.json" "$CONFIG_DIR/agents/mobile/expo-dev.json"
                log_success "Downloaded mobile agents"
                ;;
        esac
    done
}

# Setup GitHub workflows
setup_workflows() {
    log_info "Setting up GitHub workflows..."

    # Create .github/workflows directory if it doesn't exist
    mkdir -p "$GITHUB_WORKFLOWS_DIR"

    # Download AI agent workflow if it doesn't exist
    if [ ! -f "$GITHUB_WORKFLOWS_DIR/ai-agent.yml" ]; then
        download_file "$BASE_URL/workflows/ai-agent.yml" "$GITHUB_WORKFLOWS_DIR/ai-agent.yml"
        log_success "Created ai-agent.yml workflow"
    else
        log_warning "ai-agent.yml already exists, skipping..."
    fi

    # Download security audit workflow if it doesn't exist
    if [ ! -f "$GITHUB_WORKFLOWS_DIR/security-audit.yml" ]; then
        download_file "$BASE_URL/workflows/security-audit.yml" "$GITHUB_WORKFLOWS_DIR/security-audit.yml"
        log_success "Created security-audit.yml workflow"
    else
        log_warning "security-audit.yml already exists, skipping..."
    fi
}

# Create update script
create_update_script() {
    log_info "Creating update script..."

    download_file "$BASE_URL/scripts/update.sh" "update-ai-agents.sh"
    chmod +x update-ai-agents.sh

    log_success "Created update-ai-agents.sh script"
}

# Create .gitignore entry
create_gitignore() {
    log_info "Updating .gitignore..."

    if [ ! -f ".gitignore" ]; then
        touch .gitignore
    fi

    if ! grep -q "^# AI Agent Config" .gitignore; then
        cat >> .gitignore <<'EOF'

# AI Agent Config (managed centrally)
EOF
        log_success "Updated .gitignore"
    else
        log_info ".gitignore already configured"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   AI Agent Installation Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "📁 Configuration directory: $CONFIG_DIR"
    echo "🔧 GitHub workflows: $GITHUB_WORKFLOWS_DIR"
    echo ""
    echo "📋 Installed Agents:"
    find "$CONFIG_DIR/agents" -name "*.json" -exec basename {} \; 2>/dev/null | sed 's/.json$//' | nl
    echo ""
    echo "🚀 Next Steps:"
    echo ""
    echo "1. Configure GitHub Secrets:"
    echo "   - CUSTOM_ANTHROPIC_BASE_URL"
    echo "   - CUSTOM_ANTHROPIC_TOKEN"
    echo ""
    echo "2. Create bot account (if not exists):"
    echo "   - Username: super-ai-agent"
    echo "   - Grant read access to this repository"
    echo ""
    echo "3. To update agents in the future, run:"
    echo "   ./update-ai-agents.sh"
    echo ""
    echo "4. Assign an issue to @super-ai-agent to trigger AI implementation"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
}

# Main execution
main() {
    echo ""
    echo -e "${BLUE}AI Agent Installation Script${NC}"
    echo "=================================="
    echo ""

    check_git_repo
    detect_stack
    create_structure
    download_agents "$STACK"
    setup_workflows
    create_update_script
    create_gitignore

    print_summary
}

# Run main function
main
