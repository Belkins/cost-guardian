#!/bin/bash
# pre-tool-check.sh - PreToolUse hook for Cost Guardian
# Estimates cost before tool execution and enforces budgets

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
tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')
tool_input=$(echo "$input" | jq -c '.tool_input // {}')

# Get current session
session_data=$(read_session "$session_id")
if [[ "$session_data" == "{}" ]]; then
  # No session, allow operation
  exit 0
fi

# Get model and pricing
model=$(echo "$session_data" | jq -r '.model // "claude-sonnet-4"')

# Estimate cost for this operation
estimated_cost=$(estimate_tool_cost "$tool_name" "$tool_input" "$model")

# Get current totals
current_total=$(echo "$session_data" | jq -r '.costs.total // 0')

# Get budget configuration
budget=$(echo "$session_data" | jq -r '.budget // {}')
session_limit=$(echo "$budget" | jq -r '.session.limit // empty')
enforcement=$(echo "$budget" | jq -r '.session.enforcement // "warn"')

# Calculate projected total
projected=$(echo "scale=6; $current_total + $estimated_cost" | bc)

# Format values for display
formatted_estimate=$(printf "%.4f" "$estimated_cost")
formatted_current=$(printf "%.2f" "$current_total")
formatted_projected=$(printf "%.2f" "$projected")

# Check if we have a budget limit
if [[ -n "$session_limit" ]]; then
  formatted_limit=$(printf "%.2f" "$session_limit")

  # Check if operation would exceed budget
  if (( $(echo "$projected > $session_limit" | bc -l) )); then
    case "$enforcement" in
      block)
        # Hard block - deny the operation
        cat <<EOF
{
  "hookSpecificOutput": {
    "permissionDecision": "deny"
  },
  "systemMessage": "BUDGET BLOCKED: Operation (~\$${formatted_estimate}) would exceed budget. Current: \$${formatted_current}/\$${formatted_limit}. Use /budget to adjust."
}
EOF
        exit 0
        ;;
      confirm)
        # Soft block - ask for confirmation
        cat <<EOF
{
  "hookSpecificOutput": {
    "permissionDecision": "ask"
  },
  "systemMessage": "BUDGET WARNING: Operation (~\$${formatted_estimate}) will exceed budget (\$${formatted_projected}/\$${formatted_limit}). Proceed?"
}
EOF
        exit 0
        ;;
      *)
        # Warn only - show warning but allow
        cat <<EOF
{
  "systemMessage": "Budget warning: ~\$${formatted_estimate} (Total: \$${formatted_projected}/\$${formatted_limit})"
}
EOF
        exit 0
        ;;
    esac
  fi
fi

# Check for expensive operations (>$0.10) even without budget
if (( $(echo "$estimated_cost > 0.10" | bc -l) )); then
  cat <<EOF
{
  "systemMessage": "Expensive operation: $tool_name ~\$${formatted_estimate}"
}
EOF
  exit 0
fi

# Check for web search (has additional fixed cost)
if [[ "$tool_name" == "WebSearch" || "$tool_name" == "websearch" ]]; then
  web_search_cost=$(get_special_cost "web_search")
  cat <<EOF
{
  "systemMessage": "Web search: +\$${web_search_cost} per search"
}
EOF
  exit 0
fi

# Normal operation - no output needed
exit 0
