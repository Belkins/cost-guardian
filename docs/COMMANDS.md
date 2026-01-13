# Command Reference

Complete reference for all Cost Guardian commands.

---

## /budget

Manage spending budgets and enforcement.

### Set Budget

```bash
/budget set <amount> [--scope <scope>] [--enforcement <mode>]
```

**Arguments:**
- `<amount>` - Budget limit in USD (e.g., `10`, `50.00`)
- `--scope` - Budget scope: `session` (default), `daily`, `monthly`, `project`
- `--enforcement` - Mode: `warn` (default), `confirm`, `block`

**Examples:**

```bash
# Set $10 session budget with warnings
/budget set 10

# Set $50 daily budget requiring confirmation
/budget set 50 --scope daily --enforcement confirm

# Set $500 monthly budget with hard block
/budget set 500 --scope monthly --enforcement block

# Set project-specific budget
/budget set 100 --scope project
```

### View Budget

```bash
/budget
```

Shows current budget configuration and spending:

```
Cost Guardian: Budget Status
============================
Session:  $3.47 / $10.00 (34.7%)
Daily:    $12.50 / $50.00 (25.0%)
Monthly:  $156.30 / $500.00 (31.3%)

Enforcement: warn
Alerts: 50%, 80%, 95%
```

### Reset Budget

```bash
/budget reset [--scope <scope>]
```

**Examples:**

```bash
# Reset session budget
/budget reset

# Reset all budgets
/budget reset --scope all

# Reset only daily budget
/budget reset --scope daily
```

### Configure Alerts

```bash
/budget alert <thresholds>
```

**Examples:**

```bash
# Alert at 50%, 80%, 95% (default)
/budget alert 50,80,95

# Alert at 25%, 50%, 75%, 90%
/budget alert 25,50,75,90

# Single alert at 80%
/budget alert 80
```

---

## /cost

View current session costs.

### Basic Usage

```bash
/cost
```

**Output:**

```
Cost Guardian: Session Costs
============================
Total:      $2.47
Tokens:     45,230 input / 8,456 output
Operations: 23
Duration:   32 minutes

Budget:     $2.47 / $10.00 (24.7%)
```

### Detailed View

```bash
/cost --detail
```

Shows per-operation breakdown:

```
Cost Guardian: Detailed Costs
=============================

Operation Log:
1. Read src/app.ts              $0.12  (2,450 tokens)
2. Edit src/app.ts              $0.38  (7,800 tokens)
3. Bash npm test                $0.08  (1,200 tokens)
4. Read package.json            $0.04  (850 tokens)
...

Top 5 Expensive Operations:
1. Edit src/components/App.tsx  $0.52
2. Edit src/app.ts              $0.38
3. Read node_modules/...        $0.28
4. Bash npm run build           $0.15
5. Read src/utils/helpers.ts    $0.14
```

### Category Breakdown

```bash
/cost --breakdown
```

Shows costs by category:

```
Cost Guardian: Cost Breakdown
=============================

By Category:
  File Operations:  $1.23 (49.8%)
  Code Generation:  $0.89 (36.0%)
  Tool Execution:   $0.25 (10.1%)
  Conversation:     $0.10 (4.1%)

By Tool:
  Edit:   $0.89 (36.0%)
  Read:   $0.67 (27.1%)
  Bash:   $0.45 (18.2%)
  Grep:   $0.28 (11.3%)
  Other:  $0.18 (7.3%)
```

### Projection

```bash
/cost --estimate
```

Projects session cost based on current pace:

```
Cost Guardian: Cost Projection
==============================

Current pace: $4.63/hour
Session so far: 32 minutes, $2.47

Projected costs:
  1 hour:   $4.63
  2 hours:  $9.26
  4 hours:  $18.52

At current pace, you'll hit budget in: 1h 38m
```

---

## /cost-report

Generate detailed analytics reports.

### Session Report

```bash
/cost-report
```

Full analytics for current session:

```
Cost Guardian: Session Report
=============================

SUMMARY
-------
Total Cost:     $3.47
Tokens Used:    89,234 input / 12,456 output
Operations:     47
Duration:       45 minutes
Efficiency:     A- (score: 87)

COST BREAKDOWN
--------------
File Operations:  $1.23 (35.4%)
Code Generation:  $1.89 (54.5%)
Searches:         $0.35 (10.1%)

TOKEN EFFICIENCY
----------------
Output/Input Ratio: 0.14 (good)
Cache Hit Rate:     65% (excellent)
Overhead Tokens:    4,200 (4.7%)

TOP OPERATIONS
--------------
1. Edit src/components/Dashboard.tsx  $0.52
2. Edit src/app.ts                    $0.38
3. Read node_modules/react/...        $0.28

PATTERNS DETECTED
-----------------
- 3 redundant file reads
- High cache utilization
- Good model selection
```

