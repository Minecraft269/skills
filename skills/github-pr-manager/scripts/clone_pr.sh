#!/usr/bin/env bash
# clone_pr.sh — 克隆 GitHub PR 到 <owner>-<repo>-pr-<编号> 目录并检测项目类型引导初始化
# 兼容: Git Bash (Windows), WSL2, macOS, Linux
# 用法: ./clone_pr.sh <owner/repo> <pr_number> [base_path] [选项]

set -euo pipefail

# ============================================================================
# 帮助信息
# ============================================================================
show_help() {
    cat << 'EOF'
用法: ./clone_pr.sh <owner/repo> <pr_number> [base_path] [选项]

克隆 GitHub PR 到本地 <owner>-<repo>-pr-<编号> 目录，自动检测项目类型并引导初始化。

参数:
  owner/repo      GitHub 仓库（如 facebook/react）
  pr_number       PR 编号
  base_path       克隆根目录（默认当前目录）

选项:
  -y, --yes       跳过所有确认提示（非交互模式）
  --no-install    禁止任何依赖安装，仅克隆代码（最高安全级别）
  --force         非交互模式下，若目标目录已存在则自动删除重建
  --debug         输出详细诊断日志
  -h, --help      显示此帮助

环境变量:
  CLONE_PR_YES=1          等同于 -y
  CLONE_PR_NO_INSTALL=1   等同于 --no-install
  CLONE_PR_RUST_MODE      非交互模式下 Rust 行为: fetch|build|check|skip（默认 fetch）

示例:
  ./clone_pr.sh facebook/react 28452
  ./clone_pr.sh lodash/lodash 4528 ~/dev/pr-review -y
  ./clone_pr.sh owner/repo 123 . --no-install --debug

审查完成后:
  清理:  rm -rf <owner>-<repo>-pr-<编号>
  提交:  cd <owner>-<repo>-pr-<编号> && git push  # 需仓库写权限
EOF
    exit 0
}

# ============================================================================
# 参数解析
# ============================================================================
SKIP_CONFIRM=false
NO_INSTALL=false
FORCE_DELETE=false
DEBUG=false
ARGS=()

for arg in "$@"; do
    case "$arg" in
        -h|--help)       show_help ;;
        -y|--yes)        SKIP_CONFIRM=true ;;
        --no-install)    NO_INSTALL=true ;;
        --force)         FORCE_DELETE=true ;;
        --debug)         DEBUG=true ;;
        --*)             echo "❌ 未知选项: $arg" >&2; exit 1 ;;
        *)               ARGS+=("$arg") ;;
    esac
done

[ "${CLONE_PR_YES:-0}" = "1" ]         && SKIP_CONFIRM=true
[ "${CLONE_PR_NO_INSTALL:-0}" = "1" ]  && NO_INSTALL=true

REPO="${ARGS[0]:?请提供仓库 (owner/repo)}"
PR_NUMBER="${ARGS[1]:?请提供 PR 编号}"

# 跨平台路径规范化（Git Bash / WSL / macOS / Linux 通用）
BASE_PATH="${ARGS[2]:-.}"
mkdir -p "$BASE_PATH"
BASE_PATH="$(cd "$BASE_PATH" && pwd)" || {
    echo "❌ 无法进入目录: $BASE_PATH"
    exit 1
}

REPO_SAFE="${REPO//\//-}"
TARGET_DIR="${BASE_PATH}/${REPO_SAFE}-pr-${PR_NUMBER}"

# ============================================================================
# 中断/退出清理
# ============================================================================
CLONE_DONE=false

cleanup() {
    if [ -d "$TARGET_DIR" ] && ! $CLONE_DONE; then
        echo ""
        echo "🧹 清理未完成的克隆目录: ${TARGET_DIR}"
        rm -rf "$TARGET_DIR"
    fi
}
trap cleanup EXIT

# ============================================================================
# 诊断日志
# ============================================================================
debug() { [ "$DEBUG" = true ] && echo "[DEBUG] $*" >&2; }
debug "REPO=$REPO  PR=$PR_NUMBER  BASE_PATH=$BASE_PATH"
debug "TARGET_DIR=$TARGET_DIR"
debug "SKIP_CONFIRM=$SKIP_CONFIRM  NO_INSTALL=$NO_INSTALL  FORCE_DELETE=$FORCE_DELETE"

