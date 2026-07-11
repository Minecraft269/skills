#!/usr/bin/env bash
# list_prs.sh — List open PRs in a GitHub repository with formatted output
# Compatibility: Git Bash (Windows), WSL2, macOS, Linux
# Usage: ./list_prs.sh <owner/repo> [limit] [-a|--all]

set -euo pipefail

# ============================================================================
# Argument parsing
# ============================================================================
PAGINATE=false
ARGS=()

for arg in "$@"; do
    case "$arg" in
        -a|--all) PAGINATE=true ;;
        -h|--help) echo "Usage: ./list_prs.sh <owner/repo> [limit] [-a|--all]"; echo "  -a  Paginate to fetch all PRs"; exit 0 ;;
        *) ARGS+=("$arg") ;;
    esac
done

REPO="${ARGS[0]:?Please provide repository (owner/repo)}"
LIMIT="${ARGS[1]:-1000}"

# ============================================================================
# Dependency check
# ============================================================================
for cmd in gh jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Missing required command: $cmd, please install and retry."
        exit 1
    fi
done

# Authentication check (relies only on exit code, language-agnostic)
if ! gh auth status &>/dev/null; then
    echo "❌ GitHub CLI not logged in, run: gh auth login"
    exit 1
fi

# Repository format validation
if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo "❌ Invalid repository format, should be owner/repo (e.g. facebook/react)"
    exit 1
fi

# ============================================================================
# Fetch PR data
# ============================================================================

if $PAGINATE; then
    # Pagination mode: use gh api --paginate to fetch all PRs
    echo "⏳ Fetching all open PRs (may be slow for large repositories)..."

    OWNER="${REPO%/*}"
    REPO_NAME="${REPO#*/}"

    PRS_JSON=$(gh api --paginate \
        "repos/${OWNER}/${REPO_NAME}/pulls?state=open&per_page=100" \
        --jq '[.[] | {number, title, user: {login: .user.login}, created_at}]' 2>&1) || {
        echo "❌ Failed to fetch PR list"
        printf '%s\n' "$PRS_JSON"
        exit 1
    }

    # Normalize field names to match subsequent jq processing
    PRS_JSON=$(printf '%s\n' "$PRS_JSON" | jq '[.[] | {number, title, author: {login: .user.login}, createdAt: .created_at}]')
else
    # Standard mode: use gh pr list (fast)
    # LIMIT range validation
    if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [ "$LIMIT" -lt 1 ] || [ "$LIMIT" -gt 1000 ]; then
        echo "❌ LIMIT must be an integer between 1 and 1000"
        exit 1
    fi

    PRS_JSON=$(gh pr list --repo "$REPO" --state open \
        --json number,title,author,createdAt \
        --limit "$LIMIT" 2>&1) || {
        echo "❌ Failed to fetch PR list"
        printf '%s\n' "$PRS_JSON"
        exit 1
    }
fi

# ============================================================================
# Parse count
# ============================================================================
PR_COUNT=$(printf '%s\n' "$PRS_JSON" | jq 'length') || {
    echo "⚠️  Failed to parse PR list, raw output:"
    printf '%s\n' "$PRS_JSON" | head -n 5
    exit 1
}

if [ "$PR_COUNT" -eq 0 ]; then
    echo "📋 Repository: ${REPO} | No open PRs currently"
    exit 0
fi

# ============================================================================
# Output
# ============================================================================

if $PAGINATE; then
    echo "📋 Repository: ${REPO} | All open PRs"
else
    echo "📋 Repository: ${REPO} | Open PR list"
    if [ "$PR_COUNT" -ge "$LIMIT" ]; then
        echo "   (Results may be truncated, use -a to fetch all PRs)"
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Formatted output (| separated, replace | with ¦ in titles to avoid conflict)
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
echo "Total: ${PR_COUNT} open PRs"
