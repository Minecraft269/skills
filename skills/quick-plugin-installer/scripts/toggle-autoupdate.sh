#!/bin/bash
# Toggle the autoUpdate status for a given source in known_marketplaces.json
# Usage: ./toggle-autoupdate.sh <source-url-pattern> [on|off]
# Pattern is substring matched (case-insensitive), lists and confirms when multiple matches found

set -euo pipefail

MARKETPLACES_FILE="$HOME/.claude/known_marketplaces.json"

if [ ! -f "$MARKETPLACES_FILE" ]; then
  echo "❌ known_marketplaces.json not found, please register a Marketplace first"
  exit 1
fi

PATTERN="${1:-}"
ACTION="${2:-}"

# Show current state (no arguments)
if [ -z "$PATTERN" ]; then
  echo "Usage: $0 <source-url-pattern> [on|off]"
  echo ""
  echo "Current autoUpdate status for all Marketplaces:"
  jq -r '.[] | "  \(.source // "unknown"): autoUpdate = \(.autoUpdate // false)"' "$MARKETPLACES_FILE"
  exit 0
fi

# Input validation: reject overly long patterns
if [ ${#PATTERN} -gt 200 ]; then
  echo "❌ Pattern too long (exceeds 200 characters)"
  exit 1
fi

# Use --arg to safely pass variables to jq (prevents jq injection)
MATCHES=$(jq -r --arg pattern "$PATTERN" '.[] | select(.source | contains($pattern)) | .source' "$MARKETPLACES_FILE")
MATCH_COUNT=$(echo "$MATCHES" | grep -c . || true)

if [ -z "$MATCHES" ] || [ "$MATCH_COUNT" -eq 0 ]; then
  echo "❌ No Marketplace matching '$PATTERN' found"
  exit 1
fi

# List and confirm when multiple matches
if [ "$MATCH_COUNT" -gt 1 ]; then
  echo "⚠️  Matched $MATCH_COUNT Marketplaces:"
  echo "$MATCHES" | while IFS= read -r line; do
    CURRENT=$(jq -r --arg pattern "$line" '.[] | select(.source == $pattern) | .autoUpdate // false' "$MARKETPLACES_FILE")
    echo "  - $line (autoUpdate: $CURRENT)"
  done
  echo ""
  if [ -z "$ACTION" ]; then
    echo "Please specify an action: $0 '$PATTERN' on   or  $0 '$PATTERN' off"
    echo "💡 Hint: use a more precise pattern to match a single Marketplace"
    exit 1
  fi
  echo "Will apply the operation to the above $MATCH_COUNT Marketplaces..."
fi

# Cross-platform temp file (fallback when Windows lacks mktemp)
if command -v mktemp &>/dev/null; then
  tmpfile=$(mktemp "${MARKETPLACES_FILE}.XXXXXXXX")
else
  tmpfile="${MARKETPLACES_FILE}.tmp.$$"
fi
cleanup() {
  rm -f "$tmpfile"
}
trap cleanup EXIT

case "$ACTION" in
  on|true|enable)
    if jq --arg pattern "$PATTERN" \
      'map(if .source | contains($pattern) then .autoUpdate = true else . end)' \
      "$MARKETPLACES_FILE" > "$tmpfile"; then
      mv "$tmpfile" "$MARKETPLACES_FILE"
      trap - EXIT  # File moved successfully, cancel cleanup
      echo "✅ autoUpdate enabled (matched $MATCH_COUNT Marketplaces)"
    else
      cleanup
      echo "❌ jq processing failed, original file unchanged"
      exit 1
    fi
    ;;
  off|false|disable)
    if jq --arg pattern "$PATTERN" \
      'map(if .source | contains($pattern) then .autoUpdate = false else . end)' \
      "$MARKETPLACES_FILE" > "$tmpfile"; then
      mv "$tmpfile" "$MARKETPLACES_FILE"
      trap - EXIT
      echo "✅ autoUpdate disabled (matched $MATCH_COUNT Marketplaces)"
    else
      cleanup
      echo "❌ jq processing failed, original file unchanged"
      exit 1
    fi
    ;;
  *)
    # Show status only
    echo "📋 Current autoUpdate status:"
    echo "$MATCHES" | while IFS= read -r line; do
      CURRENT=$(jq -r --arg pattern "$line" '.[] | select(.source == $pattern) | .autoUpdate // false' "$MARKETPLACES_FILE")
      echo "  $line: autoUpdate = $CURRENT"
    done
    echo ""
    echo "Available actions: $0 '$PATTERN' on   or  $0 '$PATTERN' off"
    ;;
esac