# ============================================================================
# 辅助函数
# ============================================================================

confirm_or_skip() {
    local prompt="$1"
    if [ "$NO_INSTALL" = true ]; then
        return 1
    fi
    if [ "$SKIP_CONFIRM" = false ]; then
        if [ -t 0 ]; then
            read -r -p "$prompt [y/N] " answer
            [ "${answer:-n}" != "y" ] && [ "${answer:-n}" != "Y" ] && return 1
        else
            return 1
        fi
    fi
    return 0
}

# 安全获取目录大小（Git Bash 可能没有 du）
get_dir_size() {
    if command -v du &>/dev/null; then
        du -sh . 2>/dev/null | awk '{print $1}'
    else
        echo "N/A"
    fi
}

# ============================================================================
# 前置检查
# ============================================================================

if ! command -v gh &>/dev/null; then
    echo "❌ 需要安装 GitHub CLI: https://cli.github.com/"
    exit 1
fi
debug "gh: $(gh --version 2>&1 | head -1)"

if ! gh auth status &>/dev/null; then
    echo "❌ 未登录 GitHub CLI，请执行: gh auth login"
    exit 1
fi

if [ ! -w "$BASE_PATH" ]; then
    echo "❌ 路径 $BASE_PATH 不可写，请检查权限。"
    exit 1
fi

SKIP_CLONE=false

if [ -d "$TARGET_DIR" ]; then
    echo "⚠️  目录 ${TARGET_DIR} 已存在。"
    if [ "$SKIP_CONFIRM" = true ]; then
        if [ "$FORCE_DELETE" = true ]; then
            echo "🔄 自动删除已有目录 ${TARGET_DIR} ..."
            rm -rf "$TARGET_DIR"
        else
            echo "❌ 非交互模式下目标目录已存在，拒绝自动删除。"
            echo "   请手动处理或使用 --force 选项。"
            exit 1
        fi
    else
        echo "   [y] 删除并重新克隆"
        echo "   [n] 跳过克隆，直接在已有目录检测项目类型"
        echo "   [q] 取消"
        read -r -p "选择: " choice
        case "$choice" in
            y|Y) rm -rf "$TARGET_DIR" ;;
            n|N) SKIP_CLONE=true ;;
            *)   echo "已取消" && exit 0 ;;
        esac
    fi
fi

# ============================================================================
# 安全警告
# ============================================================================
cat << 'EOF'

⚠️  您即将操作来自第三方 PR 的代码，其中可能包含未审查的内容。
安装依赖（npm install / pip install 等）时可能执行构建脚本。

请优先检查以下文件中是否包含恶意脚本：
  - package.json 中的 "scripts"（尤其 preinstall / postinstall）
  - Makefile / CMakeLists.txt / build.gradle
  - setup.py / pyproject.toml 中的自定义命令
  - 任何 .sh / .bat / .ps1 文件

建议在审查代码后再安装依赖。

EOF

if [ "$NO_INSTALL" = true ]; then
    echo "🔒 --no-install 模式：本次不会安装任何依赖。"
fi

if [ "$SKIP_CONFIRM" = false ] && ! $SKIP_CLONE; then
    read -r -p "是否继续？ [y/N] " confirm
    if [ "${confirm:-N}" != "y" ] && [ "${confirm:-N}" != "Y" ]; then
        echo "已取消。"
        exit 0
    fi
fi

# ============================================================================
# 克隆流程
# ============================================================================

if ! $SKIP_CLONE; then
    echo "🚀 正在克隆 PR #${PR_NUMBER} from ${REPO}..."

    if ! gh repo clone "$REPO" "$TARGET_DIR" -- --filter=blob:none 2>/dev/null; then
        echo "⚠️  部分克隆失败（可能 Git 版本过旧或服务端不支持）"
        echo "   建议升级 Git 到 ≥ 2.19"
        echo "   正在尝试完整克隆..."
        if ! gh repo clone "$REPO" "$TARGET_DIR"; then
            echo "❌ 无法克隆仓库 $REPO"
            echo "   请检查仓库名是否正确，以及是否有访问权限。"
            exit 1
        fi
    fi

    cd "$TARGET_DIR"

    echo "⏳ 检出 PR 分支..."
    if ! gh pr checkout "$PR_NUMBER"; then
        echo "❌ 无法检出 PR #${PR_NUMBER}"
        echo "   请检查：PR 编号是否正确 / 是否有该仓库读取权限 / 网络是否正常"
        cd "$BASE_PATH"
        rm -rf "$TARGET_DIR"
        exit 1
    fi

    CLONE_DONE=true
