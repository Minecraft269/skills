#!/usr/bin/env bash
# ci_pr.sh — PR CI status check + failure analysis + rerun + tracking
# Usage: ./ci_pr.sh <owner/repo|.> <PR> [options]
set -euo pipefail

if [ -t 1 ]; then
  RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BOLD='\033[1m'; OFF='\033[0m'
else RED=''; GREEN=''; YELLOW=''; BOLD=''; OFF=''; fi

show_help() {
  cat << 'HELP'
Usage: ./ci_pr.sh <owner/repo|.> <PR> [options]
  --log       Show full logs of failed jobs
  --analyze   Analyze failure reasons and suggest fixes
  --rerun     Rerun failed jobs
  --wait      Wait for rerun completion
  --json      Output raw CI checks JSON
  --exit-code Exit with code 1 if any failure
  --yes,-y    Skip rerun confirmation
  --verbose   Debug info
  -h,--help   Show this help
Environment variables:
  GH_REPO     Default repository (owner/repo)
  CI_PATTERNS Custom error pattern file path, one per line: regex|hint, # for comments
HELP
  exit 0
}

# Failed states: completed and not success/skipped
JQ_FAILED='select(.state == "FAILURE" or .state == "CANCELLED" or .state == "TIMED_OUT" or .state == "STARTUP_FAILURE" or .state == "ACTION_REQUIRED")'

ANALYZE=false; RERUN=false; SHOW_LOG=false; WAIT=false
VERBOSE=false; JSON_OUT=false; SKIP_CONFIRM=false; EXIT_CODE=false
REPO_ARG=""; PR_ARG=""
for a in "$@"; do
  case "$a" in
    -h|--help)   show_help ;;
    --analyze)   ANALYZE=true ;;
    --rerun)     RERUN=true ;;
    --log)       SHOW_LOG=true ;;
    --wait)      WAIT=true ;;
    --json)      JSON_OUT=true ;;
    --verbose)   VERBOSE=true ;;
    --exit-code) EXIT_CODE=true ;;
    -y|--yes)    SKIP_CONFIRM=true ;;
    *) [ -z "$REPO_ARG" ] && { REPO_ARG="$a"; continue; }
       [ -z "$PR_ARG" ]   && { PR_ARG="$a"; continue; }
       { echo "❌ Unknown argument: $a"; exit 1; } ;;
  esac
