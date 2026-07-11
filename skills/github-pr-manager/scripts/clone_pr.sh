#!/usr/bin/env bash
# clone_pr.sh — Clone a GitHub PR to <owner>-<repo>-pr-<number> directory and detect project type for guided initialization
# Compatibility: Git Bash (Windows), WSL2, macOS, Linux
# Usage: ./clone_pr.sh <owner/repo> <pr_number> [base_path] [options]

set -euo pipefail

# ============================================================================
# Help information
# ============================================================================
show_help() {
    cat << 'EOF'
Usage: ./clone_pr.sh <owner/repo> <pr_number> [base_path] [options]

Clone a GitHub PR to a local <owner>-<repo>-pr-<number> directory, auto-detect project type, and guide initialization.

Arguments:
  owner/repo      GitHub repository (e.g. facebook/react)
  pr_number       PR number
  base_path       Clone root directory (default: current directory)

Options:
  -y, --yes       Skip all confirmation prompts (non-interactive mode)
  --no-install    Skip any dependency installation, only clone code (highest safety level)
  --force         In non-interactive mode, auto delete and recreate if target directory exists
  --debug         Output detailed diagnostic logs
  -h, --help      Show this help

Environment variables:
  CLONE_PR_YES=1          Equivalent to -y
  CLONE_PR_NO_INSTALL=1   Equivalent to --no-install
  CLONE_PR_RUST_MODE      Rust behavior in non-interactive mode: fetch|build|check|skip (default fetch)

Examples:
  ./clone_pr.sh facebook/react 28452
  ./clone_pr.sh lodash/lodash 4528 ~/dev/pr-review -y
  ./clone_pr.sh owner/repo 123 . --no-install --debug

After review:
  Cleanup:  rm -rf <owner>-<repo>-pr-<number>
  Submit:   cd <owner>-<repo>-pr-<number> && git push  # requires repo write access
EOF
    exit 0
}

# ============================================================================
# Argument parsing
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
        --*)             echo "❌ Unknown option: $arg" >&2; exit 1 ;;
        *)               ARGS+=("$arg") ;;
    esac
done

[ "${CLONE_PR_YES:-0}" = "1" ]         && SKIP_CONFIRM=true
[ "${CLONE_PR_NO_INSTALL:-0}" = "1" ]  && NO_INSTALL=true

REPO="${ARGS[0]:?Please provide repository (owner/repo)}"
PR_NUMBER="${ARGS[1]:?Please provide PR number}"

# Cross-platform path normalization (Git Bash / WSL / macOS / Linux compatible)
BASE_PATH="${ARGS[2]:-.}"
mkdir -p "$BASE_PATH"
BASE_PATH="$(cd "$BASE_PATH" && pwd)" || {
    echo "❌ Cannot enter directory: $BASE_PATH"
    exit 1
}

REPO_SAFE="${REPO//\//-}"
TARGET_DIR="${BASE_PATH}/${REPO_SAFE}-pr-${PR_NUMBER}"

# ============================================================================
# Interrupt/exit cleanup
# ============================================================================
CLONE_DONE=false

cleanup() {
    if [ -d "$TARGET_DIR" ] && ! $CLONE_DONE; then
        echo ""
        echo "🧹 Cleaning up incomplete clone directory: ${TARGET_DIR}"
        rm -rf "$TARGET_DIR"
    fi
}
trap cleanup EXIT

# ============================================================================
# Diagnostic log
# ============================================================================
debug() { [ "$DEBUG" = true ] && echo "[DEBUG] $*" >&2; }
debug "REPO=$REPO  PR=$PR_NUMBER  BASE_PATH=$BASE_PATH"
debug "TARGET_DIR=$TARGET_DIR"
debug "SKIP_CONFIRM=$SKIP_CONFIRM  NO_INSTALL=$NO_INSTALL  FORCE_DELETE=$FORCE_DELETE"

# ============================================================================
# Helper functions
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

