#!/usr/bin/env bash
# ci_pr.sh — PR CI 状态查看 + 失败分析 + 重跑 + 跟踪
# 用法: ./ci_pr.sh <owner/repo|.> <PR> [选项]
set -euo pipefail

if [ -t 1 ]; then
  RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BOLD='\033[1m'; OFF='\033[0m'
else RED=''; GREEN=''; YELLOW=''; BOLD=''; OFF=''; fi

show_help() {
  cat << 'HELP'
用法: ./ci_pr.sh <owner/repo|.> <PR> [选项]
  --log       显示失败 Job 完整日志
  --analyze   分析失败原因并给出修复建议
  --rerun     重跑失败 Job
  --wait      重跑后等待完成
  --json      输出原始 CI checks JSON
  --exit-code 有失败时退出码 1
  --yes,-y    跳过重跑确认
  --verbose   调试信息
  -h,--help   帮助
环境变量:
  GH_REPO     默认仓库 (owner/repo)
  CI_PATTERNS 自定义错误模式文件路径, 每行: 正则|提示, 支持#注释
HELP
  exit 0
}

# 失败状态：已结束且非成功/跳过
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
       { echo "❌ 未知参数: $a"; exit 1; } ;;
  esac
done
REPO="${REPO_ARG:-${GH_REPO:-}}"; PR="${PR_ARG:-}"
[ -z "$REPO" ] && { echo "❌ 缺少仓库参数"; exit 1; }
[ -z "$PR" ]   && { echo "❌ 缺少 PR 编号"; exit 1; }
[[ "$PR" =~ ^[0-9]+$ ]] || { echo "❌ PR 编号必须为数字"; exit 1; }
# 验证仓库格式（跳过 . 推断）
[[ "$REPO" = "." || "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]] || { echo "❌ 仓库格式必须为 owner/repo"; exit 1; }
debug() { [ "$VERBOSE" = true ] && printf '%s\n' "[DEBUG] $*" >&2; }

# 仓库推断
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
  REPO=$(infer_repo) || { echo "❌ 无法推断仓库，请手动提供 owner/repo"; exit 1; }
  printf '%s\n' "📁 $REPO"
fi

command -v gh &>/dev/null || { echo "❌ 需要 gh"; exit 1; }
command -v jq &>/dev/null || { echo "❌ 需要 jq"; exit 1; }
JQ_VER=$(jq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0.0")
JQ_MAJOR=${JQ_VER%%.*}; JQ_MINOR=${JQ_VER##*.}
{ [ "$JQ_MAJOR" -lt 1 ] || { [ "$JQ_MAJOR" -eq 1 ] && [ "$JQ_MINOR" -lt 6 ]; }; } \
  && echo "⚠️  jq $JQ_VER 可能不支持部分功能，建议 ≥ 1.6"
gh auth status &>/dev/null || { echo "❌ 请 gh auth login"; exit 1; }
debug "REPO=$REPO PR=$PR"

H="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
USE_JSON=true

echo ""; printf '%s\n' "${BOLD}$H${OFF}"
printf '%s\n' "${BOLD}🔄 CI 状态 — PR #$PR ($REPO)${OFF}"
printf '%s\n' "🔗 https://github.com/$REPO/pull/$PR"
printf '%s\n' "${BOLD}$H${OFF}"

CHECKS_TXT=$(gh pr checks "$PR" --repo "$REPO" 2>&1) || CHECKS_TXT=""
CHECKS_JSON=$(gh pr checks "$PR" --repo "$REPO" --json name,state,bucket,link,workflow,completedAt 2>/dev/null) || CHECKS_JSON=""

if $JSON_OUT && [ -n "$CHECKS_JSON" ]; then
  printf '%s\n' "$CHECKS_JSON"; exit 0
fi

if [ -z "$CHECKS_TXT" ] && [ -z "$CHECKS_JSON" ]; then
  printf '%s\n' "  (此 PR 未配置 CI checks)"; exit 0
fi

if [ -n "$CHECKS_JSON" ] && ! jq -e . >/dev/null 2>&1 <<< "$CHECKS_JSON"; then
  printf '%s\n' "⚠️  JSON 数据无效，回退到文本模式"; USE_JSON=false
fi
if $USE_JSON && [ "$CHECKS_JSON" = "[]" ]; then
  printf '%s\n' "⚠️  无法获取 JSON 数据，回退到文本模式"; USE_JSON=false
fi

if $USE_JSON; then
  TOTAL=$(jq 'length' <<< "$CHECKS_JSON")
  PASSED=$(jq '[.[] | select(.state == "SUCCESS")] | length' <<< "$CHECKS_JSON")
  FAILED=$(jq "[.[] | $JQ_FAILED] | length" <<< "$CHECKS_JSON")
  PENDING=$(jq '[.[] | select(.state | test("PENDING|IN_PROGRESS|QUEUED"))] | length' <<< "$CHECKS_JSON")
  printf '%s' "${BOLD}📊 总计 $TOTAL  |  ${GREEN}✅ $PASSED 通过${OFF}"
  printf '%s\n' "  |  ${RED}❌ $FAILED 失败${OFF}  |  ${YELLOW}⏳ $PENDING 等待中${OFF}"
else
  PASSED=0; FAILED=0; TOTAL=0
  printf '%s\n' "⚠️  文本模式功能受限，建议安装 jq"
fi

printf '%s\n' "$CHECKS_TXT"; echo ""

get_failed_runs() {
  jq -c ".[] | $JQ_FAILED | {link: (.link // \"\"), name: .name}" <<< "$CHECKS_JSON" \
  | while IFS= read -r line; do
      local link; link=$(jq -r '.link // ""' <<< "$line")
      local name; name=$(jq -r '.name' <<< "$line")
      if [ -z "$link" ]; then
        printf '%s\n' "⚠️  「$name」无关联 workflow run，跳过" >&2; continue
      fi
      local rid; rid=$(echo "$link" | grep -Eo 'runs/[0-9]+' | cut -d/ -f2 || echo "")
      if [ -z "$rid" ]; then
        printf '%s\n' "⚠️  「$name」无法解析 run ID" >&2; continue
      fi
      printf '%s\t%s\n' "$rid" "$name"
    done | awk -F'\t' '!seen[$1]++'
}

lm() { grep -qiE "$1" <<< "$LOG" 2>/dev/null && return 0 || return 1; }
a() { ANALYSIS+="$1"$'\n'; }

if $ANALYZE && [ "${FAILED:-0}" != "0" ] && $USE_JSON; then
  echo ""; printf '%s\n' "${BOLD}$H${OFF}"
  printf '%s\n' "${BOLD}🔍 失败分析${OFF}"; printf '%s\n' "${BOLD}$H${OFF}"
  echo "失败 Job:"
  jq -r ".[] | $JQ_FAILED | \"  ❌ \(.name) [\(.state)]\"" <<< "$CHECKS_JSON"
  echo ""; echo "📋 日志分析:"
  while IFS=$'\t' read -r run_id job_name; do
    ANALYSIS=""
    echo ""; echo "━━ $job_name (run $run_id) ━━"
    LOG=$(timeout 30 gh run view "$run_id" --repo "$REPO" --log-failed 2>/dev/null | tail -n 150) || LOG=""
    if [ -n "$LOG" ]; then
      printf '%s\n' "$LOG" | head -n 120
      if lm 'npm ERR!|error TS[0-9]+|Cannot find module'; then
        a "   → Node.js/TS 构建或依赖错误"; a "     运行: npm ci && npm run build"
      fi
      if lm 'error\[E\d+\]|cargo build.*failed'; then
        a "   → Rust 编译错误"; a "     运行: cargo check --all-features"
      fi
      if lm 'FAIL:|assertion|expected.*but got|Actual:'; then
        a "   → 测试失败"; a "     运行: cargo test | npm test | pytest"
      fi
      if lm 'warning:.*clippy|prettier|eslint|format'; then
        a "   → Lint/格式错误"; a "     运行: cargo clippy | npm run lint"
      fi
      if lm 'timeout|timed out|connection refused|502|503|504'; then
        a "   → 网络超时或服务不可用"; a "     建议: --rerun 重试"
      fi
      if lm 'could not resolve|ModuleNotFoundError|ImportError'; then
        a "   → 依赖解析失败"; a "     建议: 检查依赖声明和锁文件"
      fi
      if lm 'docker build.*failed|manifest.*not found'; then
        a "   → Docker 构建错误"; a "     运行: docker build ."
      fi
      if lm 'not set|required.*variable|variable.*missing'; then
        a "   → 环境变量缺失"; a "     建议: 检查 CI secrets/variables"
      fi
      if lm 'Permission denied|403|not authorized'; then
        a "   → 权限不足"; a "     建议: gh auth refresh -s workflow"
      fi
      if lm 'certificate|SSL|TLS|untrusted'; then
        a "   → 证书/SSL 错误"; a "     建议: 检查证书或网络代理"
      fi
      if [ -n "${CI_PATTERNS:-}" ]; then
        if [ -f "$CI_PATTERNS" ]; then
          while IFS='|' read -r pat hint; do
            [[ "$pat" =~ ^# ]] && continue; [ -z "$pat" ] && continue
            lm "$pat" && a "   → $hint"
          done < "$CI_PATTERNS"
        else
          printf '%s\n' "⚠️  CI_PATTERNS 文件不存在: $CI_PATTERNS" >&2
        fi
      fi
      [ -z "$ANALYSIS" ] && a "   → 未匹配已知错误模式"
      echo ""; printf '%s\n' "${BOLD}💡 分析:${OFF}"; printf '%s' "$ANALYSIS"
      KEY=$(grep -iE 'error|fail|fatal' <<< "$LOG" | head -n 5 || true)
      [ -n "$KEY" ] && { echo ""; printf '%s\n' "${BOLD}🔑 关键行:${OFF}"; printf '%s\n' "$KEY" | sed 's/^/  /'; }
      TL=$(printf '%s\n' "$LOG" | tail -n 15)
      echo ""; printf '%s\n' "${BOLD}📄 日志末尾:${OFF}"; printf '%s\n' "$TL" | sed 's/^/  /'
    else echo "  (无法获取日志)"; fi
  done < <(get_failed_runs)
elif $ANALYZE && [ "${FAILED:-0}" != "0" ]; then
  printf '%s\n' "  ⚠️ 文本模式不支持分析"
elif $ANALYZE; then printf '%s\n' "  (全部通过)"; fi

if $SHOW_LOG && [ "${FAILED:-0}" != "0" ] && $USE_JSON; then
  echo ""; printf '%s\n' "${BOLD}$H${OFF}"
  printf '%s\n' "${BOLD}📋 失败日志 (完整)${OFF}"; printf '%s\n' "${BOLD}$H${OFF}"
  while IFS=$'\t' read -r run_id job_name; do
    echo ""; echo "━━ $job_name (run $run_id) ━━"
    printf '%s\n' "🔗 https://github.com/$REPO/actions/runs/$run_id"
    gh run view "$run_id" --repo "$REPO" --log-failed 2>/dev/null || echo "  (无)"
  done < <(get_failed_runs)
fi

if $RERUN && [ "${FAILED:-0}" != "0" ] && $USE_JSON; then
  echo ""; printf '%s\n' "${BOLD}$H${OFF}"
  printf '%s\n' "${BOLD}🔄 重跑失败 Job${OFF}"; printf '%s\n' "${BOLD}$H${OFF}"
  while IFS=$'\t' read -r run_id job_name; do
    echo "  ❌ $job_name (run $run_id)"
  done < <(get_failed_runs)
  if ! $SKIP_CONFIRM; then
    echo ""; read -r -p "确认重跑以上所有失败 Job？ [y/N] " cf
    [[ "${cf:-n}" != "y" && "${cf:-n}" != "Y" ]] && { echo "已取消"; exit 0; }
  fi
  NEW_RUNS=()
  while IFS=$'\t' read -r run_id job_name; do
    echo "🔄 重跑 $job_name ..."
    RERUN_OUT=$(gh run rerun "$run_id" --repo "$REPO" --failed 2>&1) || { printf '%s\n' "  ${RED}⚠️ 重跑失败${OFF}"; continue; }
    NEW_ID=$(echo "$RERUN_OUT" | grep -oE 'runs/[0-9]+' | cut -d/ -f2 | head -1 || echo "")
    if [ -n "$NEW_ID" ]; then
      printf '%s\n' "  ${GREEN}✅ 新 run: $NEW_ID${OFF}"; NEW_RUNS+=("$NEW_ID")
    else printf '%s\n' "  ✅ 已触发"; fi
  done < <(get_failed_runs)
  if [ ${#NEW_RUNS[@]} -gt 0 ]; then
    echo ""; echo "📎 新 Run:"
    for rid in "${NEW_RUNS[@]}"; do
      printf '%s\n' "   https://github.com/$REPO/actions/runs/$rid"
    done
    if $WAIT; then
      echo ""; echo "⏳ 等待完成..."
      for rid in "${NEW_RUNS[@]}"; do
        gh run watch "$rid" --repo "$REPO" 2>&1 || {
          echo "   watch 不可用，轮询中..."
          while true; do
            S=$(gh run view "$rid" --repo "$REPO" --json status --jq '.status' 2>/dev/null)
            [ "$S" = "completed" ] && { echo "   ✅ 完成"; break; }
            sleep 15
          done
        }
      done
    fi
  fi
elif $RERUN && [ "${FAILED:-0}" != "0" ]; then
  printf '%s\n' "  ⚠️ 文本模式不支持重跑"
elif $RERUN; then printf '%s\n' "  (全部通过，无需重跑)"; fi

echo ""; printf '%s\n' "${BOLD}$H${OFF}"

if $EXIT_CODE && [ "${FAILED:-0}" != "0" ]; then exit 1; fi
