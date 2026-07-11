# Code Review Checklist

This document defines the items to check during PR review, organized by severity (P0-P5). Reviewers should inspect code changes in the diff by priority level.

---

## P0 — Correctness Defects (Always Review)

These are the most severe issues. When found, they must be marked as `severity: critical` in inline comments.

### Logic Errors

- [ ] **Inverted condition** — `if` / `while` condition is the opposite of what was intended
- [ ] **Wrong operator** — `>` vs `>=`, `&&` vs `||` confusion
- [ ] **Loop boundary errors** — start/end conditions cause one too many or one too few iterations (off-by-one)
- [ ] **Wrong return value** — function returns the wrong value or type
- [ ] **Missing early return** — execution continues in a boundary case where it should have returned early

### Null Values and Boundaries

- [ ] **Null/undefined access** — calling methods or properties on a value that may be null/undefined
- [ ] **Array index out of bounds** — index may exceed array length
- [ ] **Division by zero** — denominator in a division operation may be zero
- [ ] **Empty collection handling** — not handling cases of empty arrays, empty strings, or empty Maps
- [ ] **Regex match failure** — accessing `.match()` results directly when it may return null

### Types and Conversions

- [ ] **Type coercion errors** — `==` vs `===` confusion, implicit coercion causing unexpected behavior
- [ ] **Precision loss** — floating point precision issues in comparisons/operations (especially monetary calculations)
- [ ] **Integer overflow** — large number operations without overflow consideration
- [ ] **Date/timezone errors** — time parsing without timezone specification, date comparisons

### Concurrency and State

- [ ] **Race conditions** — missing synchronization between async operations
- [ ] **State inconsistency** — no rollback after optimistic update failure
- [ ] **Deadlock** — lock acquisition order may cause deadlock

---

## P1 — Security Issues (Always Review)

Mark as `severity: critical` or `severity: warning`.

### Injection Prevention

- [ ] **SQL injection** — building SQL queries with string concatenation (should use parameterized queries or ORM)
- [ ] **NoSQL injection** — user input passed directly to MongoDB/Redis queries
- [ ] **Command injection** — unsanitized user input used in `exec()` / `spawn()` / `subprocess`
- [ ] **XSS** — user input inserted directly into HTML (should use escaping or safe DOM APIs)
- [ ] **Path traversal** — file paths containing unsanitized `../`

### Authentication and Authorization

- [ ] **Authentication bypass** — sensitive endpoints missing auth middleware
- [ ] **Missing authorization** — operations don't check if user has permission
- [ ] **Incomplete JWT validation** — signature, expiration, or issuer not verified
- [ ] **Session fixation** — session ID not regenerated after login

### Sensitive Data

- [ ] **Hardcoded secrets/tokens** — API keys, passwords, private keys written in code
- [ ] **Sensitive information in logs** — `console.log` / `log.info` printing passwords, tokens, user data
- [ ] **Insecure transmission** — sensitive data sent over plaintext HTTP
- [ ] **Error information leakage** — error responses exposing database structure, stack traces

### Cryptography

- [ ] **Weak encryption algorithm** — using MD5, SHA1 for security hashing
- [ ] **Insecure random numbers** — using `Math.random()` to generate tokens/passwords
- [ ] **Missing encryption** — passwords stored without bcrypt/argon2 hashing

---

## P2 — Performance Issues (Always Review)

Mark as `severity: warning`.

### Database and I/O

- [ ] **N+1 queries** — querying the database one row at a time in a loop (should use JOIN or batch queries)
- [ ] **Missing index** — newly added WHERE/ORDER BY columns may lack an index
- [ ] **Full table scan** — query conditions cannot use indexes
- [ ] **Large transactions** — transactions containing time-consuming operations

### Network and Rendering

- [ ] **Unnecessary data transfer** — API returns many fields the frontend doesn't need
- [ ] **Duplicate requests** — multiple API calls for the same data (should use caching or deduplication)
- [ ] **Unnecessary re-renders** — React/Vue components re-rendering when props haven't changed
- [ ] **Large files without pagination** — list endpoint returning all data at once

### Memory

- [ ] **Memory leaks** — event listeners not removed, timers not cleared, closures holding references to large objects
- [ ] **Large object copies** — unnecessary deep copies of large arrays/objects
- [ ] **Unnecessary data retention** — one-time computation results cached indefinitely

### Algorithms

- [ ] **O(n²) or higher nested loops** — nested iteration over large data sets
- [ ] **Unnecessary sorting** — calling sort when order is not required

---

## P3 — Design Issues (Thorough Mode Only)

Mark as `severity: suggestion`.

- [ ] **Single responsibility violation** — a function/class doing multiple unrelated things
- [ ] **Excessive coupling** — modules depending on concrete types rather than interfaces
- [ ] **Circular dependency** — module A depends on B, B depends on A
- [ ] **God class/god function** — a class/function taking on too many responsibilities
- [ ] **Duplicate code** — the same logic appearing in multiple places (more than 3)
- [ ] **Magic numbers** — unnamed hardcoded numeric values

---

## P4 — Best Practices (Thorough Mode Only)

Mark as `severity: suggestion`.

- [ ] **Unclear naming** — variable/function names don't convey their purpose
- [ ] **Missing error handling** — missing try-catch or empty catch blocks
- [ ] **Missing documentation** — public APIs without JSDoc/Python docstrings
- [ ] **Missing tests** — new critical logic without test cases
- [ ] **Outdated comments** — comments describing behavior that no longer matches the code
- [ ] **Not following project style** — indentation, quotes, naming inconsistent with project conventions

---

## P5 — Nice-to-Have (Thorough Mode Only)

Mark as `severity: suggestion` or `severity: praise`.

- [ ] **Better naming suggestion** — alternative names that are more expressive
- [ ] **Minor optimization** — using more concise syntax or built-in methods
- [ ] **Praiseworthy code** — clear logic, good comments, elegant design (`severity: praise`)
- [ ] **Optional code simplification** — more concise but equivalent expression available

---

## Review Principles

1. **Understand first, critique second** — before criticizing, ensure you understand the author's intent
2. **Be specific, not vague** — "this could NPE" is worse than "line 42 `user.name` will throw TypeError when `user` is null"
3. **Suggest, don't command** — "consider using `Array.find()` instead of a manual loop" rather than "must use find instead"
4. **Include fix suggestions** — provide code examples when pointing out issues
5. **Balance positive and negative feedback** — good code deserves praise too
6. **Don't block non-critical issues** — use COMMENT instead of REQUEST_CHANGES for P3 and below
