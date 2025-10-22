# EC-CUBE Dev Agents

EC-CUBE/Symfony development toolkit with specialized AI agents, Gemini integration, GitHub automation, and Slack notifications. Optimized for EC-CUBE/Symfony but applicable to any development project.

## Features

### 🤖 Specialized AI Agents

- **implementation-analyzer** - Analyzes implementation status by examining specs, PRs, commits, and staged changes
- **bug-investigator** - Investigates bugs with detailed error log analysis and systematic debugging
- **log-analyzer** - Analyzes GitHub Actions CI/CD logs to identify root causes of test failures
- **refactoring-expert** - Improves code quality, identifies DRY violations, and applies best practices

### ⚡ Custom Commands

- **gemini-search** - Web search using Google Gemini CLI
- **github-check** - View PR/Issue details with automatic number extraction
- **github-logs-analyze** - Analyze failed GitHub Actions jobs
- **generate-commit** - Generate commit messages from git diff
- **update-pr-description** - Auto-update PR descriptions based on changes

### 🔔 Slack Notifications

Automatic notifications to Slack:
- Task completion notifications (Stop hook)
- Task confirmation notifications (Notification hook)
- AI-summarized conversation content in Japanese with mrkdwn formatting

## Prerequisites

- **Gemini CLI** - The `gemini` command must be available in your PATH
- **GitHub CLI (gh)** - For GitHub integration commands
- **jq** - JSON processor for hook commands
- **curl** - For Slack webhook integration

## Installation

### 1. Set up environment variables

For Slack notifications to work, set your Slack webhook URL:

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

Add this to your `~/.bashrc` or `~/.zshrc` to make it persistent.

### 2. Install via local marketplace

Create a local marketplace:

```bash
mkdir -p ~/claude-plugins-marketplace
cd ~/claude-plugins-marketplace
```

Clone or copy this plugin:

```bash
# If using git
git clone https://github.com/nanasess/eccube-dev-agents.git

# Or copy from your existing location
cp -r ~/.config/claude/plugins/eccube-dev-agents .
```

Create `marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "eccube-dev-agents",
      "source": "./eccube-dev-agents"
    }
  ]
}
```

Add marketplace to Claude Code:

```bash
claude plugin marketplace add ~/claude-plugins-marketplace
```

Install the plugin:

```bash
claude plugin install eccube-dev-agents
```

Restart Claude Code to activate the plugin.

## Usage

### Using Agents

```bash
# Analyze implementation status
"Use implementation-analyzer agent to analyze the current implementation"

# Investigate bugs
"Use bug-investigator agent to find the root cause of this error"

# Analyze CI logs
"Use log-analyzer agent to analyze this failed GitHub Actions run"

# Refactor code
"Use refactoring-expert agent to refactor this code"
```

### Using Commands

```bash
# Web search
/gemini-search latest EC-CUBE 4.2 features

# Check GitHub PR
/github-check #450

# Analyze failed CI
/github-logs-analyze <job-id>

# Generate commit message
/generate-commit

# Update PR description
/update-pr-description
```

## Configuration

### Customizing Hooks

Edit `hooks/hooks.json` to customize notification behavior:

- Modify the Gemini prompt for different summarization styles
- Change the Slack message format
- Add additional hooks for other events

### Gemini CLI Setup

Ensure the `gemini` command is available in your PATH. If it's installed in a custom location, you can:
- Add it to your PATH: `export PATH="$PATH:/path/to/gemini"`
- Or create a symlink: `ln -s /path/to/gemini/bin/gemini /usr/local/bin/gemini`

## Structure

```
eccube-dev-agents/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── agents/                   # AI agent definitions
│   ├── implementation-analyzer.md
│   ├── bug-investigator.md
│   ├── log-analyzer.md
│   └── refactoring-expert.md
├── commands/                 # Custom slash commands
│   ├── gemini-search.md
│   ├── github-check.md
│   ├── github-logs-analyze.md
│   ├── generate-commit.md
│   └── update-pr-description.md
├── hooks/
│   └── hooks.json           # Event hooks configuration
└── README.md
```

## Contributing

Issues and pull requests are welcome! Please feel free to contribute improvements.

## License

MIT

## Author

nanasess
