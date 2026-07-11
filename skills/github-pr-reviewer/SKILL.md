---
name: github-pr-reviewer
description: >
  GitHub PR Code Reviewer — Creates line-by-line inline review comments on PRs using GitHub MCP tools.
  Automatically fetches the PR diff, analyzes code changes, creates a pending review, adds inline comments line by line,
  and submits a review conclusion (APPROVE/REQUEST_CHANGES/COMMENT).
  Use this skill when you need to review a PR, check code quality, or provide specific line-level suggestions on a PR.
  Should trigger even if the user simply says "review this PR" or "see what's wrong with this code".
capabilities: ["pr-review", "code-review", "inline-comments"]
integrates_with: ["pr-management", "skill-discovery"]
metadata:
  compatibility: "需要 GitHub MCP Server（plugin:github:github）"
  risk: safe
---

# GitHub PR Reviewer

Performs code reviews on GitHub Pull Requests, using GitHub MCP tools to create **line-by-line inline comments** — this is the core distinction from other review skills.

## Prerequisites

- **Required**: GitHub MCP Server (`plugin:github:github`) configured and connected
- **Optional fallback**: `gh` CLI (>= 2.0.0) — serves as a fallback when MCP is unavailable

Verify MCP tool availability on startup:

```
方法：尝试调用 pull_request_read 获取任意公开 PR 的元信息
如果失败 → 提示用户配置 GitHub MCP Server，同时启用 gh CLI 降级模式
```

## Package Linking

This skill supports linking with sibling skills within the minecraft269-skills plugin package.

**Linkage Hooks (executed only when PACKAGE_MODE = true):**

Detection method:
1. Glob search for `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. If found → PACKAGE_MODE = true, execute the linkage logic below
3. If not found → PACKAGE_MODE = false, skip all linkage references

### Phase 0 Linkage: Get context from github-pr-manager

When PACKAGE_MODE = true and the following signals are present in the conversation context, the user may have already selected a PR via github-pr-manager:

- A recent `pull_request_read` or `gh pr view` call appears in the conversation
- The user entered a PR number without specifying the repository
- A repository identifier in `owner/repo` format is present in the conversation context

**Linkage operation:**
```
如果检测到上述信号 → 主动询问用户：
「检测到你正在查看 [owner/repo] 的 PR #[N]。是否对此 PR 执行代码审查？」
- 如果用户确认 → 直接进入阶段 1，跳过仓库/PR 询问
- 如果用户拒绝 → 照常询问仓库和 PR 编号
```

### Post-Review Linkage

After the review is submitted, scan sibling skills' capabilities:

- Matches `pr-management` → Prompt: "💡 You can use **GitHub PR Manager** to view other PRs or clone this PR locally"
- Matches `skill-discovery` → Prompt: "💡 You can run **Proactive Skill Discovery** to get more tool recommendations for the current project"

In Standalone Mode (PACKAGE_MODE = false), none of the above linkage prompts are displayed.

---

## Three-Phase Review Workflow

The following three phases must be executed strictly in order. Do not proceed to the next phase until the current one is complete.

### Phase 0: Identify Target PR

Determine the PR to review. Obtain it in the following priority order:

1. **Linkage context** (PACKAGE_MODE = true): Extract the repository and PR number from github-pr-manager's session context
2. **User provides directly**: The user states the target repository and PR number (e.g., "review Minecraft269/skills #5")
3. **Ask proactively**: If neither is available, ask the user:
   ```
   「请提供要审查的 PR：
   - 仓库：owner/repo
   - PR 编号：#N」
   ```

Once obtained, immediately verify the PR exists:
```
pull_request_read(method="get", owner, repo, pullNumber)
```
If an error is returned → Prompt the user to check the repository name and PR number.

### Phase 1: Gather Review Context

Before starting the review, fetch the PR's full context in parallel. The following four calls can be made simultaneously:

```
pull_request_read(method="get_diff", owner, repo, pullNumber)
  → 获取完整 unified diff — 这是审查的核心材料

pull_request_read(method="get_files", owner, repo, pullNumber)
  → 获取变更文件列表（含每个文件的 additions/deletions/changes 统计）

pull_request_read(method="get_review_comments", owner, repo, pullNumber)
  → 获取已有 inline 审查评论 — 用于避免重复评论同一位置

pull_request_read(method="get_reviews", owner, repo, pullNumber)
  → 获取整体审查状态（已 APPROVED / CHANGES_REQUESTED / 无审查）
