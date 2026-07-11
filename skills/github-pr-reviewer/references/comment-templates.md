# Review Comment Templates

## Comment Body Structure

```
**🔒 [Security] Password validation missing null check**

The current code passes `password` directly to `hashPassword()` when it is `null` or `undefined`,
which may cause a runtime exception or produce insecure hash results.

**Suggested Fix:**
```typescript
if (!password) {
  throw new BadRequestError('Password cannot be empty');
}
const hashed = await hashPassword(password);
```
```

1. **Bold title**: `**[Icon] [Category] Short problem description**`
2. **Problem description**: 1-3 sentences explaining the current code issue and its potential impact
3. **Suggested fix** (optional): Specific fix with code example

## Category Icon Mapping

| Category | Icon | Name |
|----------|------|------|
| bug | 🐛 | Bug |
| security | 🔒 | Security |
| performance | ⚡ | Performance |
| design | 🏗️ | Design |
| best-practice | 📐 | Best Practice |
| nitpick | 💭 | Suggestion |
| praise | 👍 | Praise |

## Severity Levels

| Severity | Description | Blocks Merge |
|----------|-------------|-------------|
| critical | Critical defect or security vulnerability that must be fixed | Yes |
| warning | Code that may cause issues | Recommended to fix |
| suggestion | Improvement suggestion | No |
| praise | Well-written code | No |

## Addition Strategy

- Sort by severity: critical → warning → suggestion → praise
- Space out comments appropriately to avoid triggering GitHub API rate limits
- Log the entry on failure and continue with the next one
- Skip positions where a comment already exists to avoid duplicates
