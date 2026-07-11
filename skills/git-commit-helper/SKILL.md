---
name: git-commit-helper
description: >
  Git Commit Standardization Helper — automatically analyzes staged diff to determine change types
  and generates commit messages conforming to the Conventional Commits specification.
  Use this skill when you need to commit code, write a standardized commit message,
  organize the git staging area, or are unsure how to write a commit.
capabilities: ["git-commit"]
integrates_with: ["pr-management", "code-review"]
metadata:
  compatibility: "Requires git"
---

# Git Commit Standardization Helper

Intelligently analyzes staged diff changes and generates commit messages conforming to the [Conventional Commits](https://www.conventionalcommits.org/) specification. Purely AI-driven, no additional script dependencies required.

## Package Linking

1. Glob search for `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. If found → `PACKAGE_MODE = true`, can discover and link with sibling skills
3. If not found → `PACKAGE_MODE = false`, skip all cross-skill logic (silent degradation)

When `PACKAGE_MODE = true`:
- After commit, can link with `integrates_with: pr-management` (PR management)
- After commit, can link with `integrates_with: code-review` (code review)
- Scan sibling SKILL.md `capabilities` fields for intersection matching

See `_shared/package-context.md` for details.

## Core Workflow

### 1. Detect Staging Area State

```bash
git status --short
git diff --staged --stat
git diff --staged
```

First check if the staging area has changes. If not, prompt the user:

```markdown
📭 The staging area is empty. Please use `git add <file>` to add the changes you want to commit.

Current workspace changes (unstaged):
<output of git status --short>

Would you like me to help you organize the staging area?
```

### 2. Analyze Changes and Generate Message

Analyze changes based on `git diff --staged` content and generate a Conventional Commits format commit message.

**Analysis Dimensions:**
- **Type Inference**: Determine the type based on the nature of the change
- **Scope Extraction**: Extract the scope from changed file paths
- **Subject Writing**: One sentence describing the core change, plus optional multi-line bullet points

**Type Inference Rules:**

| Type | Criteria |
|------|---------|
| `feat` | New feature, new file, new API endpoint, new component |
| `fix` | Bug fix, logic error correction, null pointer/null value fix |
| `docs` | Only documentation changes (`*.md`, comments, README) |
| `style` | Formatting, whitespace, semicolons, etc. — adjustments not affecting code logic |
| `refactor` | Refactoring (neither new feature nor bug fix, but changes code structure) |
| `perf` | Performance optimization (loop reduction, caching, algorithm improvements) |
| `test` | Adding or modifying tests |
| `chore` | Build configuration, dependency updates, CI/CD, `.gitignore`, etc. |
| `ci` | CI/CD pipeline changes |
| `build` | Build system or external dependency changes |

**Scope Extraction Rules:**
- Extract the common prefix from changed file paths (e.g. `skills/github-pr-manager` → `github-pr-manager`)
- Single-file change: use the file name as the scope
- Multi-module change: use the most frequent path or `multiple`
- Can be omitted when no clear scope exists

**Generated Format:**
```
<type>(<scope>): <short description>

<detailed description (optional, multi-line bullet points)>

BREAKING CHANGE: <description of breaking change (if any)>
```

**Example Output:**
```
feat(git-commit-helper): add automatic commit message generation based on staged diff

- Automatically analyze changes to infer type and scope
- Support Conventional Commits specification
- Interactive preview and editing before commit
- Link to PR management and code review after commit
```

### 3. Preview and Confirm

After generating the message, present it to the user in a fully formatted preview:

```markdown
## 📝 Commit Preview

```
feat(git-commit-helper): add automatic commit message generation based on staged diff

- Automatically analyze changes to infer type and scope
- Support Conventional Commits specification
- Interactive preview and editing before commit
```

| Item | Detail |
|------|--------|
| 📂 Changed files | N |
| 🏷️ Type | feat |
| 🎯 Scope | git-commit-helper |
| 📏 Lines | +X / -Y |

---

Please choose:
1. ✅ **Confirm** — Execute `git commit` directly
2. ✏️ **Edit** — Modify type / scope / description
3. 🔄 **Regenerate** — Re-analyze from a different perspective
4. 📝 **Manual** — Write the commit message yourself
5. ❌ **Cancel** — Do nothing
```

**Important: Wait for the user's choice before proceeding to the next step.**

### 4. Execute Commit and Link

**Execute after confirmation:**
```bash
git commit -m "<message>"
```

**Linkage after successful commit (only when PACKAGE_MODE = true):**

Check for GitHub remote:
```bash
git remote get-url origin 2>/dev/null
```

- If a GitHub remote exists → prompt: `💡 Changes committed. Would you like to push and create a PR?` (matches `pr-management`)
- If functional code changes are involved → prompt: `💡 Would you like to run a code review before pushing the PR?` (matches `code-review`)

## Conventional Commits Quick Reference

### Format
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Type Quick Reference
- `feat` — New feature
- `fix` — Bug fix
- `docs` — Documentation
- `style` — Formatting (does not affect code logic)
- `refactor` — Refactoring
- `perf` — Performance optimization
- `test` — Tests
- `chore` — Build/tooling/dependencies
- `ci` — CI/CD
- `build` — Build system

### Breaking Change
- Prefix the body or footer with `BREAKING CHANGE:`
- Or append `!` after type/scope: `feat(api)!: Redesign user API`

## Error Handling

| Scenario | Handling |
|----------|---------|
| Empty staging area | Show unstaged changes, prompt user to `git add` |
| Not in a git repository | Prompt to initialize with `git init` or switch to a repository directory |
| Diff too large (>500 lines) | Analyze only the first 500 lines, annotate as "only the first 500 lines were analyzed" |
| Change type is ambiguous | List 2-3 possible types and ask the user to choose |
| `git commit` fails | Display the error, offer retry or manual input |
| pre-commit hook fails | Display hook output, prompt to fix and retry |
