# Contributing to Cost Guardian

Thank you for your interest in contributing to Cost Guardian! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful, inclusive, and constructive. We're all here to build something useful together.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/your-username/cost-guardian/issues) first
2. Create a new issue with:
   - Clear title describing the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Claude Code version (`claude --version`)
   - OS and shell version

### Suggesting Features

1. Check [existing discussions](https://github.com/your-username/cost-guardian/discussions)
2. Open a new discussion with:
   - Clear description of the feature
   - Use case / problem it solves
   - Proposed implementation (optional)

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly (see Testing section)
5. Commit with clear messages
6. Push and open a PR

## Development Setup

### Prerequisites

- Claude Code v2.0.12+
- Bash 4.0+
- `jq` for JSON processing
- `bc` for decimal calculations

### Local Installation

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/cost-guardian.git
cd cost-guardian

# Install locally for testing
claude
/plugin install .

# Verify installation
/cost
```

### Project Structure

```
cost-guardian/
├── .claude-plugin/plugin.json  # Plugin manifest
├── commands/                    # Slash commands (*.md)
├── hooks/hooks.json            # Hook configuration
├── scripts/
│   ├── core/                   # Main hook handlers
│   └── utils/                  # Shared utilities
├── data/                       # Static data (pricing)
└── templates/                  # Report templates
```

## Testing

### Unit Testing Hook Scripts

```bash
# Test init-session
echo '{"session_id":"test","cwd":"/tmp"}' | bash scripts/core/init-session.sh

# Test pre-tool-check
echo '{"session_id":"test","tool_name":"Read","tool_input":{"file_path":"README.md"}}' | bash scripts/core/pre-tool-check.sh

# Test post-tool-track
echo '{"session_id":"test","tool_name":"Read","tool_result":"content here"}' | bash scripts/core/post-tool-track.sh
```

### Integration Testing

1. Install plugin locally
2. Start a new Claude Code session
3. Set a budget: `/budget set 1`
4. Perform operations and verify tracking
5. Check `/cost` output accuracy
6. Verify alerts trigger at thresholds

### Test Checklist

- [ ] SessionStart creates session file
- [ ] PreToolUse estimates costs correctly
- [ ] PostToolUse updates totals
- [ ] Budget warnings appear at thresholds
- [ ] Budget blocking works in block mode
- [ ] SessionEnd generates summary
- [ ] `/cost` displays accurate data
- [ ] `/cost-report` generates full analytics
- [ ] `/cost-optimize` provides suggestions
- [ ] `/cost-share` exports valid output

## Code Style

### Shell Scripts

```bash
#!/bin/bash
set -euo pipefail

# Always quote variables
file_path="$1"

# Use meaningful variable names
session_cost=$(calculate_cost "$tokens")

# Check file existence before reading
if [[ -f "$config_file" ]]; then
  config=$(cat "$config_file")
fi

# Use functions for reusable logic
calculate_cost() {
  local tokens=$1
  local rate=$2
  echo "scale=6; $tokens * $rate / 1000000" | bc
}
```

### JSON Files

- Use 2-space indentation
- Keep keys lowercase with underscores
- Include comments via separate documentation (JSON doesn't support comments)

### Command Files (Markdown)

```markdown
---
description: Brief command description
argument-hint: [required] [--optional]
allowed-tools: Read, Bash(cat:*), Bash(echo:*)
---

# Command Name

Clear explanation of what the command does.

## Usage

Examples of how to use the command.
```

## Commit Messages

Use conventional commits:

```
feat: Add daily budget support
fix: Correct token estimation for large files
docs: Update README with new commands
refactor: Extract pricing logic to utility
test: Add integration tests for budget enforcement
```

## Pull Request Process

1. **Title**: Clear, descriptive title
2. **Description**:
   - What does this PR do?
   - Why is it needed?
   - How was it tested?
3. **Checklist**:
   - [ ] Tests pass
   - [ ] Documentation updated
   - [ ] CHANGELOG updated (if user-facing)
4. **Review**: Address feedback promptly

## Areas for Contribution

### Good First Issues

- Improve token estimation accuracy
- Add more model pricing data
- Enhance error messages
- Add shell completion support

### Wanted Features

- Team cost aggregation
- Webhook notifications
- Cost forecasting
- VS Code integration
- Alternative shell support (zsh, fish)

### Documentation

- Usage examples
- Troubleshooting guide
- Video tutorials
- Translations

## Release Process

1. Update version in `plugin.json`
2. Update CHANGELOG.md
3. Create GitHub release
4. Tag with semantic version

## Getting Help

- **Discord**: [Join our server](https://discord.gg/cost-guardian)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/cost-guardian/discussions)
- **Issues**: For bugs only

## Recognition

Contributors are recognized in:
- README.md contributors section
- Release notes
- Annual contributor spotlight

Thank you for contributing to Cost Guardian!
