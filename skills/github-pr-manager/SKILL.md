---
name: github-pr-manager
description: >
  GitHub PR full-featured manager — specify a repo, list PRs, view details and diff,
  view comments and review status, view commit history, clone PR code locally to
  owner/repo-pr-N directory with automatic dev environment initialization, supports
  multi-repo switching and batch operations. Use this skill when you need to manage
  GitHub pull requests, clone PRs, view code reviews, inspect PR commits, batch-process
  multiple PRs, or any operation related to GitHub pull requests — trigger even if
  the user doesn't explicitly say "PR management" as long as GitHub repository pull
  requests are involved.
capabilities: ["pr-management", "ci-analysis", "code-cloning"]
integrates_with: ["project-setup", "skill-discovery"]
metadata:
  compatibility: "需要 gh (GitHub CLI ≥ 2.0.0), git, jq"
---

# GitHub PR Manager

Manage Pull Requests for any GitHub repository: list, view details/diff/comments/commits, clone locally, batch operations.

## Core Philosophy

This skill lets you operate remote PRs as if they were local git branches. Each PR is cloned to an independent directory `<owner>-<repo>-pr-<number>`, directories never interfere, and multi-repo parallel management stays clean.

## Prerequisites

- `gh` (GitHub CLI >= 2.0.0): `gh auth status` to confirm login
- `git`, `jq` (for JSON formatting, falls back to raw output if missing)

## Package Linking

This skill supports automatic linking with other skills in the minecraft269-skills plugin package. The following detection is performed:

1. Glob search for `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. If found -> `PACKAGE_MODE = true`, can discover and link sibling skills
3. If not found -> `PACKAGE_MODE = false`, skip all cross-skill logic (silent degradation, no error)

When `PACKAGE_MODE = true`:
- After cloning a PR, can link with `integrates_with: project-setup` (project initialization flow) and `integrates_with: skill-discovery` (skill discovery)
- Scan the `capabilities` field of sibling SKILL.md files, match against this skill's `integrates_with` tags
- Only show linking hints when a match succeeds

See `_shared/package-context.md` for details.

## Core Workflow

### 1. Set Repository

The user must specify a repository in `owner/repo` format. If the user does not provide one, proactively ask:

> "Please provide a GitHub repository (format: owner/repo, e.g. facebook/react)"

Supports `/set-repo owner/repo` to switch repositories. In multi-repo scenarios, remember the most recently used repository list.

After setting the repository, **automatically execute `/list-pr` to show all open PRs.**

### 2. List PRs

```bash
gh pr list --repo <repo> --state open --json number,title,author,headRefName,createdAt,labels --limit 50
```

Display as a clear table:

```
📋 Repo: owner/repo | Open PR List
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #1234  feat: add new button component    @john_doe   🏷 enhancement  2d ago
  #1235  fix: resolve memory leak          @jane_dev   🐛 bug         5h ago
  #1236  docs: update API reference        @dev_sam    📖 docs        1w ago
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3 open PRs
```

**User options (conversational, no need to memorize commands):**
- Enter a PR number (e.g. `1234`) -> View full PR info (details + diff + comments + commits)
- `c <number>` -> Clone PR and initialize dev environment
- `d <number>` -> View PR details only
- `diff <number>` -> View PR code change summary
- `comments <number>` -> View PR comments and review status
- `commits <number>` -> View PR commit history
- `batch clone <number1>,<number2>,...` -> Batch clone multiple PRs
- `r` -> Refresh list
- `repo <owner/repo>` -> Switch repository

### 3. PR Full Info (Default Behavior)

When the user enters a PR number, display all at once:

#### 3a. Basic Info

```bash
gh pr view <number> --repo <repo> --json title,body,author,state,mergeable,changedFiles,commits,url,headRefName,baseRefName,createdAt,labels
```

#### 3b. Code Changes (diff)

```bash
gh pr diff <number> --repo <repo> | head -200
```

Show the list of changed files and key diffs (truncated to 200 lines, prompt the user they can view the full diff).

#### 3c. Comments and Reviews

```bash
gh pr view <number> --repo <repo> --json reviews,comments
```

Show review status (APPROVED/CHANGES_REQUESTED/COMMENTED) and latest comment summary.

#### 3d. Commit History

```bash
gh pr view <number> --repo <repo> --json commits --jq '.commits[] | "\(.oid[:7]) \(.author.name) \(.messageHeadline)"'
```

Show author, short hash, and commit message.

### 4. Clone PR Locally

```bash
# See scripts/clone_pr.sh — full clone and initialization flow
```

Flow:
1. Check if `<owner>-<repo>-pr-<number>` already exists -> prompt overwrite/skip
2. Execute `gh pr checkout <number> --repo <repo>` or manual fetch + checkout
3. Show clone result: path, branch, size
4. Detect project type and guide initialization:
   - **Node.js** (`package.json`) -> Ask whether to `npm install`
   - **Python** (`requirements.txt`/`pyproject.toml`) -> Ask whether to create venv
   - **Rust** (`Cargo.toml`) -> Ask whether to `cargo build`
   - **Other** -> Prompt manual initialization

**Linking hooks (only when PACKAGE_MODE = true):**

After cloning completes, scan sibling skills' `capabilities` against this skill's `integrates_with` for intersection matching:
- Match `project-setup` -> Prompt: "This is your first time with this project? Use **Universal Project Kickoff** to quickly understand the project structure and conventions."
- Match `skill-discovery` -> Prompt: "A new project type [tech stack] has been detected. Would you like to run **Proactive Skill Discovery** to recommend matching skills and plugins for this project?"

### 5. Batch Operations

**Batch clone:** `batch clone 1234,1235,1236`

Execute the clone flow for each PR sequentially and summarize results:

```
🚀 Batch clone 3 PRs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ #1234 -> ./facebook-react-pr-1234  (Node.js, npm install done)
✅ #1235 -> ./facebook-react-pr-1235  (Python, venv created)
❌ #1236 -> Directory already exists, skipped
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Batch view:** `batch view 1234,1235,1236` — Display summary info for each PR in sequence.

## Command Quick Reference

| Input | Description |
|-------|-------------|
| `<number>` | View PR full info (default behavior) |
| `/set-repo <owner/repo>` | Set/switch repository |
| `c <number>` | Clone PR and initialize |
| `d <number>` | View details only |
| `diff <number>` | View code changes |
| `comments <number>` | View comments and reviews |
| `commits <number>` | View commit history |
| `batch clone <n1>,<n2>` | Batch clone |
| `batch view <n1>,<n2>` | Batch view |
| `r` | Refresh PR list |
| `repo <owner/repo>` | Switch repository |

## Scripts

- `scripts/list_prs.sh` — List open PRs for a repository (JSON -> formatted table, supports `-a` pagination)
- `scripts/view_pr.sh` — Get full PR info (details+diff+comments+commits, supports `-d`/`-v`/`-a`)
- `scripts/clone_pr.sh` — Clone PR and detect project type, supports multi-language auto-initialization
- `scripts/ci_pr.sh` — View CI status, analyze failures, rerun failed jobs (`--analyze`/`--rerun`/`--wait`)

## Detailed References

- `references/workflows.md` — Full workflow details, example conversations, multi-repo management
- `references/error-handling.md` — All error scenarios and handling approaches
