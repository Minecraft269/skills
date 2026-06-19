#!/usr/bin/env bash
# list_prs.sh — 列出 GitHub 仓库开放 PR 并格式化输出
# 兼容: Git Bash (Windows), WSL2, macOS, Linux
# 用法: ./list_prs.sh <owner/repo> [limit] [-a|--all]

set -euo pipefail

# ============================================================================
# 参数解析
# ============================================================================
PAGINATE=false
ARGS=()

for arg in "$@"; do
    case "$arg" in
        -a|--all) PAGINATE=true ;;
        -h|--help) echo "用法: ./list_prs.sh <owner/repo> [limit] [-a|--all]"; echo "  -a  翻页获取全部PR"; exit 0 ;;
        *) ARGS+=("$arg") ;;
    esac
done

REPO="${ARGS[0]:?请提供仓库 (owner/repo)}"
LIMIT="${ARGS[1]:-1000}"

# ============================================================================
# 依赖检查
# ============================================================================
for cmd in gh jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ 缺少必要命令: $cmd，请安装后重试。"
        exit 1
    fi
done

# 认证检查（仅依赖退出码，语言无关）
if ! gh auth status &>/dev/null; then
    echo "❌ GitHub CLI 未登录，请执行: gh auth login"
    exit 1
fi

# 仓库格式校验
if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo "❌ 仓库格式错误，应为 owner/repo（如 facebook/react）"
    exit 1
fi

# ============================================================================
# 获取 PR 数据
# ============================================================================

if $PAGINATE; then
    # ── 翻页模式：使用 gh api --paginate 获取全部 PR ──
    echo "⏳ 正在获取全部开放 PR（大仓库可能较慢）..."

    OWNER="${REPO%/*}"
    REPO_NAME="${REPO#*/}"

    PRS_JSON=$(gh api --paginate \
        "repos/${OWNER}/${REPO_NAME}/pulls?state=open&per_page=100" \
        --jq '[.[] | {number, title, user: {login: .user.login}, created_at}]' 2>&1) || {
        echo "❌ 获取 PR 列表失败"
        printf '%s\n' "$PRS_JSON"
        exit 1
    }

    # 统一字段名以匹配后续 jq 处理
    PRS_JSON=$(printf '%s\n' "$PRS_JSON" | jq '[.[] | {number, title, author: {login: .user.login}, createdAt: .created_at}]')
else
    # ── 标准模式：使用 gh pr list（快速） ──
    # LIMIT 范围校验
    if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [ "$LIMIT" -lt 1 ] || [ "$LIMIT" -gt 1000 ]; then
        echo "❌ LIMIT 应为 1-1000 的整数"
        exit 1
    fi

    PRS_JSON=$(gh pr list --repo "$REPO" --state open \
        --json number,title,author,createdAt \
        --limit "$LIMIT" 2>&1) || {
        echo "❌ 获取 PR 列表失败"
        printf '%s\n' "$PRS_JSON"
        exit 1
    }
fi

# ============================================================================
# 解析计数
# ============================================================================
PR_COUNT=$(printf '%s\n' "$PRS_JSON" | jq 'length') || {
    echo "⚠️  解析 PR 列表失败，原始返回："
    printf '%s\n' "$PRS_JSON" | head -n 5
    exit 1
}

if [ "$PR_COUNT" -eq 0 ]; then
    echo "📋 仓库: ${REPO} | 当前没有开放的 PR"
    exit 0
fi

# ============================================================================
# 输出
# ============================================================================

if $PAGINATE; then
    echo "📋 仓库: ${REPO} | 全部开放 PR"
else
    echo "📋 仓库: ${REPO} | 开放 PR 列表"
    if [ "$PR_COUNT" -ge "$LIMIT" ]; then
        echo "   （结果可能被截断，使用 -a 获取全部 PR）"
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 格式化输出（| 分隔，标题中 | 替换为 ¦ 避免冲突）
FORMATTED=$(printf '%s\n' "$PRS_JSON" | jq -r '.[] | [
    "  #\(.number)",
    (if (.title | length) > 60 then (.title[:60] | gsub("\\|"; "¦")) + "…" else (.title | gsub("\\|"; "¦")) end),
    "@\(.author.login // "unknown")",
    .createdAt[:10]
] | join("|")')

if command -v column &>/dev/null; then
    printf '%s\n' "$FORMATTED" | column -t -s '|'
else
    printf '%s\n' "$FORMATTED" | tr '|' '\t'
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "共 ${PR_COUNT} 个开放 PR"
