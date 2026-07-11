# 审查预览模板

在调用任何 GitHub API 之前，必须将每条审查发现以完整格式化预览展示给用户。禁止以 MCP 工具调用参数格式展示 — 用户需要看到最终会出现在 PR 上的完整评论内容。

## 预览格式

```
## 🔍 PR 审查预览

**审查仓库：** owner/repo
**审查 PR：** #[N] — PR 标题
**审查模型：** <当前模型名称>
**审查时间：** <当前时间>

---

### 发现 #1 — 🔒 安全 · critical

**文件：** `src/auth/login.ts`
**diff 行号：** 第 42 行（RIGHT 侧 — 新增代码）
**类别：** security
**严重程度：** critical

---

📝 **将发布的 inline 评论内容：**

当前代码在 `password` 为 `null` 或 `undefined` 时会直接传递给 `hashPassword()`，
可能导致运行时异常或不安全的哈希结果。

**建议修复：**
```typescript
if (!password) {
  throw new BadRequestError('密码不能为空');
}
const hashed = await hashPassword(password);
```

📋 **相关 diff 上下文：**
```diff
@@ -38,6 +38,8 @@ export async function login(username: string, password: string) {
   // 验证用户名
   const user = await db.findUser(username);
   ...
```

---

...（每条发现完整展开）...

---

## 📊 审查统计

| 严重程度 | 数量 |
|---------|------|
| 🔴 critical | X 条 |
| 🟡 warning | Y 条 |
| 🔵 suggestion | Z 条 |
| 🟢 praise | P 条 |

---

## ⏳ 等待确认

你可以：
- 回复「**确认**」→ 按默认范围（P0-P2）开始发布
- 回复 `--all` → 发布所有发现（含 P3-P5）
- 回复 `--select 1,3,5` → 仅发布指定编号
- 回复「**修改 #N**」→ 编辑第 N 条发现
```

## 重要规则

- 每条发现必须完整展开评论文本（问题描述 + 建议修复 + 代码示例）
- 每条发现必须附带相关 diff 上下文（含 `@@` hunk 头部）
- 审查模型名称必须从系统提示上下文中获取实际值，不可编造
- 必须等待用户确认后才能创建 pending review
