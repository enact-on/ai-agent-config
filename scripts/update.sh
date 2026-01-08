#!/bin/bash

###############################################################################
# AI Agent Update Script
#
# This script updates AI agents from the central repository.
# It preserves existing configurations while updating agent definitions.
#
# Usage: ./update-ai-agents.sh
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_REPO="${CONFIG_REPO:-company/ai-agent-config}"
CONFIG_BRANCH="${CONFIG_BRANCH:-main}"
CONFIG_DIR=".claude-agents"
GITHUB_WORKFLOWS_DIR=".github/workflows"

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

# Print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Update AI agents from the central configuration repository.

OPTIONS:
    -h, --help              Show this help message
    -r, --repo REPO         Specify config repository (default: company/ai-agent-config)
    -b, --branch BRANCH     Specify branch (default: main)
    --dry-run               Show what would be updated without making changes
    --force                 Force update even if git has uncommitted changes

EXAMPLES:
    ./update-ai-agents.sh
    ./update-ai-agents.sh --repo mycompany/ai-config --branch develop
    ./update-ai-agents.sh --dry-run

EOF
}

# Parse command line arguments
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -r|--repo)
            CONFIG_REPO="$2"
            shift 2
            ;;
        -b|--branch)
            CONFIG_BRANCH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "This directory is not a git repository."
        exit 1
    fi
}

# Check for uncommitted changes
check_git_status() {
    if [ "$FORCE" = false ]; then
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            log_warning "You have uncommitted changes."
            log_warning "Please commit or stash them before updating, or use --force to proceed."
            exit 1
        fi
    fi
}

# Detect tech stack
detect_stack() {
    log_info "Detecting project tech stack..."

    STACK=""

    # Run the detect-stack.sh script if it exists
    if [ -f "scripts/detect-stack.sh" ]; then
        STACK=$(bash scripts/detect-stack.sh)
    else
        # Fallback to inline detection
        if [ -f "composer.json" ]; then
            STACK="$STACK,laravel"
        fi
        if [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ]; then
            STACK="$STACK,nextjs"
        fi
        if [ -f "package.json" ]; then
            if grep -q '"express"' package.json 2>/dev/null || \
               grep -q '"fastify"' package.json 2>/dev/null || \
               grep -q '"nestjs"' package.json 2>/dev/null; then
                STACK="$STACK,nodejs"
            fi
        fi
        if [ -d "android" ] || [ -d "ios" ]; then
            STACK="$STACK,reactnative"
        fi
        if [ -f "app.json" ] && grep -q "expo" app.json 2>/dev/null; then
            STACK="$STACK,expo"
        fi
        STACK="${STACK#,}"
    fi

    log_success "Detected stack: $STACK"
}

# Download latest configs
download_configs() {
    log_info "Downloading from https://github.com/$CONFIG_REPO/archive/$CONFIG_BRANCH.tar.gz..."

    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    if command -v curl > /dev/null 2>&1; then
        curl -sSL "https://github.com/$CONFIG_REPO/archive/$CONFIG_BRANCH.tar.gz" | tar -xz -C "$TEMP_DIR"
    elif command -v wget > /dev/null 2>&1; then
        wget -qO- "https://github.com/$CONFIG_REPO/archive/$CONFIG_BRANCH.tar.gz" | tar -xz -C "$TEMP_DIR"
    else
        log_error "Neither curl nor wget is available."
        exit 1
    fi

    EXTRACTED_DIR="$TEMP_DIR/ai-agent-config-$CONFIG_BRANCH"

    if [ ! -d "$EXTRACTED_DIR" ]; then
        log_error "Failed to download configuration repository."
        exit 1
    fi

    echo "$EXTRACTED_DIR"
}

# Backup existing configurations
backup_configs() {
    if [ -d "$CONFIG_DIR" ]; then
        BACKUP_DIR="${CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up existing configs to: $BACKUP_DIR"

        if [ "$DRY_RUN" = false ]; then
            cp -r "$CONFIG_DIR" "$BACKUP_DIR"
        fi

        log_success "Backup created"
    fi
}

