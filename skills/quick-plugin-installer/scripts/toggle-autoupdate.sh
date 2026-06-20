#!/bin/bash
# 切换 known_marketplaces.json 中指定来源的 autoUpdate 状态
# 用法: ./toggle-autoupdate.sh <source-url-pattern> [on|off]
# pattern 为子串匹配（不区分大小写），匹配多个时会列出并请求确认

set -euo pipefail

MARKETPLACES_FILE="$HOME/.claude/known_marketplaces.json"

if [ ! -f "$MARKETPLACES_FILE" ]; then
  echo "❌ 未找到 known_marketplaces.json，请先注册 Marketplace"
  exit 1
fi

PATTERN="${1:-}"
ACTION="${2:-}"

# 显示当前状态（无参数时）
if [ -z "$PATTERN" ]; then
  echo "用法: $0 <source-url-pattern> [on|off]"
  echo ""
  echo "当前所有 Marketplace 的 autoUpdate 状态："
  jq -r '.[] | "  \(.source // "unknown"): autoUpdate = \(.autoUpdate // false)"' "$MARKETPLACES_FILE"
  exit 0
fi

# 输入验证：拒绝过长的模式
if [ ${#PATTERN} -gt 200 ]; then
  echo "❌ 匹配模式过长（超过 200 字符）"
  exit 1
fi

# 使用 --arg 安全传递变量到 jq（防止 jq 注入）
MATCHES=$(jq -r --arg pattern "$PATTERN" '.[] | select(.source | contains($pattern)) | .source' "$MARKETPLACES_FILE")
MATCH_COUNT=$(echo "$MATCHES" | grep -c . || true)

if [ -z "$MATCHES" ] || [ "$MATCH_COUNT" -eq 0 ]; then
  echo "❌ 未找到匹配 '$PATTERN' 的 Marketplace"
  exit 1
fi

# 多匹配时列出并确认
if [ "$MATCH_COUNT" -gt 1 ]; then
  echo "⚠️ 匹配到 $MATCH_COUNT 个 Marketplace："
  echo "$MATCHES" | while IFS= read -r line; do
    CURRENT=$(jq -r --arg pattern "$line" '.[] | select(.source == $pattern) | .autoUpdate // false' "$MARKETPLACES_FILE")
    echo "  - $line (autoUpdate: $CURRENT)"
  done
  echo ""
  if [ -z "$ACTION" ]; then
    echo "请指定操作: $0 '$PATTERN' on  或  $0 '$PATTERN' off"
    echo "💡 提示：使用更精确的模式来匹配单个 Marketplace"
    exit 1
  fi
  echo "将对以上 $MATCH_COUNT 个 Marketplace 执行操作..."
fi

# 跨平台临时文件（Windows 无 mktemp 时回退）
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
      trap - EXIT  # 文件已成功移动，取消 cleanup
      echo "✅ autoUpdate 已启用（匹配 $MATCH_COUNT 个 Marketplace）"
    else
      cleanup
      echo "❌ jq 处理失败，原文件未修改"
      exit 1
    fi
    ;;
  off|false|disable)
    if jq --arg pattern "$PATTERN" \
      'map(if .source | contains($pattern) then .autoUpdate = false else . end)' \
      "$MARKETPLACES_FILE" > "$tmpfile"; then
      mv "$tmpfile" "$MARKETPLACES_FILE"
      trap - EXIT
      echo "✅ autoUpdate 已禁用（匹配 $MATCH_COUNT 个 Marketplace）"
    else
      cleanup
      echo "❌ jq 处理失败，原文件未修改"
      exit 1
    fi
    ;;
  *)
    # 仅显示状态
    echo "📋 当前 autoUpdate 状态："
    echo "$MATCHES" | while IFS= read -r line; do
      CURRENT=$(jq -r --arg pattern "$line" '.[] | select(.source == $pattern) | .autoUpdate // false' "$MARKETPLACES_FILE")
      echo "  $line: autoUpdate = $CURRENT"
    done
    echo ""
    echo "可用操作: $0 '$PATTERN' on  或  $0 '$PATTERN' off"
    ;;
esac