# Safely get directory size (Git Bash may not have du)
get_dir_size() {
    if command -v du &>/dev/null; then
        du -sh . 2>/dev/null | awk '{print $1}'
    else
        echo "N/A"
    fi
}

# ============================================================================
# Pre-checks
# ============================================================================

if ! command -v gh &>/dev/null; then
    echo "❌ GitHub CLI is required: https://cli.github.com/"
    exit 1
fi
debug "gh: $(gh --version 2>&1 | head -1)"

if ! gh auth status &>/dev/null; then
    echo "❌ Not logged into GitHub CLI, run: gh auth login"
    exit 1
fi

if [ ! -w "$BASE_PATH" ]; then
    echo "❌ Path $BASE_PATH is not writable, check permissions."
    exit 1
fi

SKIP_CLONE=false

if [ -d "$TARGET_DIR" ]; then
    echo "⚠️  Directory ${TARGET_DIR} already exists."
    if [ "$SKIP_CONFIRM" = true ]; then
        if [ "$FORCE_DELETE" = true ]; then
            echo "🔄 Auto deleting existing directory ${TARGET_DIR} ..."
            rm -rf "$TARGET_DIR"
        else
            echo "❌ In non-interactive mode, target directory already exists, refusing to auto delete."
            echo "   Handle it manually or use --force."
            exit 1
        fi
    else
        echo "   [y] Delete and re-clone"
        echo "   [n] Skip clone, detect project type in existing directory"
        echo "   [q] Cancel"
        read -r -p "Choice: " choice
        case "$choice" in
            y|Y) rm -rf "$TARGET_DIR" ;;
            n|N) SKIP_CLONE=true ;;
            *)   echo "Cancelled" && exit 0 ;;
        esac
    fi
fi

# ============================================================================
# Safety warning
# ============================================================================
cat << 'EOF'

⚠️  You are about to operate on code from a third-party PR, which may contain unreviewed content.
Installing dependencies (npm install / pip install etc.) may execute build scripts.

Please check these files for malicious scripts first:
  - "scripts" in package.json (especially preinstall / postinstall)
  - Makefile / CMakeLists.txt / build.gradle
  - Custom commands in setup.py / pyproject.toml
  - Any .sh / .bat / .ps1 files

It is recommended to review code before installing dependencies.

EOF

if [ "$NO_INSTALL" = true ]; then
    echo "🔒 --no-install mode: no dependencies will be installed this time."
fi

if [ "$SKIP_CONFIRM" = false ] && ! $SKIP_CLONE; then
    read -r -p "Continue? [y/N] " confirm
    if [ "${confirm:-N}" != "y" ] && [ "${confirm:-N}" != "Y" ]; then
        echo "Cancelled."
        exit 0
    fi
fi

# ============================================================================
# Clone workflow
# ============================================================================

if ! $SKIP_CLONE; then
    echo "🚀 Cloning PR #${PR_NUMBER} from ${REPO}..."

    if ! gh repo clone "$REPO" "$TARGET_DIR" -- --filter=blob:none 2>/dev/null; then
        echo "⚠️  Partial clone failed (possibly git version too old or server unsupported)"
        echo "   Upgrade git to >= 2.19 recommended"
        echo "   Attempting full clone..."
        if ! gh repo clone "$REPO" "$TARGET_DIR"; then
            echo "❌ Unable to clone repository $REPO"
            echo "   Check the repository name and your access permissions."
            exit 1
        fi
    fi

    cd "$TARGET_DIR"

    echo "⏳ Checking out PR branch..."
    if ! gh pr checkout "$PR_NUMBER"; then
        echo "❌ Unable to checkout PR #${PR_NUMBER}"
        echo "   Check: PR number is correct / you have read access / network is working"
        cd "$BASE_PATH"
        rm -rf "$TARGET_DIR"
        exit 1
    fi

    CLONE_DONE=true