done
REPO="${REPO_ARG:-${GH_REPO:-}}"; PR="${PR_ARG:-}"
[ -z "$REPO" ] && { echo "❌ Missing repository argument"; exit 1; }
[ -z "$PR" ]   && { echo "❌ Missing PR number"; exit 1; }
[[ "$PR" =~ ^[0-9]+$ ]] || { echo "❌ PR number must be numeric"; exit 1; }
# Validate repository format (skip . inference)
[[ "$REPO" = "." || "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]] || { echo "❌ Repository format must be owner/repo"; exit 1; }
debug() { [ "$VERBOSE" = true ] && printf '%s\n' "[DEBUG] $*" >&2; }

# Repository inference
infer_repo() {
  for remote in origin upstream; do
    local url; url=$(git remote get-url "$remote" 2>/dev/null) || continue
    local repo; repo=$(echo "$url" | sed -E '
      s|^https?://[^/]+/||; s|^git@[^:]+:||;
      s|\.git$||; s|/$||; s|^.*[:/]([^/]+/[^/]+)$|\1|
    ')
    [ -n "$repo" ] && { echo "$repo"; return 0; }
  done; return 1
}
if [ "$REPO" = "." ]; then
  REPO=$(infer_repo) || { echo "❌ Unable to infer repository, provide owner/repo manually"; exit 1; }
  printf '%s\n' "📁 $REPO"
fi

command -v gh &>/dev/null || { echo "❌ gh is required"; exit 1; }
command -v jq &>/dev/null || { echo "❌ jq is required"; exit 1; }
JQ_VER=$(jq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0.0")
JQ_MAJOR=${JQ_VER%%.*}; JQ_MINOR=${JQ_VER##*.}
{ [ "$JQ_MAJOR" -lt 1 ] || { [ "$JQ_MAJOR" -eq 1 ] && [ "$JQ_MINOR" -lt 6 ]; }; } \
  && echo "⚠️  jq $JQ_VER may lack some features, recommend >= 1.6"
gh auth status &>/dev/null || { echo "❌ Run gh auth login first"; exit 1; }
debug "REPO=$REPO PR=$PR"

H="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
USE_JSON=true

echo ""; printf '%s\n' "${BOLD}$H${OFF}"
printf '%s\n' "${BOLD}🔄 CI Status — PR #$PR ($REPO)${OFF}"
printf '%s\n' "🔗 https://github.com/$REPO/pull/$PR"
printf '%s\n' "${BOLD}$H${OFF}"

CHECKS_TXT=$(gh pr checks "$PR" --repo "$REPO" 2>&1) || CHECKS_TXT=""
CHECKS_JSON=$(gh pr checks "$PR" --repo "$REPO" --json name,state,bucket,link,workflow,completedAt 2>/dev/null) || CHECKS_JSON=""

if $JSON_OUT && [ -n "$CHECKS_JSON" ]; then
  printf '%s\n' "$CHECKS_JSON"; exit 0
fi

if [ -z "$CHECKS_TXT" ] && [ -z "$CHECKS_JSON" ]; then
  printf '%s\n' "  (This PR has no CI checks configured)"; exit 0
fi

if [ -n "$CHECKS_JSON" ] && ! jq -e . >/dev/null 2>&1 <<< "$CHECKS_JSON"; then
  printf '%s\n' "⚠️  Invalid JSON data, falling back to text mode"; USE_JSON=false
fi
if $USE_JSON && [ "$CHECKS_JSON" = "[]" ]; then
  printf '%s\n' "⚠️  Unable to fetch JSON data, falling back to text mode"; USE_JSON=false
fi

if $USE_JSON; then
  TOTAL=$(jq 'length' <<< "$CHECKS_JSON")
  PASSED=$(jq '[.[] | select(.state == "SUCCESS")] | length' <<< "$CHECKS_JSON")
  FAILED=$(jq "[.[] | $JQ_FAILED] | length" <<< "$CHECKS_JSON")
  PENDING=$(jq '[.[] | select(.state | test("PENDING|IN_PROGRESS|QUEUED"))] | length' <<< "$CHECKS_JSON")
  printf '%s' "${BOLD}📊 Total $TOTAL  |  ${GREEN}✅ $PASSED passed${OFF}"
  printf '%s\n' "  |  ${RED}❌ $FAILED failed${OFF}  |  ${YELLOW}⏳ $PENDING pending${OFF}"
else
  PASSED=0; FAILED=0; TOTAL=0
  printf '%s\n' "⚠️  Text mode has limited features, jq recommended"
fi

printf '%s\n' "$CHECKS_TXT"; echo ""

get_failed_runs() {
  jq -c ".[] | $JQ_FAILED | {link: (.link // \"\"), name: .name}" <<< "$CHECKS_JSON" \
  | while IFS= read -r line; do
      local link; link=$(jq -r '.link // ""' <<< "$line")
      local name; name=$(jq -r '.name' <<< "$line")
      if [ -z "$link" ]; then
        printf '%s\n' "⚠️  \"$name\" has no associated workflow run, skipping" >&2; continue
      fi
      local rid; rid=$(echo "$link" | grep -Eo 'runs/[0-9]+' | cut -d/ -f2 || echo "")
      if [ -z "$rid" ]; then
        printf '%s\n' "⚠️  \"$name\" unable to parse run ID" >&2; continue
      fi
      printf '%s\t%s\n' "$rid" "$name"
    done | awk -F'\t' '!seen[$1]++'
}

lm() { grep -qiE "$1" <<< "$LOG" 2>/dev/null && return 0 || return 1; }
a() { ANALYSIS+="$1"$'\n'; }

if $ANALYZE && [ "${FAILED:-0}" != "0" ] && $USE_JSON; then
  echo ""; printf '%s\n' "${BOLD}$H${OFF}"
  printf '%s\n' "${BOLD}🔍 Failure Analysis${OFF}"; printf '%s\n' "${BOLD}$H${OFF}"
  echo "Failed jobs:"
  jq -r ".[] | $JQ_FAILED | \"  ❌ \(.name) [\(.state)]\"" <<< "$CHECKS_JSON"
  echo ""; echo "📋 Log analysis:"
  while IFS=$'\t' read -r run_id job_name; do
    ANALYSIS=""
    echo ""; echo "━━ $job_name (run $run_id) ━━"
    LOG=$(timeout 30 gh run view "$run_id" --repo "$REPO" --log-failed 2>/dev/null | tail -n 150) || LOG=""
    if [ -n "$LOG" ]; then
      printf '%s\n' "$LOG" | head -n 120
      if lm 'npm ERR!|error TS[0-9]+|Cannot find module'; then
        a "   → Node.js/TS build or dependency error"; a "     Run: npm ci && npm run build"
      fi
      if lm 'error\[E\d+\]|cargo build.*failed'; then
        a "   → Rust compilation error"; a "     Run: cargo check --all-features"
      fi
      if lm 'FAIL:|assertion|expected.*but got|Actual:'; then
        a "   → Test failure"; a "     Run: cargo test | npm test | pytest"
      fi
      if lm 'warning:.*clippy|prettier|eslint|format'; then
        a "   → Lint/format error"; a "     Run: cargo clippy | npm run lint"
      fi
      if lm 'timeout|timed out|connection refused|502|503|504'; then
        a "   → Network timeout or service unavailable"; a "     Suggestion: --rerun"
      fi
      if lm 'could not resolve|ModuleNotFoundError|ImportError'; then
        a "   → Dependency resolution failure"; a "     Suggestion: check dependency declarations and lock file"
      fi
      if lm 'docker build.*failed|manifest.*not found'; then
        a "   → Docker build error"; a "     Run: docker build ."
      fi
      if lm 'not set|required.*variable|variable.*missing'; then
        a "   → Missing environment variable"; a "     Suggestion: check CI secrets/variables"
      fi
      if lm 'Permission denied|403|not authorized'; then
        a "   → Insufficient permissions"; a "     Suggestion: gh auth refresh -s workflow"
      fi
      if lm 'certificate|SSL|TLS|untrusted'; then
        a "   → Certificate/SSL error"; a "     Suggestion: check certificate or network proxy"
      fi
      if [ -n "${CI_PATTERNS:-}" ]; then
        if [ -f "$CI_PATTERNS" ]; then
          while IFS='|' read -r pat hint; do
            [[ "$pat" =~ ^# ]] && continue; [ -z "$pat" ] && continue
            lm "$pat" && a "   → $hint"
          done < "$CI_PATTERNS"
        else
          printf '%s\n' "⚠️  CI_PATTERNS file not found: $CI_PATTERNS" >&2
        fi
      fi
      [ -z "$ANALYSIS" ] && a "   → No known error pattern matched"
      echo ""; printf '%s\n' "${BOLD}💡 Analysis:${OFF}"; printf '%s' "$ANALYSIS"
      KEY=$(grep -iE 'error|fail|fatal' <<< "$LOG" | head -n 5 || true)
      [ -n "$KEY" ] && { echo ""; printf '%s\n' "${BOLD}🔑 Key lines:${OFF}"; printf '%s\n' "$KEY" | sed 's/^/  /'; }
      TL=$(printf '%s\n' "$LOG" | tail -n 15)
      echo ""; printf '%s\n' "${BOLD}📄 Log tail:${OFF}"; printf '%s\n' "$TL" | sed 's/^/  /'
    else echo "  (Unable to fetch log)"; fi
  done < <(get_failed_runs)
elif $ANALYZE && [ "${FAILED:-0}" != "0" ]; then
  printf '%s\n' "  ⚠️ Text mode does not support analysis"
elif $ANALYZE; then printf '%s\n' "  (All passed)"; fi

if $SHOW_LOG && [ "${FAILED:-0}" != "0" ] && $USE_JSON; then
  echo ""; printf '%s\n' "${BOLD}$H${OFF}"
  printf '%s\n' "${BOLD}📋 Failure logs (full)${OFF}"; printf '%s\n' "${BOLD}$H${OFF}"
  while IFS=$'\t' read -r run_id job_name; do
    echo ""; echo "━━ $job_name (run $run_id) ━━"
    printf '%s\n' "🔗 https://github.com/$REPO/actions/runs/$run_id"
    gh run view "$run_id" --repo "$REPO" --log-failed 2>/dev/null || echo "  (none)"
  done < <(get_failed_runs)
fi

if $RERUN && [ "${FAILED:-0}" != "0" ] && $USE_JSON; then
  echo ""; printf '%s\n' "${BOLD}$H${OFF}"
  printf '%s\n' "${BOLD}🔄 Rerunning failed jobs${OFF}"; printf '%s\n' "${BOLD}$H${OFF}"
  while IFS=$'\t' read -r run_id job_name; do
    echo "  ❌ $job_name (run $run_id)"
  done < <(get_failed_runs)
  if ! $SKIP_CONFIRM; then
    echo ""; read -r -p "Confirm rerun all failed jobs above? [y/N] " cf
    [[ "${cf:-n}" != "y" && "${cf:-n}" != "Y" ]] && { echo "Cancelled"; exit 0; }
  fi
  NEW_RUNS=()
  while IFS=$'\t' read -r run_id job_name; do
    echo "🔄 Rerunning $job_name ..."
    RERUN_OUT=$(gh run rerun "$run_id" --repo "$REPO" --failed 2>&1) || { printf '%s\n' "  ${RED}⚠️ Rerun failed${OFF}"; continue; }
    NEW_ID=$(echo "$RERUN_OUT" | grep -oE 'runs/[0-9]+' | cut -d/ -f2 | head -1 || echo "")
    if [ -n "$NEW_ID" ]; then
      printf '%s\n' "  ${GREEN}✅ New run: $NEW_ID${OFF}"; NEW_RUNS+=("$NEW_ID")
    else printf '%s\n' "  ✅ Triggered"; fi
  done < <(get_failed_runs)
  if [ ${#NEW_RUNS[@]} -gt 0 ]; then
    echo ""; echo "📎 New runs:"
    for rid in "${NEW_RUNS[@]}"; do
      printf '%s\n' "   https://github.com/$REPO/actions/runs/$rid"
    done
    if $WAIT; then
      echo ""; echo "⏳ Waiting for completion..."
      for rid in "${NEW_RUNS[@]}"; do
        gh run watch "$rid" --repo "$REPO" 2>&1 || {
          echo "   watch unavailable, polling..."
          while true; do
            S=$(gh run view "$rid" --repo "$REPO" --json status --jq '.status' 2>/dev/null)
            [ "$S" = "completed" ] && { echo "   ✅ Completed"; break; }
            sleep 15
          done
        }
      done
    fi
  fi
elif $RERUN && [ "${FAILED:-0}" != "0" ]; then
  printf '%s\n' "  ⚠️ Text mode does not support rerun"
elif $RERUN; then printf '%s\n' "  (All passed, no rerun needed)"; fi

echo ""; printf '%s\n' "${BOLD}$H${OFF}"

if $EXIT_CODE && [ "${FAILED:-0}" != "0" ]; then exit 1; fi