else
    # 跳过克隆时立即标记完成，防止 cleanup 误删用户目录
    CLONE_DONE=true

    echo "📂 使用已有目录: ${TARGET_DIR}"
    if ! cd "$TARGET_DIR" 2>/dev/null; then
        echo "❌ 无法进入目录: ${TARGET_DIR}"
        exit 1
    fi

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ 目录 ${TARGET_DIR} 不是一个 Git 仓库。"
        exit 1
    fi

    echo "🌿 当前分支: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
    if [ "$SKIP_CONFIRM" = false ]; then
        read -r -p "确认使用该目录？ [y/N] " ans
        [ "${ans:-n}" != "y" ] && [ "${ans:-n}" != "Y" ] && exit 0
    fi
fi

# ============================================================================
# 展示克隆结果
# ============================================================================

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# 优先用 gh API 获取 base 分支
BASE_BRANCH=$(gh pr view "$PR_NUMBER" --json baseRefName --jq '.baseRefName' 2>/dev/null)
if [ -z "$BASE_BRANCH" ]; then
    BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD@{upstream} 2>/dev/null | sed 's|^[^/]*/||')
fi
[ -z "$BASE_BRANCH" ] && BASE_BRANCH="unknown"

SIZE=$(get_dir_size)

echo ""
echo "✅ PR #${PR_NUMBER} 就绪"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📂 路径:     ${TARGET_DIR}"
echo "🌿 分支:     ${BRANCH}"
echo "📏 大小:     ${SIZE}（使用 --filter=blob:none 时文件内容按需下载）"
echo "📍 Base:     ${BASE_BRANCH}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# Node 版本提示（.nvmrc / .node-version）
# ============================================================================
check_node_version_hint() {
    local node_ver_file=""
    [ -f ".nvmrc" ]       && node_ver_file=".nvmrc"
    [ -f ".node-version" ] && node_ver_file=".node-version"

    if [ -n "$node_ver_file" ]; then
        local ver
        ver=$(head -1 "$node_ver_file" 2>/dev/null)
        echo ""
        echo "💡 检测到 ${node_ver_file}，建议使用 Node.js ${ver}"
        echo "   nvm use   # 或: fnm use"
    fi
}

# ============================================================================
# 项目类型检测（独立检测，支持混合项目 / monorepo）
# ============================================================================

DETECTED_TYPES=()
[ -f "package.json" ]    && DETECTED_TYPES+=("node")
[ -f "requirements.txt" ] && DETECTED_TYPES+=("python")
[ -f "pyproject.toml" ]   && DETECTED_TYPES+=("python")
[ -f "Cargo.toml" ]       && DETECTED_TYPES+=("rust")
[ -f "go.mod" ]           && DETECTED_TYPES+=("go")
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    DETECTED_TYPES+=("java")
fi

DETECTED_TYPES=($(printf '%s\n' "${DETECTED_TYPES[@]}" | sort -u))

debug "检测到项目类型: ${DETECTED_TYPES[*]:-无}"

DEPS_INSTALLED=false
SUMMARY_PARTS=()

# ============================================================================
# Node.js
# ============================================================================

install_node() {
    echo ""
    echo "🔍 检测到 Node.js 项目 (package.json)"
    check_node_version_hint

    if ! confirm_or_skip "是否为 Node.js 安装依赖？"; then
        SUMMARY_PARTS+=("Node.js: ⏭ 未安装 (手动: npm install)")
        return
    fi

    if [ -f "pnpm-lock.yaml" ]; then
        if command -v pnpm &>/dev/null; then
            debug "使用 pnpm"
            if pnpm install; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Node.js: ✅ pnpm")
            else
                SUMMARY_PARTS+=("Node.js: ❌ pnpm 安装失败")
            fi
        else
            echo "⚠️  pnpm 未安装，回退到 npm ..."
            if npm install; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Node.js: ✅ npm (pnpm 不可用)")
            else
                SUMMARY_PARTS+=("Node.js: ❌ npm 安装失败")
            fi
        fi
    elif [ -f "yarn.lock" ]; then
        if command -v yarn &>/dev/null; then
            debug "使用 yarn"
            if yarn install; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Node.js: ✅ yarn")
            else
                SUMMARY_PARTS+=("Node.js: ❌ yarn 安装失败")
            fi
        else
            echo "⚠️  yarn 未安装，回退到 npm ..."
            if npm install; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Node.js: ✅ npm (yarn 不可用)")
            else
                SUMMARY_PARTS+=("Node.js: ❌ npm 安装失败")
            fi
        fi
    else
        if npm install; then
            DEPS_INSTALLED=true
            SUMMARY_PARTS+=("Node.js: ✅ npm")
        else
            SUMMARY_PARTS+=("Node.js: ❌ npm 安装失败")
        fi
    fi
}

