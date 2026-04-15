# ai-agent-config

`ai-agent-config` is a public starter repository for rolling out Claude-powered agent workflows across many repositories without touching each repo's existing `.claude/` directory.

It installs stack-aware reference agents into `.claude-agents/`, adds non-destructive GitHub Actions workflows, and gives teams a repeatable setup for:

- `@claude` comment-driven review and implementation
- assignment-based issue handling and PR review requests
- scheduled security audits
- shared agent instructions across Laravel, Next.js, Node.js, React Native, and Expo repositories

## What This Repo Installs

The installer creates:

- `.claude-agents/agents/` with common and stack-specific reference markdown files
- `.claude-agents/config/stacks.txt` with detected tech stacks
- `.claude-agents/config/install-source.env` so updates can be re-run consistently
- `.github/workflows/claude-comment-assistant.yml`
- `.github/workflows/claude-assignment-router.yml`
- `.github/workflows/security-audit.yml`
- `update-ai-agents.sh`
- `update-ai-agents.ps1`

The installer does not overwrite an existing `.claude/` directory. All generated content goes into `.claude-agents/`.

## Repository Layout

```text
agents/
  common/
  laravel/
  nextjs/
  mobile/
scripts/
  detect-stack.sh
  install.sh
  install.ps1
  update.sh
  update.ps1
workflows/
  claude-comment-assistant.yml
  claude-assignment-router.yml
  security-audit.yml
```

## Install Into A Target Repository

### Option 1: Add As A Git Submodule

```bash
git submodule add https://github.com/enact-on/ai-agent-config.git tools/ai-agent-config
bash tools/ai-agent-config/scripts/install.sh
```

On Windows PowerShell:

```powershell
git submodule add https://github.com/enact-on/ai-agent-config.git tools/ai-agent-config
powershell -ExecutionPolicy Bypass -File .\tools\ai-agent-config\scripts\install.ps1
```

### Option 2: Fetch The Installer Directly

Direct installer commands for the published public repository:

```bash
curl -fsSL https://raw.githubusercontent.com/enact-on/ai-agent-config/main/scripts/install.sh | bash
```

On Windows PowerShell:

```powershell
iwr https://raw.githubusercontent.com/enact-on/ai-agent-config/main/scripts/install.ps1 -UseBasicParsing | iex
```

If you copied `install.sh` or `install.ps1` into another repository for testing, you must tell it where the public config repo lives. Otherwise it will try to fetch from the placeholder path and return `404`.

Examples:

```bash
AI_AGENT_CONFIG_REPO=enact-on/ai-agent-config ./install.sh
./install.sh enact-on/ai-agent-config
```

```powershell
$env:AI_AGENT_CONFIG_REPO = "enact-on/ai-agent-config"
.\install.ps1
.\install.ps1 -RepoSlug enact-on/ai-agent-config
```

## Required GitHub Setup

There are two parts to the GitHub side:

1. Install Claude on the repository.
2. Add the secrets and variables the workflows expect.

### Claude GitHub App Setup

Anthropic's Claude Code GitHub Actions docs currently say the quickest setup path is to run `/install-github-app` inside Claude Code, or manually install the official Claude GitHub App and add the required workflow/secrets.

Recommended setup:

1. Open Claude Code locally and run `/install-github-app`.
2. If you prefer manual setup, install the official GitHub App from `https://github.com/apps/claude`.
3. Grant repository access with at least:
   - Contents: Read and write
   - Issues: Read and write
   - Pull requests: Read and write
4. Enable GitHub Actions in the target repository.

If you want assignment-based automation with your own GitHub App identity instead of the official Claude app, create/install your own app and store:

- `APP_ID`
- `APP_PRIVATE_KEY`

Then set the repository variable:

- `AI_AGENT_BOT_LOGIN`

Example value:

```text
super-ai-agent[bot]
```

## Required Secrets

Add these repository or organization secrets before enabling the workflows:

- `ANTHROPIC_API_KEY`: API key for Anthropic or your Anthropic-compatible provider
- `ANTHROPIC_BASE_URL`: base URL for your provider

If you use a custom GitHub App for repository writes:

- `APP_ID`
- `APP_PRIVATE_KEY`

## How The Workflows Behave

### `claude-comment-assistant.yml`

Runs when someone comments `@claude` on:

- an issue
- a pull request conversation
- an inline pull request review thread

The workflow builds a prompt from the markdown files in `.claude-agents/agents/` so Claude sees your shared reviewer, implementer, orchestrator, and stack-specific instructions before responding. The installed agent context is markdown-based, not JSON-based.

### `claude-assignment-router.yml`

Runs on:

- issue assignment
- PR review request

When the assignee or requested reviewer matches `AI_AGENT_BOT_LOGIN`, Claude either:

- implements the assigned issue
- performs a requested PR review

### `security-audit.yml`

Runs weekly and on manual dispatch. It uses the security auditor reference plus stack-specific files to inspect the repository and report findings.

## How To Keep Agent Guidance Current

Update the markdown files in `agents/`. Then target repositories can pull the newest content by running:

```bash
./update-ai-agents.sh
```

Or:

```powershell
.\update-ai-agents.ps1
```

## Notes For Developers

- Keep project-specific coding rules in the target repo's own `CLAUDE.md`.
- Keep shared cross-repo automation guidance in this repository's `agents/` folder.
- The installed workflows are additive. Existing workflows are left untouched.
- The installer only writes workflow files if they are missing.

## Suggested Rollout

1. Publish this repository publicly.
2. Pilot it on 2-3 repositories.
3. Tune the agent markdown files based on real reviews and implementation tasks.
4. Roll it out more broadly with the submodule or install-script flow.
