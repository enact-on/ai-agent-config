# AI Agent Configuration Repository

> Centralized AI agent configurations for automated development assistance across 100+ repositories.

## Overview

This repository contains AI agent definitions, workflows, and installation scripts for deploying Claude Code AI agents across multiple GitHub repositories. Teams can assign issues or PRs to `@super-ai-agent` to trigger automated code review, implementation, and security analysis.

## Features

- **Automated AI Agents**: Specialized agents for different tech stacks and tasks
- **Simple Installation**: One-command setup with automatic tech stack detection
- **Tech Stack Specific**: Agents tailored for Laravel, Next.js, Node.js, React Native, and Expo
- **Security Audits**: Automated weekly security vulnerability scanning
- **Scalable**: Manages 100+ repositories from a single configuration source
- **Easy Updates**: Single command to update all agents across all repositories

## Architecture

### Agent Hierarchy

```
Orchestration Layer
└── team-lead-orchestrator (planning, delegation)

Technology-Specific Agents
├── Laravel: laravel-fullstack-dev, laravel-backend-architect
├── Next.js/Node: nextjs-fullstack-dev, nodejs-backend-dev
└── Mobile: react-native-dev, expo-dev

Role-Based Agents
├── code-implementer (executes implementations)
├── code-reviewer (reviews PRs)
└── security-auditor (security analysis)
```

## Quick Start

### 1. Install in Your Repository

```bash
# From your repository root
curl -sSL https://raw.githubusercontent.com/company/ai-agent-config/main/scripts/install.sh | bash
```

The installer will:
- Detect your tech stack automatically
- Create `.claude-agents` directory with relevant agents
- Set up GitHub workflows
- Create an update script for future updates

### 2. Configure GitHub Secrets

Add the following secrets to your repository (Settings → Secrets and variables → Actions):

- `CUSTOM_ANTHROPIC_BASE_URL`: Your custom Anthropic API endpoint
- `CUSTOM_ANTHROPIC_TOKEN`: Your authentication token

### 3. Create Bot Account (Optional)

1. Create a GitHub bot account: `super-ai-agent`
2. Grant it read access to your repositories
3. Use this account as the assignee for AI-triggered tasks

### 4. Use the AI Agents

**For Implementation:**
1. Create a GitHub issue describing the task
2. Assign the issue to `@super-ai-agent`
3. The AI will analyze, plan, and create a PR with the implementation

**For Code Review:**
1. Create a pull request
2. Request review from `@super-ai-agent`
3. The AI will analyze the changes and provide review comments

## Repository Structure

```
ai-agent-config/
├── agents/
│   ├── common/                    # Universal agents
│   │   ├── team-lead-orchestrator.json
│   │   ├── code-implementer.json
│   │   ├── code-reviewer.json
│   │   └── security-auditor.json
│   ├── laravel/                   # Laravel-specific agents
│   │   ├── laravel-fullstack-dev.json
│   │   └── laravel-backend-architect.json
│   ├── nextjs/                    # Next.js/Node.js agents
│   │   ├── nextjs-fullstack-dev.json
│   │   └── nodejs-backend-dev.json
│   └── mobile/                    # Mobile development agents
│       ├── react-native-dev.json
│       └── expo-dev.json
├── workflows/
│   ├── ai-agent.yml               # Main AI workflow
│   └── security-audit.yml         # Weekly security audit
├── scripts/
│   ├── install.sh                 # Installation script
│   ├── detect-stack.sh            # Tech stack detection
│   └── update.sh                  # Update script
└── README.md
```

## Available Agents

### Common Agents

| Agent | Description | Triggers |
|-------|-------------|----------|
| `team-lead-orchestrator` | Analyzes requirements, creates plans, delegates to specialists | plan, architect, design, complex |
| `code-implementer` | Executes implementation tasks with clean, functional code | implement, add feature, fix bug |
| `code-reviewer` | Reviews PRs for quality and best practices | review, code review, quality check |
| `security-auditor` | Performs security analysis and vulnerability detection | security, audit, vulnerability |

### Technology-Specific Agents

| Agent | Tech Stack | Specialization |
|-------|-----------|----------------|
| `laravel-fullstack-dev` | Laravel/PHP | Full-stack Laravel development |
| `laravel-backend-architect` | Laravel/PHP | Backend architecture and design |
| `nextjs-fullstack-dev` | Next.js/React | Modern web development |
| `nodejs-backend-dev` | Node.js | Backend API development |
| `react-native-dev` | React Native | Cross-platform mobile apps |
| `expo-dev` | Expo | Rapid mobile development |

## Usage Examples

### Example 1: Feature Implementation

```bash
# Create GitHub issue
gh issue create \
  --title "Add user authentication with OAuth2" \
  --body "Implement OAuth2 login with Google and GitHub providers" \
  --assignee "super-ai-agent"
```

The AI will:
1. Analyze the requirement
2. Create an implementation plan
3. Detect the tech stack
4. Delegate to appropriate specialist agents
5. Create a PR with the implementation

### Example 2: Code Review

```bash
# Create PR and request review
gh pr create \
  --title "Refactor user service" \
  --body "Improved the user service architecture" \
  --reviewer "super-ai-agent"
```

The AI will:
1. Review all changed files
2. Check for bugs and code quality issues
3. Verify best practices
4. Provide constructive feedback

### Example 3: Security Audit

Security audits run automatically every Sunday at midnight UTC. You can also trigger manually:

```bash
# Via GitHub CLI
gh workflow run security-audit.yml

# Or via GitHub web interface
# Actions → Security Audit → Run workflow
```

## Updating Agents

When the central configuration repository is updated:

```bash
# From your repository root
./update-ai-agents.sh

# Or specify custom repo/branch
./update-ai-agents.sh --repo company/ai-agent-config --branch develop

# Dry run to see what would change
./update-ai-agents.sh --dry-run
```

## GitHub Workflows

### AI Agent Workflow (`.github/workflows/ai-agent.yml`)

**Triggers:**
- Issue assigned to `@super-ai-agent`
- PR review requested from `@super-ai-agent`

**Behavior:**
- Detects project tech stack
- Selects appropriate AI agents
- Executes the task
- Creates PR or review comments
- Posts status updates

### Security Audit Workflow (`.github/workflows/security-audit.yml`)

**Triggers:**
- Weekly schedule (Sundays at midnight UTC)
- Manual dispatch

**Behavior:**
- Runs dependency vulnerability scans
- Performs secret detection
- Executes AI security analysis
- Creates issue with findings

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `ANTHROPIC_BASE_URL` | Custom API endpoint | Yes |
| `ANTHROPIC_AUTH_TOKEN` | Authentication token | Yes |
| `CLAUDE_CODE_CONFIG_DIR` | Agent config directory | No (default: `.claude-agents`) |

### Agent Selection

Claude Code automatically selects agents based on:
1. Keywords in agent `description` field
2. Issue/PR content analysis
3. Codebase context
4. Explicit mention of agent name

### Tech Stack Detection

The installer automatically detects:
- **Laravel**: `composer.json` with Laravel dependencies
- **Next.js**: `next.config.js` or `next.config.mjs` or `next.config.ts`
- **Node.js**: `package.json` with Express/Fastify/NestJS
- **Expo**: `app.json` with Expo configuration
- **React Native**: `android/` or `ios/` directories

## Customization

### Adding Custom Agents

Create a new agent file in the appropriate directory:

```json
{
  "name": "my-custom-agent",
  "description": "Triggers on keywords: custom, specialized",
  "instructions": "Detailed behavior and capabilities...",
  "tools": ["Read", "Write", "Edit", "Bash"],
  "model": "inherit"
}
```

### Modifying Workflows

Workflows are never overwritten during updates. You can safely customize:
- Timeout values
- Permissions
- Additional steps
- Conditional logic

### Tech Stack Extension

To add support for a new tech stack:

1. Create agent files in `agents/<stack>/`
2. Update `scripts/detect-stack.sh`
3. Update `scripts/install.sh` to copy the new agents
4. Update documentation

## Best Practices

### For Developers

1. **Be Specific in Issues**: Provide detailed requirements for better AI understanding
2. **Use Keywords**: Include relevant keywords (e.g., "implement", "review", "security") to trigger appropriate agents
3. **Review AI Output**: Always review AI-generated code before merging
4. **Provide Context**: Include relevant context about the codebase in issues

### For Repository Maintainers

1. **Keep Config Updated**: Run `./update-ai-agents.sh` regularly
2. **Monitor Workflows**: Check GitHub Actions for failed runs
3. **Review Security Reports**: Address security audit findings promptly
4. **Customize Agents**: Adjust agent behaviors for your team's coding standards

### For Admin Team

1. **Version Control**: Tag releases of the config repository (e.g., `v1.0.0`)
2. **Test Changes**: Test config updates on pilot repositories first
3. **Document Changes**: Maintain a changelog for agent updates
4. **Monitor Usage**: Track how agents are being used across repositories

## Troubleshooting

### Installation Fails

```bash
# Check if curl/wget is installed
which curl wget

# Manually download and run
curl -O https://raw.githubusercontent.com/company/ai-agent-config/main/scripts/install.sh
bash install.sh
```

### Agents Not Triggering

1. Verify GitHub secrets are configured
2. Check GitHub Actions logs for errors
3. Ensure bot account has repository access
4. Verify issue/PR is assigned to `@super-ai-agent`

### Wrong Agents Selected

1. Check agent `description` keywords
2. Be more specific in issue/PR descriptions
3. Explicitly mention the desired agent name
4. Update tech stack detection if needed

### Workflow Permissions Error

Add these permissions to your workflow:
```yaml
permissions:
  contents: write
  pull-requests: write
  issues: write
  id-token: write
  actions: read
```

## Security Considerations

- **Secrets Management**: Never commit API keys or tokens
- **Access Control**: Limit bot account permissions to read-only
- **Code Review**: Always review AI-generated code before merging
- **Audit Logs**: Review GitHub Actions logs regularly
- **Dependency Updates**: Keep dependencies updated for security patches

## Contributing

To contribute to this configuration repository:

1. Fork the repository
2. Create a feature branch
3. Add or modify agent configurations
4. Test on pilot repositories
5. Submit a pull request

## License

MIT License

## Support

For issues or questions:
- GitHub Issues: https://github.com/enact-on/ai-agent-config/issues
- Documentation: https://github.com/enact-on/ai-agent-config

## Changelog

### v1.0.0 (2024-01-15)
- Initial release
- Common agents: orchestrator, implementer, reviewer, auditor
- Laravel agents: fullstack, architect
- Next.js/Node agents: fullstack, backend
- Mobile agents: React Native, Expo
- Installation and update scripts
- GitHub workflows for automation

---

Made with love by the development team

Automating development assistance across all repositories.