# Update agent configurations
update_agents() {
    local EXTRACTED_DIR="$1"

    log_info "Updating agents..."

    if [ "$DRY_RUN" = true ]; then
        log_warning "[DRY RUN] Would update agents in: $CONFIG_DIR/agents"
        return
    fi

    # Remove old agents
    rm -rf "$CONFIG_DIR/agents"
    mkdir -p "$CONFIG_DIR/agents"

    # Copy common agents
    if [ -d "$EXTRACTED_DIR/agents/common" ]; then
        cp -r "$EXTRACTED_DIR/agents/common" "$CONFIG_DIR/agents/"
        log_success "Updated common agents"
    fi

    # Copy tech-specific agents based on detected stack
    IFS=',' read -ra STACK_ARRAY <<< "$STACK"
    for stack_item in "${STACK_ARRAY[@]}"; do
        stack_item=$(echo "$stack_item" | xargs)  # Trim whitespace

        case "$stack_item" in
            laravel)
                if [ -d "$EXTRACTED_DIR/agents/laravel" ]; then
                    cp -r "$EXTRACTED_DIR/agents/laravel" "$CONFIG_DIR/agents/"
                    log_success "Updated Laravel agents"
                fi
                ;;
            nextjs|nodejs)
                if [ -d "$EXTRACTED_DIR/agents/nextjs" ]; then
                    cp -r "$EXTRACTED_DIR/agents/nextjs" "$CONFIG_DIR/agents/"
                    log_success "Updated Next.js/Node.js agents"
                fi
                ;;
            reactnative|expo)
                if [ -d "$EXTRACTED_DIR/agents/mobile" ]; then
                    cp -r "$EXTRACTED_DIR/agents/mobile" "$CONFIG_DIR/agents/"
                    log_success "Updated mobile agents"
                fi
                ;;
        esac
    done
}

# Update GitHub workflows (if they don't exist)
update_workflows() {
    local EXTRACTED_DIR="$1"

    log_info "Checking GitHub workflows..."

    if [ "$DRY_RUN" = true ]; then
        if [ ! -f "$GITHUB_WORKFLOWS_DIR/ai-agent.yml" ]; then
            log_warning "[DRY RUN] Would create: $GITHUB_WORKFLOWS_DIR/ai-agent.yml"
        fi
        if [ ! -f "$GITHUB_WORKFLOWS_DIR/security-audit.yml" ]; then
            log_warning "[DRY RUN] Would create: $GITHUB_WORKFLOWS_DIR/security-audit.yml"
        fi
        return
    fi

    mkdir -p "$GITHUB_WORKFLOWS_DIR"

    if [ -f "$EXTRACTED_DIR/workflows/ai-agent.yml" ] && [ ! -f "$GITHUB_WORKFLOWS_DIR/ai-agent.yml" ]; then
        cp "$EXTRACTED_DIR/workflows/ai-agent.yml" "$GITHUB_WORKFLOWS_DIR/"
        log_success "Created ai-agent.yml workflow"
    else
        log_info "ai-agent.yml already exists, skipping..."
    fi

    if [ -f "$EXTRACTED_DIR/workflows/security-audit.yml" ] && [ ! -f "$GITHUB_WORKFLOWS_DIR/security-audit.yml" ]; then
        cp "$EXTRACTED_DIR/workflows/security-audit.yml" "$GITHUB_WORKFLOWS_DIR/"
        log_success "Created security-audit.yml workflow"
    else
        log_info "security-audit.yml already exists, skipping..."
    fi
}

# Update the update script itself
update_self() {
    local EXTRACTED_DIR="$1"

    log_info "Checking for update script updates..."

    if [ "$DRY_RUN" = true ]; then
        log_warning "[DRY RUN] Would update update-ai-agents.sh"
        return
    fi

    if [ -f "$EXTRACTED_DIR/scripts/update.sh" ]; then
        cp "$EXTRACTED_DIR/scripts/update.sh" "update-ai-agents.sh"
        log_success "Updated update-ai-agents.sh"
    fi
}

# Show what would be updated
show_diff() {
    local EXTRACTED_DIR="$1"

    echo ""
    echo "Available agents in repository:"
    find "$EXTRACTED_DIR/agents" -name "*.json" -exec basename {} \; | sed 's/.json$//' | sort | uniq

    echo ""
    echo "Currently installed agents:"
    if [ -d "$CONFIG_DIR/agents" ]; then
        find "$CONFIG_DIR/agents" -name "*.json" -exec basename {} \; | sed 's/.json$//' | sort | uniq
    else
        echo "(none)"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   AI Agent Update Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "📁 Configuration directory: $CONFIG_DIR"
    echo "🔧 Tech stack: $STACK"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN] No changes were made.${NC}"
    else
        echo "📋 Installed agents:"
        find "$CONFIG_DIR/agents" -name "*.json" -exec basename {} \; | sed 's/.json$//' | nl
        echo ""
        echo "✨ Agents updated successfully!"
        echo ""
        echo "💡 Tip: Assign an issue to @super-ai-agent to trigger AI implementation"
    fi

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
}

# Main execution
main() {
    echo ""
    echo -e "${BLUE}AI Agent Update Script${NC}"
    echo "========================"
    echo ""

    check_git_repo
    check_git_status
    detect_stack

    EXTRACTED_DIR=$(download_configs)

    if [ "$DRY_RUN" = true ]; then
        show_diff "$EXTRACTED_DIR"
    fi

    backup_configs
    update_agents "$EXTRACTED_DIR"
    update_workflows "$EXTRACTED_DIR"
    update_self "$EXTRACTED_DIR"

    print_summary
}

# Run main function
main