### Period Report

```bash
/cost-report --period <day|week|month>
```

**Examples:**

```bash
# Today's costs
/cost-report --period day

# Last 7 days
/cost-report --period week

# Last 30 days
/cost-report --period month
```

**Output:**

```
Cost Guardian: Weekly Report
============================

PERIOD: Jan 6 - Jan 12, 2025

DAILY BREAKDOWN
---------------
Mon Jan 6:   $4.23  ████████
Tue Jan 7:   $6.78  █████████████
Wed Jan 8:   $3.12  ██████
Thu Jan 9:   $5.45  ██████████
Fri Jan 10:  $8.90  █████████████████
Sat Jan 11:  $2.10  ████
Sun Jan 12:  $1.50  ███

WEEKLY TOTAL: $32.08
DAILY AVERAGE: $4.58

TRENDS
------
- Highest day: Friday ($8.90)
- Lowest day: Sunday ($1.50)
- Week-over-week: +12% vs last week
```

### Export Report

```bash
/cost-report --format <text|json|html>
```

---

## /cost-optimize

Get AI-powered optimization suggestions.

### Basic Usage

```bash
/cost-optimize
```

**Output:**

```
Cost Guardian: Optimization Analysis
====================================

IMMEDIATE SAVINGS OPPORTUNITIES

1. Redundant Reads Detected
   Potential savings: $0.24
   - src/utils/helpers.ts read 4 times
   - src/config/settings.ts read 3 times
   Action: Read once, reference in subsequent prompts

2. Large Context Warning
   Potential savings: 30% on input costs
   - Average context size: 45,000 tokens
   - Action: Use more specific file paths
   - Action: Summarize large contexts

3. Model Optimization
   Potential savings: $0.89
   - 12 operations used Opus for simple tasks
   - Formatting, boilerplate → Use Haiku
   - Debugging, refactoring → Use Sonnet
   - Complex architecture → Keep Opus

4. Caching Opportunity
   Potential savings: $0.67/session
   - System prompt: 2,500 tokens (repeated 23x)
   - Action: Enable prompt caching

PROJECTED MONTHLY SAVINGS: $45-60

Want detailed recommendations? Run:
/cost-optimize --aggressive
```

### Optimization Levels

```bash
# Minimal changes, easy wins only
/cost-optimize --minimal

# Balanced recommendations (default)
/cost-optimize --balanced

# Aggressive optimization, may impact workflow
/cost-optimize --aggressive
```

---

## /cost-share

Export shareable reports and badges.

### Generate Report

```bash
/cost-share
```

Creates shareable markdown report:

```markdown
## Claude Code Cost Report

**Session:** January 12, 2025
**Total Cost:** $3.47
**Efficiency Score:** A- (87/100)

### Breakdown
- Tokens: 89,234 input / 12,456 output
- Operations: 47
- Duration: 45 minutes

### Highlights
- Cache hit rate: 65%
- Model efficiency: Optimal
- No redundant operations

---
*Generated by Cost Guardian*
```

### Generate Badge

```bash
/cost-share --format badge
```

**Output:**

```markdown
Add this to your README:

[![Claude Code Efficiency: A-](https://img.shields.io/badge/Claude%20Code-A--Efficiency-brightgreen)](https://github.com/your-username/cost-guardian)

Or with cost:

[![Claude Code: $3.47](https://img.shields.io/badge/Claude%20Code-%243.47-blue)](https://github.com/your-username/cost-guardian)
```

### Export Formats

```bash
# Markdown (default)
/cost-share

# JSON data
/cost-share --format json

# HTML page
/cost-share --format html

# SVG badge
/cost-share --format badge
```

### Period Selection

```bash
# Current session (default)
/cost-share

# Today's costs
/cost-share --period day

# This week
/cost-share --period week

# This month
/cost-share --period month
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `/budget set 10` | Set $10 session budget |
| `/budget set 50 --scope daily` | Set $50 daily budget |
| `/budget set 10 --enforcement block` | Set budget with hard block |
| `/budget` | View current budgets |
| `/budget reset` | Clear session budget |
| `/budget alert 50,80,95` | Set alert thresholds |
| `/cost` | View current costs |
| `/cost --detail` | Per-operation breakdown |
| `/cost --breakdown` | Costs by category |
| `/cost --estimate` | Project future costs |
| `/cost-report` | Full session analytics |
| `/cost-report --period week` | Last 7 days report |
| `/cost-optimize` | Get savings suggestions |
| `/cost-share` | Export shareable report |
| `/cost-share --format badge` | Generate README badge |