```

**Output:** Summarize the PR context information for the user:

| Metric | Value |
|--------|-------|
| Changed files | N |
| Lines added | +M |
| Lines deleted | -K |
| Existing reviews | X (status) |
| Existing inline comments | Y |

### Phase 2: Analyze Code and Publish Inline Comments

This is the skill's Core Value — **line-by-line inline comments**.

#### 2a. Analyze Diff, Generate Review Findings

Analyze the diff against the checklist in `references/review-checklist.md`. Each finding includes:

| Field | Description | Example |
|-------|-------------|---------|
| `path` | File relative path | `src/auth/login.ts` |
| `line` | **Line number in the diff** (see important note below) | `42` |
| `side` | `"LEFT"` (old code) or `"RIGHT"` (new code) | `"RIGHT"` |
| `body` | Comment body (structured Markdown) | See template below |
| `severity` | `critical` / `warning` / `suggestion` / `praise` | `warning` |
| `category` | `bug` / `security` / `performance` / `design` / `best-practice` / `nitpick` | `security` |

**⚠️ Line numbers are critical:** The `line` parameter of `add_comment_to_pending_review` must use the **line number from the PR diff**, not the source file line number. See `references/diff-line-mapping.md` for details. Core rules:

- In a unified diff, `@@ -a,b +c,d @@` marks the hunk position
- The diff line number for new code (starting with `+`) ≠ the source file line number
- Use the `scripts/parse_diff_lines.sh` script to help extract them
- If the correct diff line number cannot be determined, fall back to a file-level comment (`subjectType="FILE"`)

#### 2b. Display Full Review Preview (Must Show to User and Get Confirmation)

**Before calling any GitHub API**, each review finding must be displayed to the user as a complete formatted preview. See `references/review-preview-template.md` for the full preview format template.

Core rules:
- Each finding must fully expand the comment text, suggested fix, code example, and diff context
- The review model name must be obtained from the system prompt context, never fabricated
- Must wait for user confirmation before proceeding to Phase 2c

#### 2c. Create Pending Review

```
pull_request_review_write(
  method="create",
  owner, repo, pullNumber,
  body="正在审查中..."
)
```

**Do not pass the `event` parameter** — this creates a pending review, and subsequent inline comments will be added to this pending review.

**If an error is returned (existing pending review):**
- First call `pull_request_review_write(method="delete_pending", ...)` to delete the old review
- Then create it again

#### 2d. Add Inline Comments One by One

For each review finding, call `add_comment_to_pending_review` (owner, repo, pullNumber, path, body, line, side, subjectType="LINE").

See `references/comment-templates.md` for comment body templates and category icon mappings.

Adding strategy: Sort by severity (critical → warning → suggestion → praise), space out calls appropriately to avoid API rate limits, log and continue if adding fails, skip locations with existing comments.

### Phase 3: Submit Review Conclusion

#### 3a. Summary and Confirmation

Display the review completion statistics to the user:

```
## 审查完成

| 指标 | 数值 |
|------|------|
| inline 评论 | N 条（成功）/ M 条（失败）/ K 条（跳过） |
| 覆盖文件 | F 个 |
| 严重问题 | C 条 |
| 建议 | S 条 |

请选择审查结论：
```

Use `AskUserQuestion` to provide three options:
- **Approve** — Approve the merge (code quality is good, no blocking issues)
- **Request Changes** — Request modifications (there are serious issues that need fixing)
- **Comment** — Comment only (neutral, does not block the merge)

#### 3b. Submit Review

```
pull_request_review_write(
  method="submit_pending",
  owner, repo, pullNumber,
  event=<用户选择>,
  body=<审查总结>
)
```

#### 3c. Output Final Result

```
✅ 审查已提交

PR [#N](https://github.com/owner/repo/pull/N) 审查完成
- 结论：{APPROVED | CHANGES_REQUESTED | COMMENTED}
- inline 评论：N 条，覆盖 M 个文件
- 审查模型：<模型名>
```

---

## Review Focus

See `references/review-checklist.md` for the detailed checklist. Focus the review by priority:

| Priority | Category | Default Behavior |
|----------|----------|-----------------|
| P0 | Correctness defects | **Always review** |
| P1 | Security issues | **Always review** |
| P2 | Performance issues | **Always review** |
| P3 | Design issues | `--thorough` only |
| P4 | Best practices | `--thorough` only |
| P5 | Polish / nits | `--thorough` only |

---

## Error Handling and Degradation

### Error Scenario Quick Reference

| Error | Cause | Handling |
|-------|-------|----------|
| PR does not exist | Wrong number or no permission | Prompt the user to confirm the repository and PR number |
| `add_comment_to_pending_review` fails | No pending review | Create a pending review first, then retry |
| `pull_request_review_write("create")` conflict | Existing old pending review | Delete the old one first, then create a new one |
| Invalid line number | Incorrect diff line number | Check the line number → retry → if still fails, fall back to file-level comment |
| All MCP tool calls fail | GitHub MCP not configured | Switch to `gh` CLI degradation mode (see below) |
| API rate limit | Too many requests | Wait 60s and retry |

### gh CLI Degradation Mode

When GitHub MCP is unavailable:

```
# 替代阶段 1 — 获取 diff
gh pr diff <NUMBER> --repo <owner/repo>

# 替代阶段 2+3 — 发布审查（仅整体评论，无 inline）
gh pr review <NUMBER> --repo <owner/repo> --approve/--request-changes/--comment --body "..."
```

In degradation mode, inline comments cannot be published. Inform the user of this limitation and provide the review report in Markdown for manual posting.

---

## Command Quick Reference

| User input | Description |
|------------|-------------|
| `review <owner/repo> #<N>` | Review a specific PR in a specific repository |
| `review #<N>` | Review a PR in the current repository (requires linkage context) |
| `review` | Review the current PR (requires linkage context) |
| `review --thorough` | Thorough review mode (includes P3-P5) |
| `review --summary-only` | Output review summary only, do not publish to GitHub |

## Scripts

- `scripts/parse_diff_lines.sh` — Extracts file paths and corresponding diff line numbers from unified diff output. Used to help calculate the line number parameter for `add_comment_to_pending_review`.

## References

- `references/review-checklist.md` — Code review checklist, organized by P0-P5 priority levels
- `references/diff-line-mapping.md` — Unified diff format parsing and line number mapping technical guide
- `references/review-preview-template.md` — Review preview format template and important rules
- `references/comment-templates.md` — Inline comment body templates, category icon mappings, and adding strategy