# ============================================================================
# Python
# ============================================================================

install_python() {
    echo ""
    echo "🔍 检测到 Python 项目"
    if ! confirm_or_skip "是否为 Python 安装依赖？"; then
        local hint="pip install -r requirements.txt"
        [ -f "pyproject.toml" ] && hint="pip install ."
        SUMMARY_PARTS+=("Python: ⏭ 未安装 (手动: ${hint})")
        return
    fi

    PYTHON=$(command -v python3 || command -v python)
    if [ -z "$PYTHON" ]; then
        echo "❌ 未找到 Python，请先安装 Python ≥ 3.6"
        SUMMARY_PARTS+=("Python: ❌ 未找到解释器")
        return
    fi
    debug "Python: $PYTHON ($($PYTHON --version 2>&1))"

    # 跨平台版本检查（不依赖 sort -V）
    local py_ver
    py_ver=$("$PYTHON" --version 2>&1 | awk '{print $2}')
    if ! "$PYTHON" -c "import sys; sys.exit(0 if sys.version_info >= (3,6) else 1)" 2>/dev/null; then
        echo "❌ Python 版本为 ${py_ver:-?}，需要 ≥ 3.6"
        SUMMARY_PARTS+=("Python: ❌ 版本 ${py_ver:-?} 不满足 (需 ≥ 3.6)")
        return
    fi
    debug "Python 版本: $py_ver"

    # 工具检测顺序：uv → poetry → pdm → pip
    if [ -f "uv.lock" ] && command -v uv &>/dev/null; then
        debug "使用 uv"
        if uv sync; then
            DEPS_INSTALLED=true
            SUMMARY_PARTS+=("Python: ✅ uv")
        else
            SUMMARY_PARTS+=("Python: ❌ uv sync 失败")
        fi
        return
    fi
    if [ -f "poetry.lock" ] && command -v poetry &>/dev/null; then
        debug "使用 poetry"
        if poetry install; then
            DEPS_INSTALLED=true
            SUMMARY_PARTS+=("Python: ✅ poetry")
        else
            SUMMARY_PARTS+=("Python: ❌ poetry 安装失败")
        fi
        return
    fi
    if [ -f "pdm.lock" ] && command -v pdm &>/dev/null; then
        debug "使用 pdm"
        if pdm install; then
            DEPS_INSTALLED=true
            SUMMARY_PARTS+=("Python: ✅ pdm")
        else
            SUMMARY_PARTS+=("Python: ❌ pdm 安装失败")
        fi
        return
    fi
    if [ -f "uv.lock" ] || [ -f "poetry.lock" ] || [ -f "pdm.lock" ]; then
        echo "⚠️  检测到锁文件但对应工具不可用，回退到 pip ..."
    fi

    # 标准 venv + pip
    local d act VENV_DIR
    for d in ".venv" "venv" "env"; do
        if [ -d "$d" ]; then
            act=""
            [ -f "$d/bin/activate" ]    && act="$d/bin/activate"
            [ -f "$d/Scripts/activate" ] && act="$d/Scripts/activate"
            if [ -n "$act" ] && [ -f "$act" ]; then
                # 验证虚拟环境可执行
                local test_py="${d}/bin/python"
                [ -f "${d}/Scripts/python.exe" ] && test_py="${d}/Scripts/python.exe"
                if [ -f "$test_py" ] && "$test_py" -c "print('ok')" >/dev/null 2>&1; then
                    VENV_DIR="$d"
                    debug "复用已有虚拟环境: $d"
                    break
                fi
            fi
        fi
    done

    if [ -z "$VENV_DIR" ]; then
        VENV_DIR=".venv"
        if ! $PYTHON -m venv "$VENV_DIR"; then
            echo "❌ 无法创建虚拟环境，请检查 Python 安装。"
            SUMMARY_PARTS+=("Python: ❌ venv 创建失败")
            return
        fi
    fi

    # 在子 shell 中激活 + 安装，避免污染当前 shell 环境
    local install_ok=false
    if [ -f "$VENV_DIR/bin/activate" ]; then
        (
            source "$VENV_DIR/bin/activate"
            if [ -f "pyproject.toml" ]; then
                echo "📦 尝试从 pyproject.toml 安装 ..."
                pip install .
            else
                pip install -r requirements.txt
            fi
        ) && install_ok=true
    elif [ -f "$VENV_DIR/Scripts/activate" ]; then
        (
            source "$VENV_DIR/Scripts/activate"
            if [ -f "pyproject.toml" ]; then
                echo "📦 尝试从 pyproject.toml 安装 ..."
                pip install .
            else
                pip install -r requirements.txt
            fi
        ) && install_ok=true
    else
        echo "❌ 虚拟环境未正确创建，跳过激活"
        SUMMARY_PARTS+=("Python: ⚠️ 虚拟环境异常")
        return
    fi

    if $install_ok; then
        DEPS_INSTALLED=true
        SUMMARY_PARTS+=("Python: ✅ pip (${VENV_DIR})")
    else
        echo "⚠️  pip install 失败，请手动检查构建系统配置"
        SUMMARY_PARTS+=("Python: ⚠️ 安装失败")
    fi
}

