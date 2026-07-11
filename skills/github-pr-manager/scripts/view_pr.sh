#!/usr/bin/env bash
set -euo pipefail
show_help() { echo "Usage: ./view_pr.sh <owner/repo|.> <PR> [-v] [-d] [-a]"; echo "  -v Expand reviews/comments  -d Show diff  -a All commits"; exit 0; }
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
           { echo "❌ Unknown argument: $a"; exit 1; } ;;
    esac
done
REPO="${REPO_ARG:?owner/repo or .}"; PR="${PR_ARG:?PR number}"
[[ "$PR" =~ ^[0-9]+$ ]] || { echo "❌ PR number must be numeric"; exit 1; }
if [ "$REPO" = "." ]; then
    git remote get-url origin &>/dev/null || { echo "❌ origin not found"; exit 1; }
    REPO=$(git remote get-url origin 2>/dev/null | sed -E 's|\.git$||; s|.*[:/]([^/]+/[^/]+)$|\1|')
    [ -z "$REPO" ] && { echo "❌ Unable to infer repository"; exit 1; }
    echo "📁 $REPO"
fi
# Validate repository format owner/repo (guard against argument injection)
[[ "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]] || { echo "❌ Repository format must be owner/repo"; exit 1; }
command -v gh &>/dev/null || { echo "❌ gh is required"; exit 1; }
command -v jq &>/dev/null || { echo "❌ jq is required"; exit 1; }
gh auth status &>/dev/null || { echo "❌ Run gh auth login first"; exit 1; }
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
DATA=$(gh pr view "$PR" --repo "$REPO" --json title,body,author,state,mergeable,changedFiles,url,headRefName,baseRefName,createdAt,labels,reviews,comments,commits 2>"$tmp") || true
if [ -z "$DATA" ]; then
    echo "❌ Unable to fetch PR $PR"
    [ -s "$tmp" ] && sed 's/^/   /' "$tmp"
    exit 1
fi
H="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section() { echo ""; echo "$H"; echo "$1"; echo "$H"; }
echo ""; echo "$H"; echo "📌 PR #$PR ($REPO)"; echo "$H"
pf() { jq -r "$1" <<< "$DATA"; }
section "📋 Basic info"
pf '"Title:      " + (.title // "N/A")'
pf '"Author:     @" + (.author.login // "unknown")'
pf '"State:      " + (.state // "?") + " | Mergeable: " + (.mergeable // "?")'
pf '"Branch:     " + (.headRefName // "?") + " -> " + (.baseRefName // "?")'
pf '"Created:    " + (.createdAt[:10] // "?")'
pf '"Labels:     " + (if (.labels|length)>0 then [.labels[].name]|join(", ") else "(none)" end)'
pf '"Files:      " + (.changedFiles|tostring) + " files"'
pf '"URL:        " + (.url // "")'
section "📝 Description"
BODY=$(jq -r '.body // ""' <<< "$DATA")
if [ -n "$BODY" ]; then
    L=${#BODY}
    if [ "$L" -gt 600 ]; then printf '%s\n' "${BODY:0:600}"; echo ""; echo "... ($L chars)"; else printf '%s\n' "$BODY"; fi
else echo "  (none)"; fi
section "📊 Diff"
if $SHOW_DIFF; then
    if D=$(gh pr diff "$PR" --repo "$REPO" 2>"$tmp"); then
        if [ -n "$D" ]; then
            printf '%s\n' "$D" | head -n 200
            N=$(printf '%s\n' "$D" | wc -l | tr -d ' ')
            [ "$N" -gt 200 ] && echo "" && echo "... ($N lines total, showing first 200)"
        else echo "  (no changes)"; fi
    else
        echo "  ⚠️  Fetch failed:"; [ -s "$tmp" ] && sed 's/^/  /' "$tmp"
    fi
else
    echo "  (Use -d to view code changes)"
fi
section "💬 Reviews"
R=$(jq '(.reviews // []) | length' <<< "$DATA")
if [ "$R" -gt 0 ]; then
    echo "$R total (use -v to see full content):"
    if $VERBOSE; then
        jq -r '.reviews[]|"\n  @"+(.author.login//"?")+" ["+.state+"] ("+.submittedAt[:10]+")\n  "+(.body//"(none)")' <<< "$DATA"
    else
        jq -r '.reviews[]|"  @"+(.author.login//"unknown")+" ["+.state+"] ("+.submittedAt[:10]+"): " + (if (.body//"")=="" then "(none)" else "\""+.body[:200]+(if (.body|length)>200 then "…" else "" end)+"\"" end)' <<< "$DATA"
    fi
else echo "  (none)"; fi
section "💬 Comments"
C=$(jq '(.comments // []) | length' <<< "$DATA")
if [ "$C" -gt 0 ]; then
    echo "$C total (use -v to see full content):"
    if $VERBOSE; then
        jq -r '.comments[]|"\n  @"+(.author.login//"?")+" ("+.createdAt[:10]+")\n  "+(.body//"(none)")' <<< "$DATA"
    else
        jq -r '.comments[]|"  @"+(.author.login//"unknown")+" ("+.createdAt[:10]+"): " + (if (.body//"")=="" then "(none)" else "\""+.body[:200]+(if (.body|length)>200 then "…" else "" end)+"\"" end)' <<< "$DATA"
    fi
else echo "  (none)"; fi
section "📜 Commits"
M=$(jq '(.commits // []) | length' <<< "$DATA")
if [ "$M" -gt 0 ]; then
    if $ALL_COMMITS; then
        echo "$M total (reverse chronological):"
        jq -r '.commits|sort_by(.committedDate // .authoredDate // "1970")|reverse|.[]|"  "+.oid[:7]+"  "+(.author.name//.author.login//"?")+"  "+.messageHeadline' <<< "$DATA"
    else
        LIMIT=$M; [ "$LIMIT" -gt 10 ] && LIMIT=10
        echo "$M total (showing last $LIMIT, -a for all):"
        jq -r --arg L "$LIMIT" '.commits|sort_by(.committedDate // .authoredDate // "1970")|reverse|.[0:($L|tonumber)]|.[]|"  "+.oid[:7]+"  "+(.author.name//.author.login//"?")+"  "+.messageHeadline' <<< "$DATA"
    fi
else echo "  (none)"; fi
echo ""; echo "$H"
