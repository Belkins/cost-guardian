#!/bin/bash
# pricing.sh - Cost calculation utilities for Cost Guardian
# Source this file in other scripts: source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/pricing.sh"

set -euo pipefail

# Get the plugin root directory
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PRICING_FILE="${PLUGIN_ROOT}/data/pricing.json"

# Load pricing data
get_model_pricing() {
  local model="${1:-claude-sonnet-4}"
  local field="$2"  # input, output, cache_read, etc.

  if [[ -f "$PRICING_FILE" ]]; then
    jq -r ".models[\"$model\"][\"$field\"] // .models[\"claude-sonnet-4\"][\"$field\"] // 3.00" "$PRICING_FILE"
  else
    # Default Sonnet pricing if file missing
    case "$field" in
      input) echo "3.00" ;;
      output) echo "15.00" ;;
      cache_read) echo "0.30" ;;
      *) echo "3.00" ;;
    esac
  fi
}

# Get tool overhead tokens
get_tool_overhead() {
  local tool_name="$1"

  if [[ -f "$PRICING_FILE" ]]; then
    case "$tool_name" in
      Bash|bash)
        jq -r '.tool_overheads.bash // 245' "$PRICING_FILE"
        ;;
      Edit|edit|Write|write)
        jq -r '.tool_overheads.text_editor // 700' "$PRICING_FILE"
        ;;
      *)
        echo "0"
        ;;
    esac
  else
    case "$tool_name" in
      Bash|bash) echo "245" ;;
      Edit|edit|Write|write) echo "700" ;;
      *) echo "0" ;;
    esac
  fi
}

# Estimate tokens from text length
estimate_tokens_from_text() {
  local text="$1"
  local content_type="${2:-text}"  # text, code, json

  local char_count=${#text}

  case "$content_type" in
    code|source)
      # Code is denser, ~3 chars per token
      echo $(( char_count / 3 ))
      ;;
    json|yaml)
      # Structured data, ~3 chars per token
      echo $(( char_count / 3 ))
      ;;
    *)
      # Plain text, ~4 chars per token
      echo $(( char_count / 4 ))
      ;;
  esac
}

# Estimate tokens for a file
estimate_file_tokens() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    echo "0"
    return
  fi

  local size
  size=$(wc -c < "$file_path" 2>/dev/null || echo "0")
  local extension="${file_path##*.}"

  case "$extension" in
    json|yaml|yml)
      echo $(( size / 3 ))
      ;;
    md|txt|html)
      echo $(( size / 4 ))
      ;;
    ts|js|tsx|jsx|py|go|rs|java|c|cpp|h|hpp|rb|php|swift|kt)
      echo $(( size / 3 ))
      ;;
    *)
      echo $(( size / 4 ))
      ;;
  esac
}

# Calculate cost from tokens
calculate_cost() {
  local input_tokens="${1:-0}"
  local output_tokens="${2:-0}"
  local model="${3:-claude-sonnet-4}"

  local input_rate
  local output_rate
  input_rate=$(get_model_pricing "$model" "input")
  output_rate=$(get_model_pricing "$model" "output")

  # Cost = tokens * rate / 1,000,000
  echo "scale=6; ($input_tokens * $input_rate + $output_tokens * $output_rate) / 1000000" | bc
}

# Estimate cost for a tool operation
estimate_tool_cost() {
  local tool_name="$1"
  local tool_input="$2"
  local model="${3:-claude-sonnet-4}"

  local estimated_input=0
  local estimated_output=0
  local overhead=0

  overhead=$(get_tool_overhead "$tool_name")

  case "$tool_name" in
    Read|read)
      local file_path
      file_path=$(echo "$tool_input" | jq -r '.file_path // ""' 2>/dev/null || echo "")
      if [[ -n "$file_path" && -f "$file_path" ]]; then
        estimated_input=$(estimate_file_tokens "$file_path")
      else
        estimated_input=500
      fi
      estimated_output=100
      ;;
    Write|write)
      local content
      content=$(echo "$tool_input" | jq -r '.content // ""' 2>/dev/null || echo "")
      estimated_input=$(estimate_tokens_from_text "$content" "code")
      estimated_input=$((estimated_input + 200))
      estimated_output=$((estimated_input / 2))
      ;;
    Edit|edit)
      local old_string new_string
      old_string=$(echo "$tool_input" | jq -r '.old_string // ""' 2>/dev/null || echo "")
      new_string=$(echo "$tool_input" | jq -r '.new_string // ""' 2>/dev/null || echo "")
      estimated_input=$(( $(estimate_tokens_from_text "$old_string" "code") + $(estimate_tokens_from_text "$new_string" "code") + 200 ))
      estimated_output=$((estimated_input / 2))
      ;;
    Bash|bash)
      estimated_input=300
      estimated_output=500
      ;;
    Grep|grep)
      estimated_input=200
      estimated_output=800
      ;;
    Glob|glob)
      estimated_input=100
      estimated_output=400
      ;;
    WebSearch|websearch)
      estimated_input=200
      estimated_output=2000
      ;;
    WebFetch|webfetch)
      estimated_input=100
      estimated_output=5000
      ;;
    Task|task)
      estimated_input=500
      estimated_output=2000
      ;;
    *)
      estimated_input=250
      estimated_output=250
      ;;
  esac

  # Add overhead to input
  estimated_input=$((estimated_input + overhead))

  # Calculate cost
  calculate_cost "$estimated_input" "$estimated_output" "$model"
}

# Format cost for display
format_cost() {
  local cost="$1"
  printf "\$%.2f" "$cost"
}

# Get special costs (web search, etc.)
get_special_cost() {
  local cost_type="$1"

  if [[ -f "$PRICING_FILE" ]]; then
    case "$cost_type" in
      web_search)
        jq -r '.special_costs.web_search_per_search // 0.01' "$PRICING_FILE"
        ;;
      code_execution)
        jq -r '.special_costs.code_execution_per_hour // 0.05' "$PRICING_FILE"
        ;;
      *)
        echo "0"
        ;;
    esac
  else
    case "$cost_type" in
      web_search) echo "0.01" ;;
      code_execution) echo "0.05" ;;
      *) echo "0" ;;
    esac
  fi
}
