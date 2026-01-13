# How Cost Guardian Works

Technical deep-dive into Cost Guardian's architecture and implementation.

## Overview

Cost Guardian uses Claude Code's native hook system to intercept operations at key points in the workflow. This allows for:

1. **Proactive warnings** - Know costs before operations execute
2. **Real-time tracking** - Accurate cost totals as you work
3. **Budget enforcement** - Block or warn when limits are exceeded

## Hook System

Claude Code provides several hook events. Cost Guardian uses four:

```
SessionStart → Initialize tracking
PreToolUse   → Estimate cost, warn/block
PostToolUse  → Track actual usage
SessionEnd   → Generate summary
```

### Hook Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        SESSION LIFECYCLE                          │
└──────────────────────────────────────────────────────────────────┘

User starts Claude Code session
              │
              ▼
┌─────────────────────────────┐
│      SessionStart Hook      │
│  ─────────────────────────  │
│  • Create session file      │
│  • Load budget config       │
│  • Initialize counters      │
│  • Check daily/monthly      │
└─────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     OPERATION LOOP                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                          │    │
│  │   User requests operation (Read, Edit, Bash, etc.)      │    │
│  │                         │                                │    │
│  │                         ▼                                │    │
│  │   ┌─────────────────────────────────────┐               │    │
│  │   │        PreToolUse Hook              │               │    │
│  │   │  ─────────────────────────────────  │               │    │
│  │   │  • Estimate token cost              │               │    │
│  │   │  • Check against budget             │               │    │
│  │   │  • Return: allow/warn/block         │               │    │
│  │   └─────────────────────────────────────┘               │    │
│  │                         │                                │    │
│  │            ┌────────────┼────────────┐                  │    │
│  │            ▼            ▼            ▼                  │    │
│  │         [allow]      [warn]       [block]               │    │
│  │            │            │            │                  │    │
│  │            │      Show warning   Return error           │    │
│  │            │            │       (stop here)             │    │
│  │            └────────────┘                               │    │
│  │                         │                                │    │
│  │                         ▼                                │    │
│  │              Tool executes normally                      │    │
│  │                         │                                │    │
│  │                         ▼                                │    │
│  │   ┌─────────────────────────────────────┐               │    │
│  │   │        PostToolUse Hook             │               │    │
│  │   │  ─────────────────────────────────  │               │    │
│  │   │  • Calculate actual tokens          │               │    │
│  │   │  • Update session totals            │               │    │
│  │   │  • Check alert thresholds           │               │    │
│  │   │  • Log operation details            │               │    │
│  │   └─────────────────────────────────────┘               │    │
│  │                         │                                │    │
│  │                         ▼                                │    │
│  │              Return to user                              │    │
│  │                         │                                │    │
│  └─────────────────────────┴────────────────────────────────┘    │
│                            │                                      │
│                    (repeat for each operation)                    │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│       SessionEnd Hook       │
│  ─────────────────────────  │
│  • Finalize session data    │
│  • Calculate efficiency     │
│  • Update daily/monthly     │
│  • Display summary          │
└─────────────────────────────┘
```

## Hook Input/Output

### Input Format

All hooks receive JSON via stdin:

```json
{
  "session_id": "abc123def456",
  "hook_event_name": "PreToolUse",
  "tool_name": "Read",
  "tool_input": {
    "file_path": "/path/to/file.ts"
  },
  "cwd": "/Users/dev/project",
  "transcript_path": "/tmp/claude/transcript.txt"
}
```

### Output Format

Hooks output JSON to stdout:

```json
{
  "hookSpecificOutput": {
    "permissionDecision": "allow"
  },
  "systemMessage": "Cost: ~$0.05 | Total: $2.47 / $10.00"
}
```

**Permission decisions:**
- `allow` - Operation proceeds normally
- `ask` - Claude asks user for confirmation
- `deny` - Operation is blocked

## Cost Estimation

### Token Estimation Algorithm

```
┌─────────────────────────────────────────────────────────────────┐
│                    TOKEN ESTIMATION                              │
└─────────────────────────────────────────────────────────────────┘

For file operations (Read, Edit, Write):

  1. Get file size in bytes
  2. Determine content type (code vs text)
  3. Apply character-to-token ratio:
     - Plain text: 4 chars/token
     - Source code: 3 chars/token
     - JSON/YAML: 3 chars/token
  4. Add tool overhead:
     - Bash: +245 tokens
     - Edit/Write: +700 tokens
  5. Estimate output tokens (varies by tool)

Example for Read:
  File: src/app.ts (8,000 bytes)
  Tokens: 8000 / 3 = 2,667 tokens
  + Tool overhead: 0
  = 2,667 input tokens

  Output estimate: ~100 tokens (minimal for Read)
```

### Cost Calculation

```
Cost = (Input Tokens × Input Rate) + (Output Tokens × Output Rate)
                      ────────────────────────────────────
                              1,000,000

Example (Sonnet 4):
  Input:  2,667 tokens × $3.00/M  = $0.0080
  Output:   100 tokens × $15.00/M = $0.0015
  Total:                          = $0.0095 ≈ $0.01
