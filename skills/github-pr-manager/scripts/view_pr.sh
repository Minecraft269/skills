#!/usr/bin/env bash
set -euo pipefail
show_help() { echo "用法: ./view_pr.sh <owner/repo|.> <PR> [-v] [-d] [-a]"; echo "  -v 展开审查/评论  -d 显示diff  -a 全部提交"; exit 0; }
VERBOSE=false; SHOW_DIFF=false; ALL_COMMITS=false
REPO_ARG=""; PR_ARG=""
for a in "$@"; do
    case "$a" in
        -h|--help)    show_help ;;
        -v|--verbose) VERBOSE=true ;;
        -d|--diff)    SHOW_DIFF=true ;;
        -a|--all)     ALL_COMMITS=true ;;
        *) [ -z "$REPO_ARG" ] && { REPO_ARG="$a"; continue; }
           [ -z "$PR_ARG" ]   && { PR_ARG="$a"; continue; }
           { echo "❌ 未知参数: $a"; exit 1; } ;;
    esac
done
REPO="${REPO_ARG:?owner/repo or .}"; PR="${PR_ARG:?PR number}"
[[ "$PR" =~ ^[0-9]+$ ]] || { echo "❌ PR 编号必须为数字"; exit 1; }
if [ "$REPO" = "." ]; then
    git remote get-url origin &>/dev/null || { echo "❌ 未找到 origin"; exit 1; }
    REPO=$(git remote get-url origin 2>/dev/null | sed -E 's|\.git$||; s|.*[:/]([^/]+/[^/]+)$|\1|')
    [ -z "$REPO" ] && { echo "❌ 无法推断仓库"; exit 1; }
    echo "📁 $REPO"
fi
command -v gh &>/dev/null || { echo "❌ 需要 gh"; exit 1; }
command -v jq &>/dev/null || { echo "❌ 需要 jq"; exit 1; }
gh auth status &>/dev/null || { echo "❌ 请 gh auth login"; exit 1; }
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
DATA=$(gh pr view "$PR" --repo "$REPO" --json title,body,author,state,mergeable,changedFiles,url,headRefName,baseRefName,createdAt,labels,reviews,comments,commits 2>"$tmp") || true
if [ -z "$DATA" ]; then
    echo "❌ 无法获取 PR $PR"
    [ -s "$tmp" ] && sed 's/^/   /' "$tmp"
    exit 1
fi
H="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section() { echo ""; echo "$H"; echo "$1"; echo "$H"; }
echo ""; echo "$H"; echo "📌 PR #$PR ($REPO)"; echo "$H"
pf() { jq -r "$1" <<< "$DATA"; }
section "📋 基本信息"
pf '"标题:       " + (.title // "N/A")'
pf '"作者:       @" + (.author.login // "unknown")'
pf '"状态:       " + (.state // "?") + " | 合并: " + (.mergeable // "?")'
pf '"分支:       " + (.headRefName // "?") + " → " + (.baseRefName // "?")'
pf '"创建:       " + (.createdAt[:10] // "?")'
pf '"标签:       " + (if (.labels|length)>0 then [.labels[].name]|join(", ") else "无" end)'
pf '"文件:       " + (.changedFiles|tostring) + " 个"'
pf '"链接:       " + (.url // "")'
section "📝 PR 描述"
BODY=$(jq -r '.body // ""' <<< "$DATA")
if [ -n "$BODY" ]; then
    L=${#BODY}
    if [ "$L" -gt 600 ]; then printf '%s\n' "${BODY:0:600}"; echo ""; echo "... ($L chars)"; else printf '%s\n' "$BODY"; fi
else echo "  (无)"; fi
section "📊 Diff"
if $SHOW_DIFF; then
    if D=$(gh pr diff "$PR" --repo "$REPO" 2>"$tmp"); then
        if [ -n "$D" ]; then
            printf '%s\n' "$D" | head -n 200
            N=$(printf '%s\n' "$D" | wc -l | tr -d ' ')
            [ "$N" -gt 200 ] && echo "" && echo "... (共 $N 行，仅显示前 200)"
        else echo "  (无变更)"; fi
    else
        echo "  ⚠️  获取失败:"; [ -s "$tmp" ] && sed 's/^/  /' "$tmp"
    fi
else
    echo "  (使用 -d 查看代码变更)"
fi
section "💬 审查"
R=$(jq '(.reviews // []) | length' <<< "$DATA")
if [ "$R" -gt 0 ]; then
    echo "共 $R 条 (使用 -v 查看完整内容):"
    if $VERBOSE; then
        jq -r '.reviews[]|"\n  @"+(.author.login//"?")+" ["+.state+"] ("+.submittedAt[:10]+")\n  "+(.body//"(无)")' <<< "$DATA"
    else
        jq -r '.reviews[]|"  @"+(.author.login//"unknown")+" ["+.state+"] ("+.submittedAt[:10]+"): " + (if (.body//"")=="" then "(无)" else "\""+.body[:200]+(if (.body|length)>200 then "…" else "" end)+"\"" end)' <<< "$DATA"
    fi
else echo "  (无)"; fi
section "💬 评论"
C=$(jq '(.comments // []) | length' <<< "$DATA")
if [ "$C" -gt 0 ]; then
    echo "共 $C 条 (使用 -v 查看完整内容):"
    if $VERBOSE; then
        jq -r '.comments[]|"\n  @"+(.author.login//"?")+" ("+.createdAt[:10]+")\n  "+(.body//"(无)")' <<< "$DATA"
    else
        jq -r '.comments[]|"  @"+(.author.login//"unknown")+" ("+.createdAt[:10]+"): " + (if (.body//"")=="" then "(无)" else "\""+.body[:200]+(if (.body|length)>200 then "…" else "" end)+"\"" end)' <<< "$DATA"
    fi
else echo "  (无)"; fi
section "📜 提交"
M=$(jq '(.commits // []) | length' <<< "$DATA")
if [ "$M" -gt 0 ]; then
    if $ALL_COMMITS; then
        echo "共 $M 次 (按时间倒序):"
        jq -r '.commits|sort_by(.committedDate // .authoredDate // "1970")|reverse|.[]|"  "+.oid[:7]+"  "+(.author.name//.author.login//"?")+"  "+.messageHeadline' <<< "$DATA"
    else
        LIMIT=$M; [ "$LIMIT" -gt 10 ] && LIMIT=10
        echo "共 $M 次 (显示最近 $LIMIT，-a 查看全部):"
        jq -r --arg L "$LIMIT" '.commits|sort_by(.committedDate // .authoredDate // "1970")|reverse|.[0:($L|tonumber)]|.[]|"  "+.oid[:7]+"  "+(.author.name//.author.login//"?")+"  "+.messageHeadline' <<< "$DATA"
    fi
else echo "  (无)"; fi
echo ""; echo "$H"
