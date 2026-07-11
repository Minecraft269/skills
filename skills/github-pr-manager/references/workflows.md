# Detailed Workflow Reference

## Directory Naming Convention

In multi-repo scenarios, clone directories follow the `<owner>-<repo>-pr-<number>` format:

```
facebook-react-pr-28452/    # PR #28452 from facebook/react
lodash-lodash-pr-4528/      # PR #4528 from lodash/lodash
vuejs-core-pr-9012/         # PR #9012 from vuejs/core
```

This keeps PRs from different repositories separate and easily identifiable.

## Multi-Repository Management

The skill maintains a repository list for quick switching:

- Recently used repositories are automatically recorded (up to 10)
- `/set-repo owner/repo` adds a new repository or switches to an existing one
- `repo owner/repo` quick switch (shorthand)
- `/show-config` displays the current configuration and recent repository list

### Configuration Display Format

```
⚙️  Current Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current repo:   facebook/react
Clone path:     ./
Recent repos:
  1. facebook/react (current)
  2. lodash/lodash
  3. vuejs/core
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## PR Details Display Format

### Full Information (default, triggered when a PR number is entered)

Displays everything at once: basic details + diff + comments/reviews + commit history.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 PR #1234 Details (facebook/react)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Title:      feat: add new button component
Author:     @john_doe
Status:     🟢 OPEN | Mergeable: ✅
Branch:     feature/button → main
Created:    2026-05-28
Labels:     enhancement, UI
Files changed:   5 files (+234 / -56)
Commits:    3
🔗 Link:    https://github.com/facebook/react/pull/1234
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Description:
Added a new button component supporting multiple styles and size configurations...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Code Changes (diff) — First 200 lines:
 src/components/Button.tsx       |  45 ++++++++++++++
 src/components/Button.test.tsx  |  67 +++++++++++++++++++
 ...
 (5 files changed, full diff available via `gh pr diff 1234`)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 Review Status:
  @reviewer1 [APPROVED] — "LGTM, nice work!" (2 days ago)
  @reviewer2 [COMMENTED] — "Consider adding aria labels" (1 day ago)

💬 Comments (3):
  @dev_helper — "Do we need to update Storybook?"
    ↳ @john_doe — "Updated, in another PR #1235"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 Commit History (3):
  abc1234  @john_doe     feat: add Button component variants
  def5678  @john_doe     style: format with prettier
  ghi9012  @john_doe     test: add Button unit tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Post-Clone Initialization Flow

After cloning into `facebook-react-pr-1234/`, auto-detect the project type:

### Node.js Project
```
🔍 Detected Node.js project (package.json)
Dependencies: express, react, typescript ... (42 packages total)
Run npm install? [y/n] (default y)
```

### Python Project
```
🔍 Detected Python project (pyproject.toml)
Create virtual environment and install dependencies? [y/n] (default y)
→ python -m venv .venv && source .venv/bin/activate && pip install -e .
```

### Rust Project
```
🔍 Detected Rust project (Cargo.toml)
Run cargo build? [y/n] (default y)
```

### Completion
```
🎉 Development environment is ready!
📂 Current directory: ./facebook-react-pr-1234
🌿 Branch: feature/button
📏 Size: 12MB
```

## Custom Clone Path

Users can change the clone root directory via `/set-clone-path <path>` (default is the current directory):

```
/set-clone-path ~/dev/pr-review
```

Subsequent clones will create `~/dev/pr-review/facebook-react-pr-<number>`.

## Full Conversation Example

**User:** Show me what PRs facebook/react has

**Claude:**
```
✅ Repo set: facebook/react
Fetching open PRs...

📋 Repository: facebook/react | Open PR List
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #28452  feat: new hook useOptimistic    @sebmarkbage   3 days ago
  #28400  fix: reconcile edge case        @acdlite       1 week ago
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2 open PRs
```

**User:** Check 28452

**Claude:** [Shows PR #28452 full info: details + diff + review + commits]

**User:** Clone this

**Claude:** [Clones to facebook-react-pr-28452 → detects Node.js → npm install → done]

**User:** Switch to lodash/lodash

**Claude:** [Switches repo → shows lodash/lodash PR list]

**User:** Batch clone 4528,4500

**Claude:** [Clones to lodash-lodash-pr-4528 and lodash-lodash-pr-4500 respectively]
