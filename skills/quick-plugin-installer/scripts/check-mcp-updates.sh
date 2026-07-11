#!/bin/bash
# Check if installed MCP Servers have new versions
# Usage: ./check-mcp-updates.sh [server-name]
# Without a server name, checks all installed MCP Servers

set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "❌ settings.json not found, please install MCP Server first"
  exit 1
fi

# List all installed MCP Servers
list_servers() {
  jq -r '.mcpServers // {} | keys[]' "$SETTINGS_FILE" 2>/dev/null
}

# Extract the first non-option argument as package name
extract_pkg() {
  local args="$1"
  for arg in $args; do
    if [[ "$arg" != -* ]]; then
      echo "$arg"
      return
    fi
  done
}

# Cross-platform timeout command
safe_timeout() {
  if command -v timeout &>/dev/null; then
    timeout "$@"
  else
    # Windows Git Bash / fallback when timeout is unavailable
    "$@"
  fi
}

# Check npm package for latest version
check_npm_update() {
  local pkg="$1"
  local latest

  # Validate package name format (only npm-legal characters)
  [[ "$pkg" =~ ^@?[a-zA-Z0-9_.-]+(/[a-zA-Z0-9_.-]+)?$ ]] || { echo "  ⚠️  Package name format is unusual, skipping"; return; }
  # Try to get locally installed version
  local current
  current=$(npm list -g -- "$pkg" --depth=0 2>/dev/null | grep "$pkg@" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")

  # Query npm registry for latest version
  latest=$(safe_timeout 10 npm view "$pkg" version 2>/dev/null || echo "")
  if [ -z "$latest" ]; then
    echo "  ⚠️ Unable to query latest version on npm"
    return
  fi

  if [ "$current" != "unknown" ] && [ "$current" != "$latest" ]; then
    echo "  🔄 New version available: $latest (current: $current)"
    echo "  📝 Update command: npm install -g $pkg@latest"
  elif [ "$current" != "unknown" ]; then
    echo "  ✅ Already at latest version ($current)"
  else
    echo "  📦 Latest version: $latest"
    echo "  📝 Install command: npm install -g $pkg@latest"
  fi
}

echo "🔍 Checking MCP Server updates..."
echo ""

TARGET="${1:-}"
COUNT=0

while IFS= read -r server; do
  if [ -n "$TARGET" ] && [ "$server" != "$TARGET" ]; then
    continue
  fi
  COUNT=$((COUNT + 1))
  echo "📦 $server"

  # Use --arg to safely pass variable to jq
  cmd=$(jq -r --arg s "$server" '.mcpServers[$s].command // empty' "$SETTINGS_FILE")
  args=$(jq -r --arg s "$server" '.mcpServers[$s].args // [] | join(" ")' "$SETTINGS_FILE")

  if echo "$cmd" | grep -qE 'npx|npm'; then
    pkg=$(extract_pkg "$args")
    if [ -n "$pkg" ] && [ "$pkg" != "$cmd" ]; then
      echo "  Type: npm"
      echo "  Package: $pkg"
      check_npm_update "$pkg"
    else
      echo "  Type: npm (unable to extract package name, skipping)"
    fi
  elif echo "$cmd" | grep -qE 'uvx|pip|pip3'; then
    echo "  Type: Python"
    echo "  ⚠️ Python package update check not yet supported, please check manually"
  elif echo "$cmd" | grep -qE 'docker|podman'; then
    echo "  Type: Container"
    echo "  ⚠️ Container image update check not yet supported, please pull manually"
  else
    echo "  Type: Local command ($cmd)"
    echo "  ⚠️ Local commands cannot be automatically checked for updates"
  fi
  echo ""
done < <(list_servers)

if [ "$COUNT" -eq 0 ]; then
  if [ -n "$TARGET" ]; then
    echo "❌ MCP Server not found: $TARGET"
  else
    echo "📭 No MCP Servers installed"
  fi
fi
