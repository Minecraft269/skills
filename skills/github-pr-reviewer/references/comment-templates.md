# 审查评论模板

## 评论正文结构

```
**🔒 [安全] 密码验证缺少空值检查**

当前代码在 `password` 为 `null` 或 `undefined` 时会直接传递给 `hashPassword()`，
可能导致运行时异常或不安全的哈希结果。

**建议修复：**
```typescript
if (!password) {
  throw new BadRequestError('密码不能为空');
}
const hashed = await hashPassword(password);
```
```

1. **粗体标题**：`**[图标] [类别中文名] 简短问题描述**`
2. **问题描述**：1-3 句话说明当前代码的问题和潜在影响
3. **建议修复**（可选）：带代码示例的具体修复方案

## 类别图标映射

| 类别 | 图标 | 中文名 |
|------|------|--------|
| bug | 🐛 | Bug |
| security | 🔒 | 安全 |
| performance | ⚡ | 性能 |
| design | 🏗️ | 设计 |
| best-practice | 📐 | 最佳实践 |
| nitpick | 💭 | 建议 |
| praise | 👍 | 表扬 |

## 严重程度说明

| 严重程度 | 说明 | 是否阻塞合并 |
|---------|------|-------------|
| critical | 必须修复的严重缺陷或安全漏洞 | 是 |
| warning | 可能导致问题的代码 | 建议修复 |
| suggestion | 改进建议 | 否 |
| praise | 写得好的代码 | 否 |

## 添加策略

- 按严重程度排序：critical → warning → suggestion → praise
- 每条之间适当间隔，避免触发 GitHub API rate limit
- 添加失败时记录条目并继续下一条
- 已有评论的位置跳过重复