# ============================================================================
# Rust
# ============================================================================

install_rust() {
    echo ""
    echo "🔍 检测到 Rust 项目 (Cargo.toml)"

    if ! command -v cargo &>/dev/null; then
        echo "❌ cargo 未安装，请先安装 Rust: https://rustup.rs/"
        SUMMARY_PARTS+=("Rust: ❌ cargo 不可用")
        return
    fi

    if [ "$NO_INSTALL" = true ]; then
        SUMMARY_PARTS+=("Rust: ⏭ 未构建 (手动: cargo build)")
        return
    fi

    local rust_choice=""
    if [ "$SKIP_CONFIRM" = false ] && [ -t 0 ]; then
        echo ""
        echo "   [f] 仅下载依赖 (cargo fetch) — 快速，不编译"
        echo "   [b] 完整构建 (cargo build) — 可能较慢"
        echo "   [c] 快速检查 (cargo check) — 不生成二进制"
        echo "   [s] 跳过"
        read -r -p "选择 [f/b/c/s] (默认 f): " rust_choice
    else
        rust_choice="${CLONE_PR_RUST_MODE:-f}"
    fi
    [ -z "$rust_choice" ] && rust_choice="f"

    # 校验值合法性
    case "$rust_choice" in
        f|fetch)   rust_choice="f" ;;
        b|build)   rust_choice="b" ;;
        c|check)   rust_choice="c" ;;
        s|skip)    rust_choice="s" ;;
        *)
            echo "⚠️  无效的 CLONE_PR_RUST_MODE 值: $rust_choice，回退到 fetch"
            rust_choice="f"
            ;;
    esac

    case "$rust_choice" in
        f)
            if cargo fetch; then
                SUMMARY_PARTS+=("Rust: ✅ 依赖已下载")
                echo "💡 依赖已下载，执行 cargo build 将开始编译，可能耗时较长。"
            else
                SUMMARY_PARTS+=("Rust: ❌ cargo fetch 失败")
            fi
            ;;
        b)
            if cargo build; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Rust: ✅ cargo build")
            else
                SUMMARY_PARTS+=("Rust: ❌ cargo build 失败")
            fi
            ;;
        c)
            if cargo check; then
                SUMMARY_PARTS+=("Rust: ✅ cargo check 通过")
            else
                SUMMARY_PARTS+=("Rust: ❌ cargo check 失败")
            fi
            ;;
        s) SUMMARY_PARTS+=("Rust: ⏭ 跳过 (手动: cargo build)") ;;
    esac
}

# ============================================================================
# Go（仅提示，不自动安装）
# ============================================================================

install_go() {
    echo ""
    echo "🔍 检测到 Go 项目 (go.mod)"
    SUMMARY_PARTS+=("Go: ℹ️ 使用 go mod (手动: go mod download)")
}

