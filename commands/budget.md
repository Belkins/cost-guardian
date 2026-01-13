---
description: Set and manage cost budgets for sessions, daily, and monthly spending limits
argument-hint: [set <amount>|view|reset] [--scope session|daily|monthly] [--enforcement warn|confirm|block]
allowed-tools: Read, Bash(cat:*), Bash(echo:*), Bash(mkdir:*), Write
---

# Budget Management Command

Manage your Claude Code spending limits with Cost Guardian.

## Current Budget Status

First, let me check your current budget configuration:

!`cat ~/.claude/cost-guardian/budgets.json 2>/dev/null || echo '{"session": null, "daily": null, "monthly": null}'`

## Current Spending

!`cat ~/.claude/cost-guardian/history.json 2>/dev/null || echo '{"daily": {}, "monthly": {}, "all_time": 0}'`

## Arguments Received: $ARGUMENTS

## Instructions

Based on the arguments provided, perform ONE of these actions:

### If "set <amount>" is requested:
1. Parse the amount (e.g., "10" means $10.00)
2. Parse --scope (default: session) - can be: session, daily, monthly
3. Parse --enforcement (default: warn) - can be: warn, confirm, block
4. Update the budgets.json file at ~/.claude/cost-guardian/budgets.json
5. Confirm the new budget settings to the user

Example budget structure:
```json
{
  "session": {
    "limit": 10.00,
    "enforcement": "warn",
    "alert_thresholds": [50, 80, 95]
  },
  "daily": {
    "limit": 50.00,
    "enforcement": "warn"
  },
  "monthly": {
    "limit": 500.00,
    "enforcement": "warn"
  }
}
```

### If "view" or no arguments:
Display the current budget configuration in a formatted way:
- Show each budget scope (session, daily, monthly)
- Show current spending vs limits
- Show enforcement mode
- Show alert thresholds

### If "reset" is requested:
1. Parse --scope to determine what to reset (default: session, can be "all")
2. Set the specified budget to null in budgets.json
3. Confirm the reset to the user

### If "alert <thresholds>" is requested:
1. Parse the comma-separated thresholds (e.g., "50,80,95")
2. Update the alert_thresholds for the session budget
3. Confirm the new thresholds

## Response Format

After making changes, display a summary like:

```
Cost Guardian: Budget configured!
  - Session limit: $10.00
  - Enforcement: warn
  - Alerts at: 50%, 80%, 95%

Current spending:
  - Today: $X.XX
  - This month: $X.XX
```

Ensure the ~/.claude/cost-guardian directory exists before writing.
