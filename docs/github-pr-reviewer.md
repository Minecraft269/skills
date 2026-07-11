# github-pr-reviewer — GitHub PR Code Reviewer

Performs code review on GitHub Pull Requests, creating **line-by-line inline review comments** using GitHub MCP tools.

## Features

- ✅ Automatically pulls PR diff and context (file list, existing reviews, comments)
- ✅ Analyzes code changes by P0-P5 priority
- ✅ Creates pending review → line-by-line inline comments → submits review conclusion
- ✅ Supports APPROVE / REQUEST_CHANGES / COMMENT review decisions
- ✅ Context linkage with github-pr-manager
- ✅ Automatic fallback to `gh` CLI when MCP is unavailable
- ✅ Review results annotated with the reviewing model

## Prerequisites

- GitHub MCP Server (`plugin:github:github`)
- `gh` CLI (optional, fallback option)

## Usage

```
review #5                          # Review PR #5 in current repo
review owner/repo #123             # Review PR in specified repo
review --thorough                  # Full review (includes P3-P5 suggestions)
review --summary-only              # Output review summary only, no publishing
```

## Three-Phase Workflow

```
Phase 0: Identify PR → Phase 1: Pull diff + context → Phase 2: Line-by-line inline comments → Phase 3: Submit review
```

The review preview displays the full content and code context of each comment. Publishing to GitHub only occurs after user confirmation.

## Comparison with Existing Review Skills

| Feature | github-pr-reviewer | code-review | pr-review-toolkit |
|---------|-------------------|-------------|-------------------|
| Inline comments (add_comment_to_pending_review) | ✅ | ❌ | ❌ |
| Full pending review lifecycle | ✅ | ❌ | ❌ |
| User review before publishing | ✅ | ❌ | ❌ |
| Review model annotation | ✅ | ❌ | ❌ |
| Diff code context display | ✅ | Partial | Partial |