else
    # Mark done immediately on skip to prevent cleanup from deleting user directory
    CLONE_DONE=true

    echo "📂 Using existing directory: ${TARGET_DIR}"
    if ! cd "$TARGET_DIR" 2>/dev/null; then
        echo "❌ Cannot enter directory: ${TARGET_DIR}"
        exit 1
    fi

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ Directory ${TARGET_DIR} is not a git repository."
        exit 1
    fi

    echo "🌿 Current branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
    if [ "$SKIP_CONFIRM" = false ]; then
        read -r -p "Confirm using this directory? [y/N] " ans
        [ "${ans:-n}" != "y" ] && [ "${ans:-n}" != "Y" ] && exit 0
    fi
fi

# ============================================================================
# Display clone results
# ============================================================================

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Prefer gh API for base branch
BASE_BRANCH=$(gh pr view "$PR_NUMBER" --json baseRefName --jq '.baseRefName' 2>/dev/null)
if [ -z "$BASE_BRANCH" ]; then
    BASE_BRANCH=$(git rev-parse --abbrev-ref 'HEAD@{upstream}' 2>/dev/null | sed 's|^[^/]*/||')
fi
[ -z "$BASE_BRANCH" ] && BASE_BRANCH="unknown"

SIZE=$(get_dir_size)

echo ""
echo "✅ PR #${PR_NUMBER} ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📂 Path:     ${TARGET_DIR}"
echo "🌿 Branch:     ${BRANCH}"
echo "📏 Size:     ${SIZE} (with --filter=blob:none, file content is fetched on demand)"
echo "📍 Base:     ${BASE_BRANCH}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# Node version hint (.nvmrc / .node-version)
# ============================================================================
check_node_version_hint() {
    local node_ver_file=""
    [ -f ".nvmrc" ]       && node_ver_file=".nvmrc"
    [ -f ".node-version" ] && node_ver_file=".node-version"

    if [ -n "$node_ver_file" ]; then
        local ver
        ver=$(head -1 "$node_ver_file" 2>/dev/null)
        echo ""
        echo "💡 Detected ${node_ver_file}, recommend Node.js ${ver}"
        echo "   nvm use   # or: fnm use"
    fi
}

# ============================================================================
# Project type detection (independent detection, supports hybrid / monorepo)
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

readarray -t DETECTED_TYPES < <(printf '%s\n' "${DETECTED_TYPES[@]}" | sort -u)

debug "Detected project types: ${DETECTED_TYPES[*]:-none}"

DEPS_INSTALLED=false
SUMMARY_PARTS=()

# ============================================================================
# Node.js
# ============================================================================

install_node() {
    echo ""
    echo "🔍 Detected Node.js project (package.json)"
    check_node_version_hint

    if ! confirm_or_skip "Install dependencies for Node.js?"; then
        SUMMARY_PARTS+=("Node.js: ⏭ Skipped (manual: npm install)")
        return
    fi

    if [ -f "pnpm-lock.yaml" ]; then
        if command -v pnpm &>/dev/null; then
            debug "Using pnpm"
            if pnpm install; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Node.js: ✅ pnpm")
            else
                SUMMARY_PARTS+=("Node.js: ❌ pnpm install failed")
            fi
        else
            echo "⚠️  pnpm not installed, falling back to npm ..."
            if npm install; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Node.js: ✅ npm (pnpm unavailable)")
            else
                SUMMARY_PARTS+=("Node.js: ❌ npm install failed")
            fi
        fi
    elif [ -f "yarn.lock" ]; then
        if command -v yarn &>/dev/null; then
            debug "Using yarn"
            if yarn install; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Node.js: ✅ yarn")
            else
                SUMMARY_PARTS+=("Node.js: ❌ yarn install failed")
            fi
        else
            echo "⚠️  yarn not installed, falling back to npm ..."
            if npm install; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Node.js: ✅ npm (yarn unavailable)")
            else
                SUMMARY_PARTS+=("Node.js: ❌ npm install failed")
            fi
        fi
    else
        if npm install; then
            DEPS_INSTALLED=true
            SUMMARY_PARTS+=("Node.js: ✅ npm")
        else
            SUMMARY_PARTS+=("Node.js: ❌ npm install failed")
        fi
    fi
}

