#!/bin/bash
# end-session.sh - SessionEnd/Stop hook for Cost Guardian
# Generates session summary and saves to history

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

# Format number with thousand separators (portable)
format_number() {
  local num="$1"
  # Use printf with LC_NUMERIC if available, otherwise use sed
  if printf "%'d" 0 >/dev/null 2>&1; then
    printf "%'d" "$num"
  else
    echo "$num" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
  fi
}

# Read hook input from stdin
input=$(cat)

# Parse input
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')

# Get current session
session_data=$(read_session "$session_id")
if [[ "$session_data" == "{}" ]]; then
  exit 0
fi

# Finalize session
end_time=$(get_iso_timestamp)
session_data=$(echo "$session_data" | jq --arg end "$end_time" '.ended_at = $end')

# Calculate efficiency metrics
total_cost=$(echo "$session_data" | jq -r '.costs.total // 0')
input_tokens=$(echo "$session_data" | jq -r '.costs.input_tokens // 0')
output_tokens=$(echo "$session_data" | jq -r '.costs.output_tokens // 0')
operation_count=$(echo "$session_data" | jq -r '.operations | length')

# Calculate efficiency score (simplified)
efficiency_score=50  # Default

if (( operation_count > 0 )); then
  # Token efficiency (output/input ratio) - higher is better, up to a point
  if (( input_tokens > 0 )); then
    # Calculate ratio and multiply by 200, then truncate to integer
    token_score=$(echo "scale=0; ($output_tokens * 200 / $input_tokens)" | bc 2>/dev/null || echo "50")
    # Remove any decimal parts and cap at 100
    token_score=${token_score%%.*}
    if [[ -z "$token_score" ]] || [[ "$token_score" -lt 0 ]]; then token_score=50; fi
    if [[ "$token_score" -gt 100 ]]; then token_score=100; fi
  else
    token_score=50
  fi

  # Average tokens per operation
  avg_tokens=$(echo "scale=0; ($input_tokens + $output_tokens) / $operation_count" | bc 2>/dev/null || echo "0")
  avg_tokens=${avg_tokens%%.*}
  if [[ -z "$avg_tokens" ]]; then avg_tokens=0; fi

  # Simple scoring: token efficiency
  efficiency_score=$token_score
fi

# Ensure efficiency_score is a valid integer
efficiency_score=${efficiency_score%%.*}
if [[ -z "$efficiency_score" ]] || ! [[ "$efficiency_score" =~ ^[0-9]+$ ]]; then
  efficiency_score=50
fi

# Determine grade
grade="C"
if [[ "$efficiency_score" -ge 95 ]]; then grade="A+"
elif [[ "$efficiency_score" -ge 85 ]]; then grade="A"
elif [[ "$efficiency_score" -ge 70 ]]; then grade="B"
elif [[ "$efficiency_score" -ge 50 ]]; then grade="C"
elif [[ "$efficiency_score" -ge 30 ]]; then grade="D"
else grade="F"
fi

# Update efficiency metrics
session_data=$(echo "$session_data" | jq \
  --argjson score "$efficiency_score" \
  --arg grade "$grade" \
  --argjson avg "$avg_tokens" '
  .efficiency_metrics.score = $score |
  .efficiency_metrics.grade = $grade |
  .efficiency_metrics.avg_tokens_per_operation = $avg
')

# Write final session data
write_session "$session_id" "$session_data"

# Add to history
add_to_history "$total_cost"

# Format values for display
formatted_cost=$(printf "%.2f" "$total_cost")
formatted_input=$(format_number "$input_tokens")
formatted_output=$(format_number "$output_tokens")

# Generate summary message
cat <<EOF
{
  "systemMessage": "SESSION SUMMARY\\n================\\nTotal Cost: \$${formatted_cost}\\nTokens: ${formatted_input} in / ${formatted_output} out\\nOperations: ${operation_count}\\nEfficiency: ${grade} (${efficiency_score}/100)\\n\\nUse /cost-report for detailed analytics."
}
EOF

# Cleanup old sessions (optional)
cleanup_old_sessions

exit 0
