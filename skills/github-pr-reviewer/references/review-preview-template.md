# Review Preview Template

Before calling any GitHub API, each review finding must be presented to the user as a fully formatted preview. It is forbidden to display findings in MCP tool call parameter format — the user needs to see the complete comment content that will eventually appear on the PR.

## Preview Format

```
## 🔍 PR Review Preview

**Repository:** owner/repo
**PR:** #[N] — PR title
**Review Model:** <current model name>
**Review Time:** <current time>

---

### Finding #1 — 🔒 Security · critical

**File:** `src/auth/login.ts`
**Diff Line:** Line 42 (RIGHT side — new code)
**Category:** security
**Severity:** critical

---

📝 **Inline comment to be posted:**

The current code passes `password` directly to `hashPassword()` when it is `null` or `undefined`,
which may cause a runtime exception or unsafe hash result.

**Suggested Fix:**
```typescript
if (!password) {
  throw new BadRequestError('Password cannot be empty');
}
const hashed = await hashPassword(password);
```

📋 **Relevant diff context:**
```diff
@@ -38,6 +38,8 @@ export async function login(username: string, password: string) {
   // Validate username
   const user = await db.findUser(username);
   ...
```

---

...(each finding fully expanded)...

---

## 📊 Review Statistics

| Severity | Count |
|---------|------|
| 🔴 critical | X |
| 🟡 warning | Y |
| 🔵 suggestion | Z |
| 🟢 praise | P |

---

## ⏳ Awaiting Confirmation

You can:
- Reply **"confirm"** → start posting with the default scope (P0-P2)
- Reply `--all` → post all findings (including P3-P5)
- Reply `--select 1,3,5` → post only the specified indices
- Reply **"edit #N"** → edit the Nth finding
```

## Important Rules

- Each finding must display the full comment text (problem description + suggested fix + code example)
- Each finding must include relevant diff context (including `@@` hunk headers)
- The review model name must be obtained from the system prompt context — never fabricated
- Must wait for user confirmation before creating a pending review
