---
description: Generate detailed cost analytics and reports
argument-hint: [--period day|week|month] [--format text|json]
allowed-tools: Read, Bash(cat:*), Bash(ls:*), Bash(find:*), Bash(date:*)
---

# Cost Report Command

Generate comprehensive cost analytics for your Claude Code usage.

## Current Session

!`cat ~/.claude/cost-guardian/sessions/current.json 2>/dev/null || echo '{}'`

## Historical Data

!`cat ~/.claude/cost-guardian/history.json 2>/dev/null || echo '{"daily": {}, "monthly": {}, "all_time": 0}'`

## Recent Sessions

!`ls -la ~/.claude/cost-guardian/sessions/ 2>/dev/null | head -20`

## Arguments Received: $ARGUMENTS

## Instructions

Generate a detailed analytics report based on arguments:

### Default (current session):
```
Cost Guardian: Session Report
=============================

SUMMARY
-------
Total Cost:     $X.XX
Tokens Used:    XX,XXX input / XX,XXX output
Operations:     XX
Duration:       XX minutes
Efficiency:     X (score: XX/100)

COST BREAKDOWN
--------------
By Tool:
  Edit:   $X.XX (XX%)
  Read:   $X.XX (XX%)
  Bash:   $X.XX (XX%)
  Grep:   $X.XX (XX%)
  Other:  $X.XX (XX%)

TOKEN EFFICIENCY
----------------
Output/Input Ratio: X.XX
Overhead Tokens:    XX,XXX (X.X%)
Avg per Operation:  XX,XXX

TOP 10 OPERATIONS
-----------------
1. [tool] [details]    $X.XX
2. [tool] [details]    $X.XX
...

EFFICIENCY SCORE: X (XX/100)
- Token efficiency: XX/30
- Low redundancy: XX/20
- Good overhead ratio: XX/25
- Consistent pacing: XX/25
```

### If "--period day" is requested:
Show today's costs across all sessions.

### If "--period week" is requested:
Show last 7 days with daily breakdown:
```
Cost Guardian: Weekly Report
============================

PERIOD: [start date] - [end date]

DAILY BREAKDOWN
---------------
Mon Jan 6:   $X.XX  ████████
Tue Jan 7:   $X.XX  █████████████
Wed Jan 8:   $X.XX  ██████
...

WEEKLY TOTAL: $XX.XX
DAILY AVERAGE: $X.XX

TRENDS
------
- Highest day: [day] ($X.XX)
- Lowest day: [day] ($X.XX)
- Week-over-week: +/-XX%
```

Use bar chart visualization with Unicode blocks (█).

### If "--period month" is requested:
Show last 30 days with weekly summaries.

### If "--format json" is requested:
Output raw JSON data instead of formatted text.

## Response Format

- Use clear section headers
- Include visual elements (bars, separators)
- Calculate all percentages and ratios
- Provide actionable insights
