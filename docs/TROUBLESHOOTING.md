# Troubleshooting Guide

Solutions to common issues with Cost Guardian.

## Installation Issues

### "Plugin not found" Error

**Symptom:** `/plugin install cost-guardian` returns error

**Solutions:**
1. Check marketplace is added:
   ```bash
   /plugin marketplace list
   ```
2. Add marketplace if missing:
   ```bash
   /plugin marketplace add cost-guardian/cost-guardian
   ```
3. Try direct GitHub install:
   ```bash
   /plugin install https://github.com/your-username/cost-guardian
   ```

### "Permission denied" on Scripts

**Symptom:** Hooks don't execute, permission errors in logs

**Solution:**
```bash
# Find plugin directory
/plugin list
# Note the path

# Make scripts executable
chmod +x /path/to/cost-guardian/scripts/core/*.sh
chmod +x /path/to/cost-guardian/scripts/utils/*.sh
```

### Missing Dependencies (jq, bc)

**Symptom:** Hooks fail with "command not found"

**Solution:**

macOS:
```bash
brew install jq bc
```

Ubuntu/Debian:
```bash
sudo apt-get install jq bc
```

Fedora/RHEL:
```bash
sudo dnf install jq bc
```

## Runtime Issues

### Commands Not Working

**Symptom:** `/cost` or `/budget` returns "command not found"

**Solutions:**
1. Verify plugin is installed:
   ```bash
   /plugin list
   ```
2. Restart Claude Code session
3. Reinstall plugin:
   ```bash
   /plugin remove cost-guardian
   /plugin install cost-guardian
   ```

### Costs Not Tracking

**Symptom:** `/cost` shows $0 even after operations

**Possible causes:**

1. **Session not initialized**
   - Start a new Claude Code session
   - Check if `~/.claude/cost-guardian/sessions/` exists

2. **Hooks not firing**
   - Check `hooks/hooks.json` exists in plugin directory
   - Verify hook scripts are executable
   - Look for errors in Claude Code output

3. **Data directory missing**
   ```bash
   mkdir -p ~/.claude/cost-guardian/sessions
   ```

### Budget Not Enforcing

**Symptom:** Warnings/blocks don't appear when over budget

**Solutions:**

1. **Check budget is set:**
   ```bash
   /budget
   ```

2. **Verify enforcement mode:**
   ```bash
   /budget set 10 --enforcement confirm
   ```

3. **Check PreToolUse hook:**
   - Must be in `hooks/hooks.json`
   - Script must be executable

### Wrong Cost Calculations

**Symptom:** Costs seem too high or too low

**Possible causes:**

1. **Model detection issue**
   - Cost Guardian may not detect your current model
   - Default assumes Sonnet pricing

2. **Outdated pricing data**
   - Check `data/pricing.json` has current rates
   - Update from Anthropic's pricing page

3. **Token estimation variance**
   - Estimates are ~10% accurate
   - Actual API usage may differ

## Data Issues

### "JSON parse error"

**Symptom:** Commands fail with JSON errors

**Solution:**
```bash
# Check for corrupted files
cat ~/.claude/cost-guardian/sessions/current.json | jq .

# If corrupted, remove and restart session
rm ~/.claude/cost-guardian/sessions/current.json
```

### Session Data Not Persisting

**Symptom:** Cost data lost between commands

**Solutions:**

1. **Check directory permissions:**
   ```bash
   ls -la ~/.claude/cost-guardian/
   ```

2. **Verify symlink:**
   ```bash
   ls -la ~/.claude/cost-guardian/sessions/current.json
   ```

3. **Check disk space:**
   ```bash
   df -h ~
   ```

### Historical Data Missing

**Symptom:** `/cost-report --period week` shows no data

**Solution:**
```bash
# Check history file exists
cat ~/.claude/cost-guardian/history.json

# If missing, historical data starts from now
```

## Performance Issues

### Slow Hook Execution

**Symptom:** Operations feel sluggish

**Possible causes:**

1. **Large session file**
   - Session files grow with operations
   - Start new session to reset

2. **Slow disk**
   - Cost Guardian writes to disk frequently
   - Consider SSD if using HDD

3. **Complex calculations**
   - Very large files cause slow estimation
   - This is expected behavior

### High Memory Usage

**Symptom:** Claude Code using more memory than usual

**Solutions:**
1. Session files shouldn't cause this
2. Check if issue persists without plugin:
   ```bash
   /plugin remove cost-guardian
   # Test without plugin
   /plugin install cost-guardian
   ```

## Hook-Specific Issues

### SessionStart Not Firing

**Symptoms:**
- No session file created
- `/cost` shows "no active session"

**Debug:**
```bash
# Test manually
echo '{"session_id":"test","cwd":"/tmp"}' | \
  bash /path/to/cost-guardian/scripts/core/init-session.sh
```

### PreToolUse Not Warning

**Symptoms:**
- No cost warnings before operations
- Budget enforcement not working

**Debug:**
```bash
# Test manually
echo '{"session_id":"test","tool_name":"Read","tool_input":{"file_path":"test.txt"}}' | \
  bash /path/to/cost-guardian/scripts/core/pre-tool-check.sh
```

### PostToolUse Not Tracking

**Symptoms:**
- Operations not logged
- Totals not updating

**Debug:**
```bash
# Test manually
echo '{"session_id":"test","tool_name":"Read","tool_result":"content"}' | \
  bash /path/to/cost-guardian/scripts/core/post-tool-track.sh
```

## Common Error Messages

### "Budget file not found"

**Cause:** First time running, no budget set yet

**Solution:**
```bash
/budget set 10
```

### "Session file corrupted"

**Cause:** Interrupted write, disk issue

**Solution:**
```bash
rm ~/.claude/cost-guardian/sessions/current.json
# Start new session
```

### "Unable to calculate cost"

**Cause:** Unknown model or missing pricing data

**Solution:**
1. Check `data/pricing.json` has your model
2. Add missing model pricing if needed

### "Hook timeout"

**Cause:** Script taking >3 seconds

**Solutions:**
1. Check for slow operations in script
2. Ensure no network calls in hooks
3. Check disk performance

## Getting Help

### Gather Debug Info

Before reporting an issue, collect:

```bash
# Claude Code version
claude --version

# Plugin version
cat /path/to/cost-guardian/.claude-plugin/plugin.json | jq .version

# OS info
uname -a

# Shell version
bash --version

# Dependencies
jq --version
bc --version

# Plugin files
ls -la /path/to/cost-guardian/

# Data files
ls -la ~/.claude/cost-guardian/

# Recent errors (if any)
# Check Claude Code output for error messages
```

### Report an Issue

1. Go to [GitHub Issues](https://github.com/your-username/cost-guardian/issues)
2. Click "New Issue"
3. Include:
   - Debug info from above
   - Steps to reproduce
   - Expected vs actual behavior
   - Any error messages

### Community Help

- **Discussions:** [GitHub Discussions](https://github.com/your-username/cost-guardian/discussions)
- **Discord:** [Join server](https://discord.gg/cost-guardian)

## Reset Everything

If all else fails, complete reset:

```bash
# Remove plugin
/plugin remove cost-guardian

# Remove data
rm -rf ~/.claude/cost-guardian

# Reinstall
/plugin install cost-guardian

# Set up fresh
/budget set 10
```
