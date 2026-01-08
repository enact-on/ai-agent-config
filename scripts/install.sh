#!/bin/bash

###############################################################################
# AI Agent Installation Script
#
# This script installs AI agents into a repository by:
# 1. Detecting the project's tech stack
# 2. Creating the .claude-agents directory structure
# 3. Copying relevant agent configurations
# 4. Setting up GitHub workflows (non-destructive)
#
# Usage: curl -sSL https://raw.githubusercontent.com/company/ai-agent-config/main/scripts/install.sh | bash
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

# Download config from central repository
download_configs() {
    log_info "Downloading agent configurations..."

    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Download from GitHub
    log_info "Fetching from: https://github.com/$CONFIG_REPO/archive/$CONFIG_BRANCH.tar.gz"

    if command -v curl > /dev/null 2>&1; then
        curl -sSL "https://github.com/$CONFIG_REPO/archive/$CONFIG_BRANCH.tar.gz" | tar -xz -C "$TEMP_DIR"
    elif command -v wget > /dev/null 2>&1; then
        wget -qO- "https://github.com/$CONFIG_REPO/archive/$CONFIG_BRANCH.tar.gz" | tar -xz -C "$TEMP_DIR"
    else
        log_error "Neither curl nor wget is available. Please install one of them."
        exit 1
    fi

    EXTRACTED_DIR="$TEMP_DIR/ai-agent-config-$CONFIG_BRANCH"

    if [ ! -d "$EXTRACTED_DIR" ]; then
        log_error "Failed to download configuration repository"
        exit 1
    fi

    echo "$EXTRACTED_DIR"
}

# Create directory structure
create_structure() {
    log_info "Creating directory structure..."

    mkdir -p "$CONFIG_DIR/agents"

    log_success "Created .claude-agents directory"
}

# Copy agent configurations
copy_agents() {
    local EXTRACTED_DIR="$1"
    local STACK="$2"

    log_info "Copying agent configurations..."

    # Always copy common agents
    if [ -d "$EXTRACTED_DIR/agents/common" ]; then
        cp -r "$EXTRACTED_DIR/agents/common" "$CONFIG_DIR/agents/"
        log_success "Copied common agents"
    fi

    # Copy tech-specific agents based on detected stack
    IFS=',' read -ra STACK_ARRAY <<< "$STACK"
    for stack_item in "${STACK_ARRAY[@]}"; do
        stack_item=$(echo "$stack_item" | xargs)  # Trim whitespace

        case "$stack_item" in
            laravel)
                if [ -d "$EXTRACTED_DIR/agents/laravel" ]; then
                    cp -r "$EXTRACTED_DIR/agents/laravel" "$CONFIG_DIR/agents/"
                    log_success "Copied Laravel agents"
                fi
                ;;
            nextjs|nodejs)
                if [ -d "$EXTRACTED_DIR/agents/nextjs" ]; then
                    cp -r "$EXTRACTED_DIR/agents/nextjs" "$CONFIG_DIR/agents/"
                    log_success "Copied Next.js/Node.js agents"
                fi
                ;;
            reactnative|expo)
                if [ -d "$EXTRACTED_DIR/agents/mobile" ]; then
                    cp -r "$EXTRACTED_DIR/agents/mobile" "$CONFIG_DIR/agents/"
                    log_success "Copied mobile agents"
                fi
                ;;
        esac
    done
}

# Setup GitHub workflows
setup_workflows() {
    local EXTRACTED_DIR="$1"

    log_info "Setting up GitHub workflows..."

    # Create .github/workflows directory if it doesn't exist
    mkdir -p "$GITHUB_WORKFLOWS_DIR"

    # Copy AI agent workflow if it doesn't exist
    if [ ! -f "$GITHUB_WORKFLOWS_DIR/ai-agent.yml" ]; then
        if [ -f "$EXTRACTED_DIR/workflows/ai-agent.yml" ]; then
            cp "$EXTRACTED_DIR/workflows/ai-agent.yml" "$GITHUB_WORKFLOWS_DIR/"
            log_success "Created ai-agent.yml workflow"
        fi
    else
        log_warning "ai-agent.yml already exists, skipping..."
    fi

    # Copy security audit workflow if it doesn't exist
    if [ ! -f "$GITHUB_WORKFLOWS_DIR/security-audit.yml" ]; then
        if [ -f "$EXTRACTED_DIR/workflows/security-audit.yml" ]; then
            cp "$EXTRACTED_DIR/workflows/security-audit.yml" "$GITHUB_WORKFLOWS_DIR/"
            log_success "Created security-audit.yml workflow"
        fi
    else
        log_warning "security-audit.yml already exists, skipping..."
    fi
}

