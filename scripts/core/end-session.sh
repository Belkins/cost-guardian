#!/bin/bash
# end-session.sh - SessionEnd/Stop hook for Cost Guardian
# Generates session summary and saves to history

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

# Get current session
session_data=$(read_session "$session_id")
if [[ "$session_data" == "{}" ]]; then
  exit 0
fi

# Finalize session
end_time=$(date -Iseconds)
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
    ratio=$(echo "scale=2; $output_tokens / $input_tokens" | bc)
    token_score=$(echo "scale=0; $ratio * 200" | bc 2>/dev/null || echo "50")
    if (( token_score > 100 )); then token_score=100; fi
  else
    token_score=50
  fi

  # Average tokens per operation
  avg_tokens=$(echo "scale=0; ($input_tokens + $output_tokens) / $operation_count" | bc)

  # Simple scoring: token efficiency
  efficiency_score=$token_score
fi

# Determine grade
grade="C"
if (( efficiency_score >= 95 )); then grade="A+"
elif (( efficiency_score >= 85 )); then grade="A"
elif (( efficiency_score >= 70 )); then grade="B"
elif (( efficiency_score >= 50 )); then grade="C"
elif (( efficiency_score >= 30 )); then grade="D"
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
formatted_input=$(printf "%'d" "$input_tokens")
formatted_output=$(printf "%'d" "$output_tokens")

# Generate summary message
cat <<EOF
{
  "systemMessage": "SESSION SUMMARY\\n================\\nTotal Cost: \$${formatted_cost}\\nTokens: ${formatted_input} in / ${formatted_output} out\\nOperations: ${operation_count}\\nEfficiency: ${grade} (${efficiency_score}/100)\\n\\nUse /cost-report for detailed analytics."
}
EOF

# Cleanup old sessions (optional)
cleanup_old_sessions

exit 0
