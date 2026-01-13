# CLAUDE.md - Cost Guardian Development Context

This file provides context for Claude Code when working on the Cost Guardian plugin.

## Project Overview

Cost Guardian is a Claude Code plugin that provides real-time budget enforcement and cost tracking using native hooks. It's the first plugin to use `PreToolUse` hooks for proactive cost warnings.

## Architecture

```
cost-guardian/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest (required)
├── commands/                  # Slash commands
│   ├── budget.md             # /budget - Budget management
│   ├── cost.md               # /cost - Current costs
│   ├── cost-report.md        # /cost-report - Analytics
│   ├── cost-optimize.md      # /cost-optimize - Suggestions
│   └── cost-share.md         # /cost-share - Export/badges
├── hooks/
│   └── hooks.json            # Hook configuration
├── scripts/
│   ├── core/                 # Main hook scripts
│   │   ├── init-session.sh   # SessionStart handler
│   │   ├── pre-tool-check.sh # PreToolUse handler (key innovation)
│   │   ├── post-tool-track.sh # PostToolUse handler
│   │   └── end-session.sh    # SessionEnd handler
│   └── utils/
│       ├── pricing.sh        # Pricing calculations
│       └── storage.sh        # JSON data operations
├── data/
│   └── pricing.json          # Model pricing cache
├── templates/
│   ├── report.html           # Shareable HTML report
│   └── badge.svg             # Efficiency badge template
├── CLAUDE.md                 # This file
└── README.md                 # User documentation
```

## Key Technical Details

### Hook System

Hooks receive JSON via stdin and output JSON to stdout:

**Input format (PreToolUse):**
```json
{
  "session_id": "abc123",
  "hook_event_name": "PreToolUse",
  "tool_name": "Read",
  "tool_input": {"file_path": "/path/to/file"},
  "cwd": "/current/dir",
  "transcript_path": "/path/to/transcript"
}
```

**Output format (to block/warn):**
```json
{
  "hookSpecificOutput": {
    "permissionDecision": "deny"  // or "ask"
  },
  "systemMessage": "Warning message shown to user"
}
```

### Environment Variables

Available in hook scripts:
- `$CLAUDE_PLUGIN_ROOT` - Plugin installation directory
- `$CLAUDE_PROJECT_DIR` - Current project directory
- `$CLAUDE_ENV_FILE` - Path to write env vars (SessionStart only)

### Data Storage

All data stored in `~/.claude/cost-guardian/`:

**Session file structure:**
```json
{
  "session_id": "abc123",
  "started_at": "2025-01-12T10:30:00Z",
  "model": "claude-sonnet-4",
  "costs": {
    "total": 3.47,
    "input_tokens": 89234,
    "output_tokens": 12456
  },
  "operations": [...],
  "budget": {"session": {"limit": 10, "enforcement": "warn"}}
}
```

### Pricing (January 2025)

| Model | Input/1M | Output/1M |
|-------|----------|-----------|
| opus-4-5 | $5.00 | $25.00 |
| sonnet-4 | $3.00 | $15.00 |
| haiku-4-5 | $1.00 | $5.00 |

Tool overheads: Bash +245 tokens, Edit/Write +700 tokens

## Development Guidelines

### Adding a New Command

1. Create `commands/command-name.md`
2. Add YAML frontmatter with description and allowed-tools
3. Write prompt that reads from data files and outputs formatted response

### Modifying Hooks

1. Edit hook script in `scripts/core/`
2. Test with: `echo '{"tool_name":"Read",...}' | bash scripts/core/pre-tool-check.sh`
3. Hooks must complete in <3 seconds

### Cost Estimation Algorithm

Token estimation heuristics:
- Text: ~4 characters per token
- Code: ~3 characters per token (denser)
- JSON: ~3 characters per token

### Testing

```bash
# Test session initialization
echo '{"session_id":"test123","cwd":"/tmp"}' | bash scripts/core/init-session.sh

# Test cost tracking
echo '{"tool_name":"Read","tool_input":{"file_path":"README.md"}}' | bash scripts/core/pre-tool-check.sh
```

## Common Tasks

### Update Pricing
Edit `data/pricing.json` with new rates from Anthropic.

### Add New Alert Threshold
Modify `scripts/core/post-tool-track.sh` alert checking logic.

### Change Default Enforcement
Update `scripts/core/init-session.sh` default budget config.

## Dependencies

- `jq` - JSON processing (required)
- `bc` - Decimal math (required)
- Bash 4.0+ (for associative arrays)

## Code Style

- Shell scripts: Use `set -euo pipefail`
- JSON: Pretty-print for storage, compact for output
- Comments: Explain "why", not "what"
- Error handling: Always check file existence before reading

## Known Limitations

1. Token counts are estimates (actual comes from API)
2. Cache hit/miss rates cannot be directly measured
3. Model detection relies on environment variable
4. Concurrent sessions may have race conditions on shared files
