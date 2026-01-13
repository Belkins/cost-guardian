# Installation Guide

Complete guide to installing and configuring Cost Guardian.

## Requirements

- **Claude Code** v2.0.12 or higher
- **Bash** 4.0+ (comes with macOS/Linux)
- **jq** - JSON processor
- **bc** - Calculator for decimal math

### Check Requirements

```bash
# Check Claude Code version
claude --version

# Check bash version
bash --version

# Check jq
jq --version

# Check bc
bc --version
```

### Install Missing Dependencies

**macOS:**
```bash
brew install jq bc
```

**Ubuntu/Debian:**
```bash
sudo apt-get install jq bc
```

**Fedora/RHEL:**
```bash
sudo dnf install jq bc
```

## Installation Methods

### Method 1: From Marketplace (Recommended)

```bash
# Start Claude Code
claude

# Add the marketplace (if not already added)
/plugin marketplace add cost-guardian/cost-guardian

# Install the plugin
/plugin install cost-guardian
```

### Method 2: From GitHub

```bash
# Start Claude Code
claude

# Install directly from GitHub
/plugin install https://github.com/your-username/cost-guardian
```

### Method 3: Local Development

```bash
# Clone the repository
git clone https://github.com/your-username/cost-guardian.git

# Start Claude Code in any project
claude

# Install from local path
/plugin install /path/to/cost-guardian
```

## Verify Installation

After installation, verify it's working:

```bash
# Check plugin is loaded
/plugin list

# Test the cost command
/cost

# You should see:
# Cost Guardian: No active session data
# Use /budget to set spending limits
```

## Initial Configuration

### Set Your First Budget

```bash
# Set a session budget of $10
/budget set 10

# Output:
# Cost Guardian: Budget configured!
#   - Session limit: $10.00
#   - Enforcement: warn (default)
#   - Alerts at: 50%, 80%, 95%
```

### Choose Enforcement Mode

```bash
# Warn only (default) - see warnings but operations continue
/budget set 10 --enforcement warn

# Confirm - require confirmation for expensive operations
/budget set 10 --enforcement confirm

# Block - hard stop when budget exceeded
/budget set 10 --enforcement block
```

### Set Daily/Monthly Budgets

```bash
# Daily budget (resets at midnight local time)
/budget set 50 --scope daily

# Monthly budget (resets on 1st of month)
/budget set 500 --scope monthly
```

## Configuration File

Cost Guardian stores configuration in `~/.claude/cost-guardian/budgets.json`:

```json
{
  "session": {
    "limit": 10.00,
    "enforcement": "warn",
    "alert_thresholds": [50, 80, 95]
  },
  "daily": {
    "limit": 50.00,
    "spent": 0,
    "reset_time": "00:00"
  },
  "monthly": {
    "limit": 500.00,
    "spent": 0,
    "reset_day": 1
  }
}
```

You can edit this file directly, but using `/budget` commands is recommended.

## Updating

### Update to Latest Version

```bash
# Remove current version
/plugin remove cost-guardian

# Reinstall latest
/plugin install cost-guardian
```

### Check for Updates

```bash
/plugin list
# Shows installed version

# Compare with latest on GitHub or marketplace
```

## Uninstalling

```bash
# Remove the plugin
/plugin remove cost-guardian

# Optionally, remove data
rm -rf ~/.claude/cost-guardian
```

## Troubleshooting

### Plugin Not Loading

1. Check Claude Code version: `claude --version`
2. Ensure v2.0.12 or higher
3. Try reinstalling: `/plugin remove cost-guardian && /plugin install cost-guardian`

### Commands Not Found

1. Verify installation: `/plugin list`
2. Check for errors in Claude Code output
3. Restart Claude Code session

### Hooks Not Firing

1. Check `hooks/hooks.json` exists in plugin directory
2. Verify scripts are executable: `chmod +x scripts/core/*.sh`
3. Check script errors: run manually with test input

### Permission Errors

```bash
# Make scripts executable
chmod +x /path/to/cost-guardian/scripts/core/*.sh
chmod +x /path/to/cost-guardian/scripts/utils/*.sh
```

### jq/bc Not Found

Install missing dependencies (see Requirements section above).

## Support

- **Issues**: [GitHub Issues](https://github.com/your-username/cost-guardian/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/cost-guardian/discussions)
