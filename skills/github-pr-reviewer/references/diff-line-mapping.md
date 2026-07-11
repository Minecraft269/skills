# Diff Line Number Mapping Guide

## Why Line Numbers Matter

The `line` parameter of `add_comment_to_pending_review` uses the **line number from the PR diff**, which is the most error-prone part. If you use source file line numbers instead, the GitHub API returns an error:

```
The line number doesn't exist in the pull request diff
```

## Unified Diff Format

GitHub PR diffs use the unified diff format:

```diff
diff --git a/src/auth/login.ts b/src/auth/login.ts
index abc123..def456 100644
--- a/src/auth/login.ts
+++ b/src/auth/login.ts
@@ -10,7 +10,9 @@ import { hashPassword } from '../crypto';
 
 export async function login(username: string, password: string) {
-  const user = await db.findUser(username);
-  return user;
+  if (!username || !password) {
+    throw new Error('Missing credentials');
+  }
+  const user = await db.findUser(username);
+  return { id: user.id, token: generateToken(user) };
 }
```

### Key Components

| Part | Meaning |
|------|---------|
| `diff --git a/... b/...` | File identifier |
| `--- a/path` / `+++ b/path` | Old / new file path |
| `@@ -10,7 +10,9 @@` | **Hunk header** — `-<start>,<count> +<start>,<count> @@ <function context>` |
| Lines starting with `-` | Deleted code (left / old version) |
| Lines starting with `+` | Added code (right / new version) |
| Lines starting with (space) | Context lines (unchanged, for orientation) |

### Hunk Header Breakdown

`@@ -10,7 +10,9 @@ import { hashPassword } from '../crypto';`

- `-10,7`: In the old file, starts at line 10, shows 7 lines
- `+10,9`: In the new file, starts at line 10, shows 9 lines
- The trailing part is the function/class name context

## Diff Line Numbers vs Source File Line Numbers

**Key difference:** `add_comment_to_pending_review` requires the **position within the diff**, not the source file line number.

### Calculating Diff Line Numbers

In the diff text returned by the GitHub API, line numbers start counting from line 1 of the diff text itself.

```
Line 1:   diff --git a/src/auth/login.ts b/src/auth/login.ts
Line 2:   index abc123..def456 100644
Line 3:   --- a/src/auth/login.ts
Line 4:   +++ b/src/auth/login.ts
Line 5:   @@ -10,7 +10,9 @@ import { hashPassword } from '../crypto';
Line 6:    
Line 7:    export async function login(username: string, password: string) {
Line 8:   -  const user = await db.findUser(username);
Line 9:   -  return user;
Line 10:  +  if (!username || !password) {
Line 11:  +  throw new Error('Missing credentials');
...
```

To comment on the added null check (line 10):
- `line`: 10 (line number in the diff)
- `side`: "RIGHT"
- `path`: "src/auth/login.ts"

### Do NOT Use the Source Line Number from `@@`!

Incorrect: "There's added code at line 10 → use `line: 10`" — but this could coincidentally be correct...

Key pitfall: `+10,9` in the `@@` header means **in the new file** these lines start at source file line 10, **but the diff line number is completely different**. You must use the diff line number.

## Multi-Line Comments (Range Comments)

To comment on a range of code, use `startLine` + `startSide` + `line` + `side`:

```
Lines 10-14 in this diff are the newly added try-catch block:
add_comment_to_pending_review(
  path="src/auth/login.ts",
  body="This try-catch block...",
  line=14,        # Last line of the range
  side="RIGHT",
  startLine=10,   # First line of the range
  startSide="RIGHT",
  subjectType="LINE"
)
```

## File-Level Comments (Fallback)

When the diff line number cannot be determined, fall back to a file-level comment:

```
add_comment_to_pending_review(
  path="src/auth/login.ts",
  body="In the `login` function, consider adding input validation...",
  subjectType="FILE"   # No line number specified; comment attaches to the entire file
)
```

File-level comments do not require the `line`, `side`, or `startLine` parameters.

## Using the parse_diff_lines.sh Script

The script `scripts/parse_diff_lines.sh` helps extract file paths and line numbers from a diff:

```bash
# Pipe diff content into the script
cat pr_diff.txt | bash scripts/parse_diff_lines.sh

# Output format:
# file:src/auth/login.ts line:10 side:RIGHT
# file:src/auth/login.ts line:11 side:RIGHT
# file:src/auth/login.ts line:14 side:RIGHT
```

Script dependencies: `bash` (minimum 4.0), `grep`, `sed` (Windows Git Bash compatible).

## Common Errors Quick Reference

| Error | Symptom | Fix |
|-------|---------|-----|
| Using source file line numbers | `line doesn't exist in diff` | Use diff line numbers (count from line 1 of the diff text) |
| Using the `c` value from `@@ +c,d` as the line number | Comment position is off | Re-count from diff line 1 |
| Not specifying `side` | Comment not in the expected location | Use RIGHT for added code, LEFT for deleted code |
| `side` does not match code type | Comment does not appear | Use RIGHT for additions, LEFT for deletions, either for context |
| Multi-line range without startLine | Comment appears on a single line | Add startLine + startSide |
