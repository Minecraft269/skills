# Diff 行号映射指南

## 为什么行号很重要

`add_comment_to_pending_review` 的 `line` 参数使用 **PR diff 中的行号**，这是最容易出错的地方。如果使用源文件行号，GitHub API 会返回错误：

```
The line number doesn't exist in the pull request diff
```

## Unified Diff 格式

GitHub PR diff 使用 unified diff 格式：

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

### 关键组成

| 部分 | 含义 |
|------|------|
| `diff --git a/... b/...` | 文件标识 |
| `--- a/path` / `+++ b/path` | 旧/新文件路径 |
| `@@ -10,7 +10,9 @@` | **Hunk 头部** — `-<起始>,<行数> +<起始>,<行数> @@ <函数上下文>` |
| `-` 开头的行 | 被删除的代码（左侧/旧版本） |
| `+` 开头的行 | 新增的代码（右侧/新版本） |
| (空格)开头的行 | 上下文行（未变更，用于定位） |

### Hunk 头部解读

`@@ -10,7 +10,9 @@ import { hashPassword } from '../crypto';`

- `-10,7`：旧文件中从第 10 行开始，显示 7 行
- `+10,9`：新文件中从第 10 行开始，显示 9 行
- 末尾是函数/类名上下文

## Diff 行号 vs 源文件行号

**关键区别：** `add_comment_to_pending_review` 需要的是 **diff 中该行的位置**，不是源文件行号。

### 计算 diff 行号

从 GitHub API 返回的 diff 文本中，行号从 diff 文本的第 1 行开始计数。

```
第 1 行:  diff --git a/src/auth/login.ts b/src/auth/login.ts
第 2 行:  index abc123..def456 100644
第 3 行:  --- a/src/auth/login.ts
第 4 行:  +++ b/src/auth/login.ts
第 5 行:  @@ -10,7 +10,9 @@ import { hashPassword } from '../crypto';
第 6 行:   
第 7 行:   export async function login(username: string, password: string) {
第 8 行:  -  const user = await db.findUser(username);
第 9 行:  -  return user;
第 10 行: +  if (!username || !password) {
第 11 行: +    throw new Error('Missing credentials');
...
```

如果要对新增的空值检查（第 10 行）发表评论：
- `line`: 10（diff 中的行号）
- `side`: "RIGHT"
- `path`: "src/auth/login.ts"

### 不是用 `@@` 中的源文件行号！

❌ **错误**：「第 10 行有新增代码」→ 使用 `line: 10` — 但这可能是正确的…

关键陷阱：`@@` 中 `+10,9` 表示**新文件中**这些行从源文件第 10 行开始，**但 diff 行号完全不同**。你要用的是 diff 行号。

## 多行评论（范围评论）

要评论一个代码段，使用 `startLine` + `startSide` + `line` + `side`：

```
该 diff 中第 10-14 行是新增的 try-catch 块：
add_comment_to_pending_review(
  path="src/auth/login.ts",
  body="这个 try-catch 块...",
  line=14,        # 范围的最后一行
  side="RIGHT",
  startLine=10,   # 范围的第一行
  startSide="RIGHT",
  subjectType="LINE"
)
```

## 文件级评论（降级方案）

当无法确定 diff 行号时，降级为文件级评论：

```
add_comment_to_pending_review(
  path="src/auth/login.ts",
  body="在 `login` 函数中，建议增加输入验证...",
  subjectType="FILE"   # 不指定行号，评论附加到整个文件
)
```

文件级评论不需要 `line`、`side`、`startLine` 参数。

## 使用 parse_diff_lines.sh 脚本

脚本 `scripts/parse_diff_lines.sh` 可以帮助从 diff 中提取文件路径和行号：

```bash
# 将 diff 内容传入脚本
cat pr_diff.txt | bash scripts/parse_diff_lines.sh

# 输出格式：
# file:src/auth/login.ts line:10 side:RIGHT
# file:src/auth/login.ts line:11 side:RIGHT
# file:src/auth/login.ts line:14 side:RIGHT
```

脚本依赖：`bash`（最低 4.0）、`grep`、`sed`（Windows Git Bash 兼容）。

## 常见错误速查

| 错误 | 症状 | 修复 |
|------|------|------|
| 使用源文件行号 | `line doesn't exist in diff` | 用 diff 行号（从 diff 文本第 1 行开始数） |
| 使用 `@@ +c,d` 中的 `c` 作为行号 | 评论位置偏移 | 从 diff 第 1 行重新计算 |
| 未指定 `side` | 评论不在预期位置 | 新增代码用 RIGHT，删除代码用 LEFT |
| `side` 与代码类型不匹配 | 评论不显示 | 新增用 RIGHT，删除用 LEFT，上下文随意 |
| 多行范围未用 startLine | 评论显示在单行 | 添加 startLine + startSide |
