# Error Handling Reference

## Error Scenarios and Handling

| Error Scenario | Detection Method | Handling Method |
|----------|----------|----------|
| `gh` not installed | `which gh` returns empty | Prompt to install: https://cli.github.com/ |
| `gh` not logged in | `gh auth status` non-zero | Prompt to run `gh auth login` |
| Repository does not exist | `gh pr list` returns 404 | "Repository owner/repo does not exist or is not accessible. Please check the spelling or your permissions." |
| No open PRs | `gh pr list` returns empty array | "This repository currently has no open PRs." |
| Invalid PR number | `gh pr view` returns "not found" | "PR #xxxx not found. Please check the number or press r to refresh the list." |
| Target directory already exists | `test -d <owner>-<repo>-pr-<number>` | Prompt `[y]` delete and recreate / `[n]` skip and enter directly / `[q]` cancel |
| Insufficient disk space | `df -h` check | Prompt to free up space or use `/set-clone-path` to change the path |
| Clone failed (network) | `gh pr checkout` timeout | Check network, suggest retry; offer `--depth 1` shallow clone |
| Clone failed (permissions) | Returns 403 | Check repository permissions (private repos require `gh auth` scope) |
| `jq` not installed | `which jq` returns empty | Fall back to raw JSON output, prompt to install jq for better formatting |
| Repository has 50+ PRs | Return count = limit | "Showing only the 50 most recent PRs. Use `--limit 100` to see more." |

## Graceful Degradation Principles

- No missing tool should block the core workflow
- `jq` missing → use `gh` built-in `--jq` or raw output
- `gh` version too old → degrade to compatible commands
- Network error → retry once, then give clear next steps

## User Feedback Pattern

Always:
1. Clearly explain what went wrong
2. Describe possible causes
3. Provide concrete resolution steps
4. Offer alternative approaches (if available)

### Example

```
❌ Failed to clone PR #1234

Cause: Network connection timed out (gh cannot reach api.github.com)

Suggestions:
  1. Check your network connection
  2. Verify gh auth status is working
  3. Retry: enter c 1234

Alternative:
  Clone manually:
  git clone https://github.com/owner/repo.git owner-repo-pr-1234
  cd owner-repo-pr-1234
  gh pr checkout 1234
```
