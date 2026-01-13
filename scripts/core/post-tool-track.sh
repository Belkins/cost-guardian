#!/bin/bash
# post-tool-track.sh - PostToolUse hook for Cost Guardian
# Tracks actual token usage after tool execution

set -euo pipefail

# Get plugin root
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Source utilities
source "${PLUGIN_ROOT}/scripts/utils/storage.sh"
source "${PLUGIN_ROOT}/scripts/utils/pricing.sh"

# Get ISO 8601 timestamp (portable for macOS and Linux)
get_iso_timestamp() {
  if date --version >/dev/null 2>&1; then
    # GNU date (Linux)
    date -Iseconds
  else
    # BSD date (macOS)
    date -u +"%Y-%m-%dT%H:%M:%SZ"
  fi
}

# Read hook input from stdin
input=$(cat)

# Parse input
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')
tool_input=$(echo "$input" | jq -r '.tool_input // "{}"')
tool_result=$(echo "$input" | jq -r '.tool_response // .tool_result // ""')

# Get current session
session_data=$(read_session "$session_id")
if [[ "$session_data" == "{}" ]]; then
  # No session, skip tracking
  exit 0
fi

# Get model from session
model=$(echo "$session_data" | jq -r '.model // "claude-sonnet-4"')

# Calculate tokens from input/output sizes
input_length=${#tool_input}
result_length=${#tool_result}

# Estimate tokens (rough approximation)
input_tokens=$(( input_length / 4 ))
output_tokens=$(( result_length / 4 ))

# Get tool overhead
overhead=$(get_tool_overhead "$tool_name")

# Calculate cost
input_rate=$(get_model_pricing "$model" "input")
output_rate=$(get_model_pricing "$model" "output")

total_input=$((input_tokens + overhead))
cost=$(echo "scale=6; ($total_input * $input_rate + $output_tokens * $output_rate) / 1000000" | bc)

# Add special costs (e.g., web search)
if [[ "$tool_name" == "WebSearch" || "$tool_name" == "websearch" ]]; then
  web_search_cost=$(get_special_cost "web_search")
  cost=$(echo "scale=6; $cost + $web_search_cost" | bc)
fi

# Create operation record
timestamp=$(get_iso_timestamp)
operation=$(cat <<EOF
{
  "timestamp": "$timestamp",
  "tool": "$tool_name",
  "input_tokens": $input_tokens,
  "output_tokens": $output_tokens,
  "overhead_tokens": $overhead,
  "cost": $cost
}
EOF
)

# Update session with new operation and totals
updated_session=$(echo "$session_data" | jq --argjson op "$operation" --argjson cost "$cost" \
  --argjson in_tok "$input_tokens" --argjson out_tok "$output_tokens" --argjson overhead "$overhead" '
  .operations += [$op] |
  .costs.total = (.costs.total + $cost) |
  .costs.input_tokens = (.costs.input_tokens + $in_tok) |
  .costs.output_tokens = (.costs.output_tokens + $out_tok) |
  .costs.tool_overhead_tokens = (.costs.tool_overhead_tokens + $overhead)
')

# Check for web searches
if [[ "$tool_name" == "WebSearch" || "$tool_name" == "websearch" ]]; then
  updated_session=$(echo "$updated_session" | jq '.costs.web_searches += 1')
fi

# Write updated session
write_session "$session_id" "$updated_session"

# Check budget alerts
budget=$(echo "$updated_session" | jq -r '.budget // {}')
session_limit=$(echo "$budget" | jq -r '.session.limit // empty')
current_total=$(echo "$updated_session" | jq -r '.costs.total')

output_message=""

if [[ -n "$session_limit" ]]; then
  percentage=$(echo "scale=0; $current_total * 100 / $session_limit" | bc 2>/dev/null || echo "0")
  alerts_triggered=$(echo "$updated_session" | jq -r '.alerts_triggered // []')

  # Check thresholds (50%, 80%, 95%)
  for threshold in 50 80 95; do
    if (( percentage >= threshold )); then
      already_alerted=$(echo "$alerts_triggered" | jq "index($threshold)")
      if [[ "$already_alerted" == "null" ]]; then
        # Trigger alert
        updated_session=$(echo "$updated_session" | jq ".alerts_triggered += [$threshold]")
        write_session "$session_id" "$updated_session"

        formatted_current=$(printf "%.2f" "$current_total")
        formatted_limit=$(printf "%.2f" "$session_limit")
        output_message="BUDGET ALERT: ${percentage}% of session budget used (\$${formatted_current}/\$${formatted_limit})"
        break
      fi
    fi
  done
fi

# Output message if any
if [[ -n "$output_message" ]]; then
  cat <<EOF
{
  "systemMessage": "$output_message"
}
EOF
fi

exit 0