# ============================================================================
# Python
# ============================================================================

install_python() {
    echo ""
    echo "🔍 Detected Python project"
    if ! confirm_or_skip "Install dependencies for Python?"; then
        local hint="pip install -r requirements.txt"
        [ -f "pyproject.toml" ] && hint="pip install ."
        SUMMARY_PARTS+=("Python: ⏭ Skipped (manual: ${hint})")
        return
    fi

    PYTHON=$(command -v python3 || command -v python)
    if [ -z "$PYTHON" ]; then
        echo "❌ Python not found, please install Python >= 3.6 first"
        SUMMARY_PARTS+=("Python: ❌ Interpreter not found")
        return
    fi
    debug "Python: $PYTHON ($($PYTHON --version 2>&1))"

    # Cross-platform version check (does not rely on sort -V)
    local py_ver
    py_ver=$("$PYTHON" --version 2>&1 | awk '{print $2}')
    if ! "$PYTHON" -c "import sys; sys.exit(0 if sys.version_info >= (3,6) else 1)" 2>/dev/null; then
        echo "❌ Python version is ${py_ver:-?}, requires >= 3.6"
        SUMMARY_PARTS+=("Python: ❌ Version ${py_ver:-?} insufficient (need >= 3.6)")
        return
    fi
    debug "Python version: $py_ver"

    # Tool detection order: uv -> poetry -> pdm -> pip
    if [ -f "uv.lock" ] && command -v uv &>/dev/null; then
        debug "Using uv"
        if uv sync; then
            DEPS_INSTALLED=true
            SUMMARY_PARTS+=("Python: ✅ uv")
        else
            SUMMARY_PARTS+=("Python: ❌ uv sync failed")
        fi
        return
    fi
    if [ -f "poetry.lock" ] && command -v poetry &>/dev/null; then
        debug "Using poetry"
        if poetry install; then
            DEPS_INSTALLED=true
            SUMMARY_PARTS+=("Python: ✅ poetry")
        else
            SUMMARY_PARTS+=("Python: ❌ poetry install failed")
        fi
        return
    fi
    if [ -f "pdm.lock" ] && command -v pdm &>/dev/null; then
        debug "Using pdm"
        if pdm install; then
            DEPS_INSTALLED=true
            SUMMARY_PARTS+=("Python: ✅ pdm")
        else
            SUMMARY_PARTS+=("Python: ❌ pdm install failed")
        fi
        return
    fi
    if [ -f "uv.lock" ] || [ -f "poetry.lock" ] || [ -f "pdm.lock" ]; then
        echo "⚠️  Lock file detected but corresponding tool unavailable, falling back to pip ..."
    fi

    # Standard venv + pip
    local d act VENV_DIR
    for d in ".venv" "venv" "env"; do
        if [ -d "$d" ]; then
            act=""
            [ -f "$d/bin/activate" ]    && act="$d/bin/activate"
            [ -f "$d/Scripts/activate" ] && act="$d/Scripts/activate"
            if [ -n "$act" ] && [ -f "$act" ]; then
                # Verify virtual environment is executable
                local test_py="${d}/bin/python"
                [ -f "${d}/Scripts/python.exe" ] && test_py="${d}/Scripts/python.exe"
                if [ -f "$test_py" ] && "$test_py" -c "print('ok')" >/dev/null 2>&1; then
                    VENV_DIR="$d"
                    debug "Reusing existing virtual environment: $d"
                    break
                fi
            fi
        fi
    done

    if [ -z "$VENV_DIR" ]; then
        VENV_DIR=".venv"
        if ! $PYTHON -m venv "$VENV_DIR"; then
            echo "❌ Cannot create virtual environment, check Python installation."
            SUMMARY_PARTS+=("Python: ❌ venv creation failed")
            return
        fi
    fi

    # Activate + install in subshell to avoid polluting current shell
    local install_ok=false
    if [ -f "$VENV_DIR/bin/activate" ]; then
        (
            source "$VENV_DIR/bin/activate"
            if [ -f "pyproject.toml" ]; then
                echo "📦 Attempting install from pyproject.toml ..."
                pip install .
            else
                pip install -r requirements.txt
            fi
        ) && install_ok=true
    elif [ -f "$VENV_DIR/Scripts/activate" ]; then
        (
            source "$VENV_DIR/Scripts/activate"
            if [ -f "pyproject.toml" ]; then
                echo "📦 Attempting install from pyproject.toml ..."
                pip install .
            else
                pip install -r requirements.txt
            fi
        ) && install_ok=true
    else
        echo "❌ Virtual environment not created properly, skipping activation"
        SUMMARY_PARTS+=("Python: ⚠️ Virtual environment abnormal")
        return
    fi

    if $install_ok; then
        DEPS_INSTALLED=true
        SUMMARY_PARTS+=("Python: ✅ pip (${VENV_DIR})")
    else
        echo "⚠️  pip install failed, please check build system configuration manually"
        SUMMARY_PARTS+=("Python: ⚠️ Install failed")
    fi
}

