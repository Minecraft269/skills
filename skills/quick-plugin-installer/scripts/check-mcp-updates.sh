#!/bin/bash
# 检查已安装的 MCP Server 是否有新版本
# 用法: ./check-mcp-updates.sh [server-name]
# 不指定名称则检查所有已安装的 MCP Server

set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "❌ 未找到 settings.json，请先安装 MCP Server"
  exit 1
fi

# 列出所有已安装的 MCP Server
list_servers() {
  jq -r '.mcpServers // {} | keys[]' "$SETTINGS_FILE" 2>/dev/null
}

# 提取第一个非选项参数作为包名
extract_pkg() {
  local args="$1"
  for arg in $args; do
    if [[ "$arg" != -* ]]; then
      echo "$arg"
      return
    fi
  done
}

# 跨平台超时命令
safe_timeout() {
  if command -v timeout &>/dev/null; then
    timeout "$@"
  else
    # Windows Git Bash / 无 timeout 时的回退
    "$@"
  fi
}

# 检查 npm 包的最新版本
check_npm_update() {
  local pkg="$1"
  local latest

  # 尝试获取本地已安装版本
  local current
  current=$(npm list -g "$pkg" --depth=0 2>/dev/null | grep "$pkg@" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")

  # 查询 npm registry 最新版本
  latest=$(safe_timeout 10 npm view "$pkg" version 2>/dev/null || echo "")
  if [ -z "$latest" ]; then
    echo "  ⚠️ 无法查询 npm 上的最新版本"
    return
  fi

  if [ "$current" != "unknown" ] && [ "$current" != "$latest" ]; then
    echo "  🔄 新版本可用: $latest (当前: $current)"
    echo "  📝 更新命令: npm install -g $pkg@latest"
  elif [ "$current" != "unknown" ]; then
    echo "  ✅ 已是最新版本 ($current)"
  else
    echo "  📦 最新版本: $latest"
    echo "  📝 安装命令: npm install -g $pkg@latest"
  fi
}

echo "🔍 检查 MCP Server 更新..."
echo ""

TARGET="${1:-}"
COUNT=0

while IFS= read -r server; do
  if [ -n "$TARGET" ] && [ "$server" != "$TARGET" ]; then
    continue
  fi
  COUNT=$((COUNT + 1))
  echo "📦 $server"

  # 使用 --arg 安全传递变量到 jq
  cmd=$(jq -r --arg s "$server" '.mcpServers[$s].command // empty' "$SETTINGS_FILE")
  args=$(jq -r --arg s "$server" '.mcpServers[$s].args // [] | join(" ")' "$SETTINGS_FILE")

  if echo "$cmd" | grep -qE 'npx|npm'; then
    pkg=$(extract_pkg "$args")
    if [ -n "$pkg" ] && [ "$pkg" != "$cmd" ]; then
      echo "  类型: npm"
      echo "  包名: $pkg"
      check_npm_update "$pkg"
    else
      echo "  类型: npm (无法提取包名，跳过)"
    fi
  elif echo "$cmd" | grep -qE 'uvx|pip|pip3'; then
    echo "  类型: Python"
    echo "  ⚠️ Python 包更新检查暂不支持，请手动检查"
  elif echo "$cmd" | grep -qE 'docker|podman'; then
    echo "  类型: 容器"
    echo "  ⚠️ 容器镜像更新检查暂不支持，请手动拉取"
  else
    echo "  类型: 本地命令 ($cmd)"
    echo "  ⚠️ 本地命令无法自动检查更新"
  fi
  echo ""
done < <(list_servers)

if [ "$COUNT" -eq 0 ]; then
  if [ -n "$TARGET" ]; then
    echo "❌ 未找到 MCP Server: $TARGET"
  else
    echo "📭 没有已安装的 MCP Server"
  fi
fi
