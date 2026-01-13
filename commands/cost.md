---
description: View current session costs and spending breakdown
argument-hint: [--detail|--breakdown|--estimate]
allowed-tools: Read, Bash(cat:*), Bash(ls:*), Bash(wc:*)
---

# Cost Command

View your current Claude Code session costs.

## Current Session Data

!`cat ~/.claude/cost-guardian/sessions/current.json 2>/dev/null || echo '{"error": "No active session"}'`

## Historical Data

!`cat ~/.claude/cost-guardian/history.json 2>/dev/null || echo '{"daily": {}, "monthly": {}, "all_time": 0}'`

## Arguments Received: $ARGUMENTS

## Instructions

Display cost information based on the arguments:

### Default (no arguments):
Show a concise summary:
```
Cost Guardian: Session Costs
============================
Total:      $X.XX
Tokens:     XX,XXX input / XX,XXX output
Operations: XX
Duration:   XX minutes

Budget:     $X.XX / $XX.XX (XX%)
```

Calculate duration from started_at to now.

### If "--detail" is requested:
Show per-operation breakdown:
```
Cost Guardian: Detailed Costs
=============================

Operation Log:
1. [timestamp] Tool: Read     $0.XX  (X,XXX tokens)
2. [timestamp] Tool: Edit     $0.XX  (X,XXX tokens)
...

Top 5 Expensive Operations:
1. Edit src/app.ts            $0.XX
2. Read large-file.json       $0.XX
...
```

List operations from the session's operations array, sorted by cost.

### If "--breakdown" is requested:
Show costs grouped by category:
```
Cost Guardian: Cost Breakdown
=============================

By Tool Type:
  Edit:   $X.XX (XX%)
  Read:   $X.XX (XX%)
  Bash:   $X.XX (XX%)
  Other:  $X.XX (XX%)

Token Distribution:
  Input:    XX,XXX (XX%)
  Output:   XX,XXX (XX%)
  Overhead: XX,XXX (XX%)
```

### If "--estimate" is requested:
Project future costs based on current pace:
```
Cost Guardian: Cost Projection
==============================

Current pace: $X.XX/hour
Session so far: XX minutes, $X.XX

Projected costs:
  1 hour:   $X.XX
  2 hours:  $X.XX
  4 hours:  $X.XX

Budget status: XX% used, ~XX minutes remaining
```

## Response Format

Always use clear formatting with:
- Dollar amounts to 2 decimal places
- Token counts with thousand separators
- Percentages as whole numbers
- Clear section headers
