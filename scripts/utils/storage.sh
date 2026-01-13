#!/bin/bash
# storage.sh - Data storage utilities for Cost Guardian
# Source this file in other scripts: source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/storage.sh"

set -euo pipefail

# Data directory
DATA_DIR="${HOME}/.claude/cost-guardian"
SESSIONS_DIR="${DATA_DIR}/sessions"
BUDGETS_FILE="${DATA_DIR}/budgets.json"
HISTORY_FILE="${DATA_DIR}/history.json"

# Ensure data directories exist
ensure_data_dirs() {
  mkdir -p "$SESSIONS_DIR"
}

# Get current session file path
get_session_file() {
  local session_id="${1:-}"
  if [[ -n "$session_id" ]]; then
    echo "${SESSIONS_DIR}/${session_id}.json"
  else
    echo "${SESSIONS_DIR}/current.json"
  fi
}

# Read session data
read_session() {
  local session_id="${1:-}"
  local session_file
  session_file=$(get_session_file "$session_id")

  if [[ -f "$session_file" ]]; then
    cat "$session_file"
  else
    echo '{}'
  fi
}

# Write session data atomically
write_session() {
  local session_id="$1"
  local data="$2"
  local session_file
  session_file=$(get_session_file "$session_id")

  ensure_data_dirs

  # Write to temp file first, then move (atomic)
  local tmp_file="${session_file}.tmp.$$"
  echo "$data" > "$tmp_file"
  mv "$tmp_file" "$session_file"
}

# Update session with jq expression
update_session() {
  local session_id="$1"
  local jq_expr="$2"

  local current_data
  current_data=$(read_session "$session_id")

  local updated_data
  updated_data=$(echo "$current_data" | jq "$jq_expr")

  write_session "$session_id" "$updated_data"
}

# Create symlink to current session
link_current_session() {
  local session_id="$1"
  local session_file="${SESSIONS_DIR}/${session_id}.json"
  local current_link="${SESSIONS_DIR}/current.json"

  ensure_data_dirs

  # Remove old symlink if exists
  rm -f "$current_link"

  # Create new symlink
  ln -sf "$session_file" "$current_link"
}

# Read budgets configuration
read_budgets() {
  ensure_data_dirs

  if [[ -f "$BUDGETS_FILE" ]]; then
    cat "$BUDGETS_FILE"
  else
    # Default budgets structure
    echo '{
      "session": null,
      "daily": null,
      "monthly": null,
      "project": {}
    }'
  fi
}

# Write budgets configuration
write_budgets() {
  local data="$1"

  ensure_data_dirs

  local tmp_file="${BUDGETS_FILE}.tmp.$$"
  echo "$data" > "$tmp_file"
  mv "$tmp_file" "$BUDGETS_FILE"
}

# Update budgets with jq expression
update_budgets() {
  local jq_expr="$1"

  local current_data
  current_data=$(read_budgets)

  local updated_data
  updated_data=$(echo "$current_data" | jq "$jq_expr")

  write_budgets "$updated_data"
}

# Read history data
read_history() {
  ensure_data_dirs

  if [[ -f "$HISTORY_FILE" ]]; then
    cat "$HISTORY_FILE"
  else
    echo '{
      "daily": {},
      "monthly": {},
      "all_time": 0
    }'
  fi
}

# Write history data
write_history() {
  local data="$1"

  ensure_data_dirs

  local tmp_file="${HISTORY_FILE}.tmp.$$"
  echo "$data" > "$tmp_file"
  mv "$tmp_file" "$HISTORY_FILE"
}

# Update history with jq expression
update_history() {
  local jq_expr="$1"

  local current_data
  current_data=$(read_history)

  local updated_data
  updated_data=$(echo "$current_data" | jq "$jq_expr")

  write_history "$updated_data"
}

# Add cost to daily/monthly history
add_to_history() {
  local cost="$1"
  local today
  local month
  today=$(date +%Y-%m-%d)
  month=$(date +%Y-%m)

  update_history "
    .daily[\"$today\"] = ((.daily[\"$today\"] // 0) + $cost) |
    .monthly[\"$month\"] = ((.monthly[\"$month\"] // 0) + $cost) |
    .all_time = ((.all_time // 0) + $cost)
  "
}

# Get today's spending
get_daily_spent() {
  local today
  today=$(date +%Y-%m-%d)

  local history
  history=$(read_history)

  echo "$history" | jq -r ".daily[\"$today\"] // 0"
}

# Get this month's spending
get_monthly_spent() {
  local month
  month=$(date +%Y-%m)

  local history
  history=$(read_history)

  echo "$history" | jq -r ".monthly[\"$month\"] // 0"
}

# Clean up old session files (keep last 30 days)
cleanup_old_sessions() {
  find "$SESSIONS_DIR" -name "*.json" -mtime +30 -delete 2>/dev/null || true
}

# Get all session files for a time period
get_sessions_for_period() {
  local period="$1"  # day, week, month
  local days

  case "$period" in
    day) days=1 ;;
    week) days=7 ;;
    month) days=30 ;;
    *) days=1 ;;
  esac

  find "$SESSIONS_DIR" -name "*.json" -mtime -"$days" -type f 2>/dev/null | grep -v current.json || true
}

# Calculate total cost for a period
get_period_total() {
  local period="$1"
  local total=0

  local sessions
  sessions=$(get_sessions_for_period "$period")

  for session_file in $sessions; do
    if [[ -f "$session_file" ]]; then
      local session_cost
      session_cost=$(jq -r '.costs.total // 0' "$session_file" 2>/dev/null || echo "0")
      total=$(echo "scale=6; $total + $session_cost" | bc)
    fi
  done

  echo "$total"
}
