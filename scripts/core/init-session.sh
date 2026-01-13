#!/bin/bash
# init-session.sh - SessionStart hook for Cost Guardian
# Initializes cost tracking for a new session

set -euo pipefail

# Get plugin root
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Source utilities
source "${PLUGIN_ROOT}/scripts/utils/storage.sh"
source "${PLUGIN_ROOT}/scripts/utils/pricing.sh"

# Read hook input from stdin
input=$(cat)

# Parse input
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
cwd=$(echo "$input" | jq -r '.cwd // "."')

# Detect model from environment or default
model="${CLAUDE_MODEL:-claude-sonnet-4}"

# Ensure data directories exist
ensure_data_dirs

# Initialize session data
session_data=$(cat <<EOF
{
  "session_id": "$session_id",
  "started_at": "$(date -Iseconds)",
  "ended_at": null,
  "project_dir": "$cwd",
  "model": "$model",
  "costs": {
    "total": 0,
    "input_tokens": 0,
    "output_tokens": 0,
    "cache_read_tokens": 0,
    "cache_write_tokens": 0,
    "tool_overhead_tokens": 0,
    "web_searches": 0
  },
  "operations": [],
  "budget": $(read_budgets),
  "alerts_triggered": [],
  "efficiency_metrics": {
    "score": 0,
    "grade": "-",
    "cache_hit_rate": 0,
    "redundant_operations": 0,
    "avg_tokens_per_operation": 0
  }
}
EOF
)

# Write session file
write_session "$session_id" "$session_data"

# Create symlink to current session
link_current_session "$session_id"

# Check daily/monthly limits and warn if close
budgets=$(read_budgets)
daily_limit=$(echo "$budgets" | jq -r '.daily.limit // empty')
monthly_limit=$(echo "$budgets" | jq -r '.monthly.limit // empty')

warnings=""

if [[ -n "$daily_limit" ]]; then
  daily_spent=$(get_daily_spent)
  daily_remaining=$(echo "scale=2; $daily_limit - $daily_spent" | bc)
  daily_percent=$(echo "scale=0; $daily_spent * 100 / $daily_limit" | bc 2>/dev/null || echo "0")

  if (( $(echo "$daily_percent >= 80" | bc -l) )); then
    warnings="${warnings}Daily budget: ${daily_percent}% used (\$${daily_spent}/\$${daily_limit}). "
  fi
fi

if [[ -n "$monthly_limit" ]]; then
  monthly_spent=$(get_monthly_spent)
  monthly_remaining=$(echo "scale=2; $monthly_limit - $monthly_spent" | bc)
  monthly_percent=$(echo "scale=0; $monthly_spent * 100 / $monthly_limit" | bc 2>/dev/null || echo "0")

  if (( $(echo "$monthly_percent >= 80" | bc -l) )); then
    warnings="${warnings}Monthly budget: ${monthly_percent}% used (\$${monthly_spent}/\$${monthly_limit}). "
  fi
fi

# Output initialization message
if [[ -n "$warnings" ]]; then
  cat <<EOF
{
  "systemMessage": "Cost Guardian active. ${warnings}Use /budget to manage limits, /cost to view spending."
}
EOF
else
  cat <<EOF
{
  "systemMessage": "Cost Guardian active. Use /budget to set limits, /cost to view spending."
}
EOF
fi

exit 0