# ============================================================================
# Rust
# ============================================================================

install_rust() {
    echo ""
    echo "🔍 Detected Rust project (Cargo.toml)"

    if ! command -v cargo &>/dev/null; then
        echo "❌ cargo not installed, install Rust first: https://rustup.rs/"
        SUMMARY_PARTS+=("Rust: ❌ cargo unavailable")
        return
    fi

    if [ "$NO_INSTALL" = true ]; then
        SUMMARY_PARTS+=("Rust: ⏭ Not built (manual: cargo build)")
        return
    fi

    local rust_choice=""
    if [ "$SKIP_CONFIRM" = false ] && [ -t 0 ]; then
        echo ""
        echo "   [f] Fetch dependencies only (cargo fetch) — fast, no compilation"
        echo "   [b] Full build (cargo build) — may be slow"
        echo "   [c] Quick check (cargo check) — no binary output"
        echo "   [s] Skip"
        read -r -p "Choice [f/b/c/s] (default f): " rust_choice
    else
        rust_choice="${CLONE_PR_RUST_MODE:-f}"
    fi
    [ -z "$rust_choice" ] && rust_choice="f"

    # Validate value
    case "$rust_choice" in
        f|fetch)   rust_choice="f" ;;
        b|build)   rust_choice="b" ;;
        c|check)   rust_choice="c" ;;
        s|skip)    rust_choice="s" ;;
        *)
            echo "⚠️  Invalid CLONE_PR_RUST_MODE value: $rust_choice, falling back to fetch"
            rust_choice="f"
            ;;
    esac

    case "$rust_choice" in
        f)
            if cargo fetch; then
                SUMMARY_PARTS+=("Rust: ✅ Dependencies fetched")
                echo "💡 Dependencies downloaded, running cargo build will start compilation, may take some time."
            else
                SUMMARY_PARTS+=("Rust: ❌ cargo fetch failed")
            fi
            ;;
        b)
            if cargo build; then
                DEPS_INSTALLED=true
                SUMMARY_PARTS+=("Rust: ✅ cargo build")
            else
                SUMMARY_PARTS+=("Rust: ❌ cargo build failed")
            fi
            ;;
        c)
            if cargo check; then
                SUMMARY_PARTS+=("Rust: ✅ cargo check passed")
            else
                SUMMARY_PARTS+=("Rust: ❌ cargo check failed")
            fi
            ;;
        s) SUMMARY_PARTS+=("Rust: ⏭ Skipped (manual: cargo build)") ;;
    esac
}

# ============================================================================
# Go (hint only, no automatic install)
# ============================================================================

