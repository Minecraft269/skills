# github-pr-manager

Full-featured GitHub PR manager — list, view, clone, and analyze GitHub Pull Requests in the terminal.

## Core Features

- List all open PRs for a repository (table display, supports pagination)
- View complete PR info: details, diff, comments, review status, commit history
- Clone PRs locally with automatic project type detection (Node/Python/Rust/Go/Java) and environment initialization
- CI status viewing and failure analysis
- Multi-repository switching and batch operations

## Prerequisites

- `gh` (GitHub CLI ≥ 2.0.0)
- `git`
- `jq`

## Command Quick Reference

| Input | Description |
|-------|-------------|
| `<number>` | View full PR info (default behavior) |
| `c <number>` | Clone PR and initialize |
| `d <number>` | View details only |
| `diff <number>` | View code changes |
| `comments <number>` | View comments and reviews |
| `commits <number>` | View commit history |
| `batch clone <n1>,<n2>` | Batch clone |
| `batch view <n1>,<n2>` | Batch view |
| `r` | Refresh PR list |
| `repo <owner/repo>` | Switch repository |

## Related Skills

This skill is part of the [minecraft269-skills](https://github.com/Minecraft269/skills) plugin package. When the full package is installed, this skill can auto-link with other package skills:

- After cloning a PR, automatically suggests project kickoff flow and skill discovery
- Auto-recommended by the proactive skill discovery engine for GitHub projects

When installed standalone, the above linkage features are silently disabled, with no impact on core PR management functionality.