```

### Pricing Table (January 2025)

| Model | Input/1M | Output/1M | Cache Read/1M |
|-------|----------|-----------|---------------|
| Claude Opus 4.5 | $5.00 | $25.00 | $0.50 |
| Claude Sonnet 4 | $3.00 | $15.00 | $0.30 |
| Claude Haiku 4.5 | $1.00 | $5.00 | $0.10 |

### Tool-Specific Costs

| Tool | Fixed Overhead | Variable Cost |
|------|----------------|---------------|
| Read | 0 tokens | File size based |
| Write | 700 tokens | Content size based |
| Edit | 700 tokens | Old + new string based |
| Bash | 245 tokens | Output dependent |
| Grep | 0 tokens | Results count based |
| Glob | 0 tokens | Results count based |
| WebSearch | 0 tokens | $0.01 per search |
| WebFetch | 0 tokens | Page size based |

## Data Storage

### Directory Structure

```
~/.claude/cost-guardian/
├── sessions/
│   ├── abc123def456.json    # Completed session
│   ├── xyz789ghi012.json    # Another session
│   └── current.json → ...   # Symlink to active
├── budgets.json             # User configuration
└── history.json             # Aggregated history
```

### Session File Schema

```json
{
  "session_id": "abc123def456",
  "started_at": "2025-01-12T10:30:00Z",
  "ended_at": "2025-01-12T11:15:00Z",
  "project_dir": "/Users/dev/myproject",
  "model": "claude-sonnet-4",

  "costs": {
    "total": 3.47,
    "input_tokens": 89234,
    "output_tokens": 12456,
    "cache_read_tokens": 15000,
    "cache_write_tokens": 2500,
    "tool_overhead_tokens": 4200,
    "web_searches": 3
  },

  "operations": [
    {
      "timestamp": "2025-01-12T10:31:15Z",
      "tool": "Read",
      "input_tokens": 2667,
      "output_tokens": 100,
      "overhead_tokens": 0,
      "cost": 0.0095,
      "details": {
        "file_path": "/src/app.ts"
      }
    }
  ],

  "budget": {
    "session": {
      "limit": 10.00,
      "enforcement": "warn"
    }
  },

  "alerts_triggered": [50, 80],

  "efficiency_metrics": {
    "score": 87,
    "grade": "A-",
    "cache_hit_rate": 0.65,
    "redundant_operations": 3,
    "avg_tokens_per_operation": 1898
  }
}
```

### Budget Configuration Schema

```json
{
  "session": {
    "limit": 10.00,
    "enforcement": "warn",
    "alert_thresholds": [50, 80, 95]
  },
  "daily": {
    "limit": 50.00,
    "spent": 12.34,
    "last_reset": "2025-01-12",
    "reset_time": "00:00"
  },
  "monthly": {
    "limit": 500.00,
    "spent": 156.78,
    "last_reset": "2025-01-01",
    "reset_day": 1
  },
  "project": {
    "/Users/dev/myproject": {
      "limit": 100.00,
      "spent": 45.67
    }
  }
}
```

## Efficiency Scoring

### Score Calculation

```
Total Score = (Token Efficiency × 0.30) +
              (Cache Utilization × 0.25) +
              (Model Optimization × 0.25) +
              (Redundancy Score × 0.20)
```

### Component Scores

**Token Efficiency (0-100):**
```
Ratio = Output Tokens / Input Tokens
Score = min(100, Ratio × 500)

Good: 0.10-0.20 ratio → 50-100 score
Bad:  <0.05 ratio → <25 score
```

**Cache Utilization (0-100):**
```
Rate = Cache Reads / Total Reads
Score = Rate × 100

70%+ cache hits = 70+ score
```

**Model Optimization (0-100):**
```
Based on task-model matching:
- Simple tasks on Haiku: +points
- Complex tasks on Opus: +points
- Mismatches: -points
```

**Redundancy Score (0-100):**
```
Score = 100 - (Redundant Ops / Total Ops × 100)

0 redundant ops = 100
5+ redundant ops = penalty
```

### Grade Mapping

| Score | Grade | Percentile |
|-------|-------|------------|
| 95-100 | A+ | Top 5% |
| 85-94 | A | Top 15% |
| 70-84 | B | Top 35% |
| 50-69 | C | Top 60% |
| 30-49 | D | Top 85% |
| 0-29 | F | Bottom 15% |

## Performance Considerations

### Hook Execution Time

All hooks must complete within 3 seconds. Cost Guardian typically completes in <100ms:

| Hook | Typical Time | Max Time |
|------|--------------|----------|
| SessionStart | 50ms | 500ms |
| PreToolUse | 20ms | 100ms |
| PostToolUse | 30ms | 150ms |
| SessionEnd | 100ms | 1000ms |

### Optimization Techniques

1. **Local calculations only** - No API calls in hooks
2. **Cached pricing data** - Loaded once per session
3. **Atomic file updates** - Write to temp, then rename
4. **Minimal JSON parsing** - Use jq streaming where possible

## Limitations

1. **Token counts are estimates** - Actual counts come from API
2. **Cache status unknown** - Can't detect cache hits/misses directly
3. **Model detection** - Relies on environment variable
4. **Concurrent sessions** - Potential race conditions on shared files
5. **Output estimation** - Varies significantly by operation type

## Security

- All data stored locally in user's home directory
- No external network calls
- No telemetry or tracking
- Sharing is explicit opt-in only
- No credentials or API keys stored