# Create update script
create_update_script() {
    log_info "Creating update script..."

    cat > update-ai-agents.sh << 'EOF'
#!/bin/bash

###############################################################################
# AI Agent Update Script
#
# This script updates AI agents from the central repository.
#
# Usage: ./update-ai-agents.sh
###############################################################################

set -e

CONFIG_REPO="${CONFIG_REPO:-company/ai-agent-config}"
CONFIG_BRANCH="${CONFIG_BRANCH:-main}"
CONFIG_DIR=".claude-agents"
GITHUB_WORKFLOWS_DIR=".github/workflows"

echo "Updating AI agents from central repository..."

# Detect current stack
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if [ -f "scripts/detect-stack.sh" ]; then
    STACK=$(bash scripts/detect-stack.sh)
else
    STACK=""
    # Auto-detect
    [ -f "composer.json" ] && STACK="$STACK,laravel"
    [ -f "next.config.js" ] && STACK="$STACK,nextjs"
    [ -d "android" ] && STACK="$STACK,reactnative"
    [ -f "app.json" ] && grep -q "expo" app.json 2>/dev/null && STACK="$STACK,expo"
    STACK="${STACK#,}"
fi

echo "Detected stack: $STACK"

# Download latest configs
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Downloading from https://github.com/$CONFIG_REPO/archive/$CONFIG_BRANCH.tar.gz..."

if command -v curl > /dev/null 2>&1; then
    curl -sSL "https://github.com/$CONFIG_REPO/archive/$CONFIG_BRANCH.tar.gz" | tar -xz -C "$TEMP_DIR"
elif command -v wget > /dev/null 2>&1; then
    wget -qO- "https://github.com/$CONFIG_REPO/archive/$CONFIG_BRANCH.tar.gz" | tar -xz -C "$TEMP_DIR"
else
    echo "Error: Neither curl nor wget is available"
    exit 1
fi

EXTRACTED_DIR="$TEMP_DIR/ai-agent-config-$CONFIG_BRANCH"

# Backup existing configs
if [ -d "$CONFIG_DIR" ]; then
    BACKUP_DIR="${CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    cp -r "$CONFIG_DIR" "$BACKUP_DIR"
    echo "Backed up existing configs to: $BACKUP_DIR"
fi

# Update agents
echo "Updating agents..."
rm -rf "$CONFIG_DIR/agents"
mkdir -p "$CONFIG_DIR/agents"

# Copy common agents
if [ -d "$EXTRACTED_DIR/agents/common" ]; then
    cp -r "$EXTRACTED_DIR/agents/common" "$CONFIG_DIR/agents/"
    echo "Updated common agents"
fi

# Copy tech-specific agents
IFS=',' read -ra STACK_ARRAY <<< "$STACK"
for stack_item in "${STACK_ARRAY[@]}"; do
    stack_item=$(echo "$stack_item" | xargs)

    case "$stack_item" in
        laravel)
            [ -d "$EXTRACTED_DIR/agents/laravel" ] && cp -r "$EXTRACTED_DIR/agents/laravel" "$CONFIG_DIR/agents/"
            ;;
        nextjs|nodejs)
            [ -d "$EXTRACTED_DIR/agents/nextjs" ] && cp -r "$EXTRACTED_DIR/agents/nextjs" "$CONFIG_DIR/agents/"
            ;;
        reactnative|expo)
            [ -d "$EXTRACTED_DIR/agents/mobile" ] && cp -r "$EXTRACTED_DIR/agents/mobile" "$CONFIG_DIR/agents/"
            ;;
    esac
done

# Update workflows (only if they don't exist)
mkdir -p "$GITHUB_WORKFLOWS_DIR"
if [ -f "$EXTRACTED_DIR/workflows/ai-agent.yml" ] && [ ! -f "$GITHUB_WORKFLOWS_DIR/ai-agent.yml" ]; then
    cp "$EXTRACTED_DIR/workflows/ai-agent.yml" "$GITHUB_WORKFLOWS_DIR/"
fi
if [ -f "$EXTRACTED_DIR/workflows/security-audit.yml" ] && [ ! -f "$GITHUB_WORKFLOWS_DIR/security-audit.yml" ]; then
    cp "$EXTRACTED_DIR/workflows/security-audit.yml" "$GITHUB_WORKFLOWS_DIR/"
fi

echo "✅ AI agents updated successfully!"
echo ""
echo "Updated agents:"
find "$CONFIG_DIR/agents" -name "*.json" -exec basename {} \; | sed 's/.json$//'
EOF

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
        cat >> .gitignore << 'EOF'

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
    find "$CONFIG_DIR/agents" -name "*.json" -exec basename {} \; | sed 's/.json$//' | nl
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

    EXTRACTED_DIR=$(download_configs)
    create_structure
    copy_agents "$EXTRACTED_DIR" "$STACK"
    setup_workflows "$EXTRACTED_DIR"
    create_update_script
    create_gitignore

    print_summary
}

# Run main function
main
