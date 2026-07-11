# git-commit-helper

Analyzes `git diff --staged` changes and automatically generates commit messages conforming to [Conventional Commits](https://www.conventionalcommits.org/).

## Prerequisites

- `git`

## Trigger

Say "help me commit", "generate commit message", or "commit changes" to trigger.

## Workflow

1. Detect staging area (`git status --short`)
2. Analyze `git diff --staged` to infer type (feat/fix/docs etc.) and scope
3. Preview the generated commit message and wait for confirmation
4. Execute `git commit` and link to PR management/review

## Interactive Options

| Option | Action |
|--------|--------|
| ✅ Confirm | Commit directly |
| ✏️ Edit | Modify type/scope/description |
| 🔄 Retry | Re-analyze |
| 📝 Manual | Write manually |
| ❌ Cancel | Do not commit |

## Linkage

- After commit, if a GitHub remote exists → suggest **PR Manager**
- When code changes are involved → suggest **Code Review**