install_go() {
    echo ""
    echo "🔍 Detected Go project (go.mod)"
    SUMMARY_PARTS+=("Go: ℹ️ Use go mod (manual: go mod download)")
}

# ============================================================================
# Java (hint only, no automatic install)
# ============================================================================

install_java() {
    echo ""
    echo "🔍 Detected Java project"
    if [ -f "pom.xml" ]; then
        SUMMARY_PARTS+=("Java (Maven): ℹ️ Manual: mvn install")
    else
        SUMMARY_PARTS+=("Java (Gradle): ℹ️ Manual: gradle build")
    fi
}

# ============================================================================
# Execute project initialization
# ============================================================================

if [ ${#DETECTED_TYPES[@]} -gt 0 ]; then
    if [ ${#DETECTED_TYPES[@]} -gt 1 ]; then
        echo ""
        echo "🔍 Detected hybrid project types: ${DETECTED_TYPES[*]}"
        echo "   Will process each type separately."
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
        echo "💡 Multi-language project recommended install order:"
        echo "   1. Process Rust / Java first (may include build tools)"
        echo "   2. Then Node.js / Python / Go"
    fi
else
    echo ""
    echo "💡 No known project types detected, please initialize development environment manually."
    SUMMARY_PARTS+=("Project type: Unrecognized")
fi

# ============================================================================
# Final summary
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📂 Directory: ${TARGET_DIR}"
echo "🌿 Branch:     ${BRANCH}"

if [ ${#SUMMARY_PARTS[@]} -gt 0 ]; then
    for part in "${SUMMARY_PARTS[@]}"; do
        echo "   ${part}"
    done
fi

if $DEPS_INSTALLED; then
    echo ""
    echo "🎉 Development environment ready! Dependencies installed."
else
    echo ""
    echo "⚠️  Dependencies not yet installed, please enter the directory and install manually."
fi

echo ""
echo "💡 Next steps:"
echo "   cd ${TARGET_DIR}"

# Provide precise hints based on lock files
if [ -f "package.json" ] && ! $DEPS_INSTALLED; then
    if [ -f "pnpm-lock.yaml" ]; then
        echo "   pnpm install        # Install Node.js dependencies"
    elif [ -f "yarn.lock" ]; then
        echo "   yarn install        # Install Node.js dependencies"
    else
        echo "   npm install         # Install Node.js dependencies"
    fi
    echo "   npm test            # Run tests"

elif [ -f "Cargo.toml" ] && ! $DEPS_INSTALLED; then
    echo "   cargo fetch         # Download dependencies"
    echo "   cargo build         # Build project"
    echo "   cargo test          # Run tests"

elif ! $DEPS_INSTALLED; then
    if [ -f "uv.lock" ]; then
        echo "   uv sync             # Install Python dependencies"
    elif [ -f "poetry.lock" ]; then
        echo "   poetry install      # Install Python dependencies"
    elif [ -f "pdm.lock" ]; then
        echo "   pdm install         # Install Python dependencies"
    elif [ -f "pyproject.toml" ]; then
        echo "   .venv/bin/pip install .         (Linux/macOS)"
        echo "   .venv/Scripts/pip install .     (Windows)"
    elif [ -f "requirements.txt" ]; then
        echo "   .venv/bin/pip install -r requirements.txt     (Linux/macOS)"
        echo "   .venv/Scripts/pip install -r requirements.txt (Windows)"
    fi
    if [ -f ".venv/bin/activate" ]; then
        echo "   source .venv/bin/activate        # Activate virtual environment (Linux/macOS)"
    elif [ -f ".venv/Scripts/activate" ]; then
        echo "   source .venv/Scripts/activate    # Activate virtual environment (Windows Git Bash)"
    fi
    echo "   pytest              # Run tests"
fi

if [ -f "go.mod" ]; then
    echo "   go mod download     # Download Go dependencies"
fi
if [ -f "pom.xml" ]; then
    echo "   mvn install         # Build Java project"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "   gradle build        # Build Java project"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