# ============================================================================
# Java（仅提示，不自动安装）
# ============================================================================

install_java() {
    echo ""
    echo "🔍 检测到 Java 项目"
    if [ -f "pom.xml" ]; then
        SUMMARY_PARTS+=("Java (Maven): ℹ️ 手动: mvn install")
    else
        SUMMARY_PARTS+=("Java (Gradle): ℹ️ 手动: gradle build")
    fi
}

# ============================================================================
# 执行项目初始化
# ============================================================================

if [ ${#DETECTED_TYPES[@]} -gt 0 ]; then
    if [ ${#DETECTED_TYPES[@]} -gt 1 ]; then
        echo ""
        echo "🔍 检测到混合项目类型: ${DETECTED_TYPES[*]}"
        echo "   将分别为每种类型处理。"
    fi

    for t in "${DETECTED_TYPES[@]}"; do
        case "$t" in
            node)   install_node ;;
            python) install_python ;;
            rust)   install_rust ;;
            go)     install_go ;;
            java)   install_java ;;
        esac
    done

    if [ ${#DETECTED_TYPES[@]} -gt 1 ]; then
        echo ""
        echo "💡 多语言项目建议安装顺序："
        echo "   1. 先处理 Rust / Java（可能包含构建工具）"
        echo "   2. 再处理 Node.js / Python / Go"
    fi
else
    echo ""
    echo "💡 未检测到已知项目类型，请手动初始化开发环境。"
    SUMMARY_PARTS+=("项目类型: 未识别")
fi

# ============================================================================
# 最终汇总
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 汇总"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📂 目录:     ${TARGET_DIR}"
echo "🌿 分支:     ${BRANCH}"

if [ ${#SUMMARY_PARTS[@]} -gt 0 ]; then
    for part in "${SUMMARY_PARTS[@]}"; do
        echo "   ${part}"
    done
fi

if $DEPS_INSTALLED; then
    echo ""
    echo "🎉 开发环境已就绪！依赖已安装。"
else
    echo ""
    echo "⚠️  依赖尚未安装，请进入目录后手动安装。"
fi

echo ""
echo "💡 下一步:"
echo "   cd ${TARGET_DIR}"

# 根据实际锁文件给出精确提示
if [ -f "package.json" ] && ! $DEPS_INSTALLED; then
    if [ -f "pnpm-lock.yaml" ]; then
        echo "   pnpm install        # 安装 Node.js 依赖"
    elif [ -f "yarn.lock" ]; then
        echo "   yarn install        # 安装 Node.js 依赖"
    else
        echo "   npm install         # 安装 Node.js 依赖"
    fi
    echo "   npm test            # 运行测试"

elif [ -f "Cargo.toml" ] && ! $DEPS_INSTALLED; then
    echo "   cargo fetch         # 下载依赖"
    echo "   cargo build         # 构建项目"
    echo "   cargo test          # 运行测试"

elif ! $DEPS_INSTALLED; then
    if [ -f "uv.lock" ]; then
        echo "   uv sync             # 安装 Python 依赖"
    elif [ -f "poetry.lock" ]; then
        echo "   poetry install      # 安装 Python 依赖"
    elif [ -f "pdm.lock" ]; then
        echo "   pdm install         # 安装 Python 依赖"
    elif [ -f "pyproject.toml" ]; then
        echo "   .venv/bin/pip install .         (Linux/macOS)"
        echo "   .venv/Scripts/pip install .     (Windows)"
    elif [ -f "requirements.txt" ]; then
        echo "   .venv/bin/pip install -r requirements.txt     (Linux/macOS)"
        echo "   .venv/Scripts/pip install -r requirements.txt (Windows)"
    fi
    if [ -f ".venv/bin/activate" ]; then
        echo "   source .venv/bin/activate        # 激活虚拟环境 (Linux/macOS)"
    elif [ -f ".venv/Scripts/activate" ]; then
        echo "   source .venv/Scripts/activate    # 激活虚拟环境 (Windows Git Bash)"
    fi
    echo "   pytest              # 运行测试"
fi

if [ -f "go.mod" ]; then
    echo "   go mod download     # 下载 Go 依赖"
fi
if [ -f "pom.xml" ]; then
    echo "   mvn install         # 构建 Java 项目"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "   gradle build        # 构建 Java 项目"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
