# 错误处理参考

## 错误场景及处理

| 错误场景 | 检测方式 | 处理方式 |
|----------|----------|----------|
| `gh` 未安装 | `which gh` 返回空 | 提示安装：https://cli.github.com/ |
| `gh` 未登录 | `gh auth status` 非 0 | 提示执行 `gh auth login` |
| 仓库不存在 | `gh pr list` 返回 404 | "仓库 owner/repo 不存在或无访问权限，请检查拼写或权限" |
| 无开放 PR | `gh pr list` 返回空数组 | "该仓库当前没有开放的 PR" |
| PR 编号无效 | `gh pr view` 返回 "not found" | "未找到 PR #xxxx，请检查编号或输入 r 刷新列表" |
| 目标目录已存在 | `test -d <owner>-<repo>-pr-<编号>` | 询问 `[y]` 删除重建 / `[n]` 跳过直接进入 / `[q]` 取消 |
| 磁盘空间不足 | `df -h` 检查 | 提示清理空间或 `/set-clone-path` 换路径 |
| 克隆失败（网络） | `gh pr checkout` 超时 | 检查网络，建议重试；提供 `--depth 1` 浅克隆 |
| 克隆失败（权限） | 返回 403 | 检查仓库权限（私有仓库需 `gh auth` scope） |
| `jq` 未安装 | `which jq` 返回空 | 回退到原始 JSON 输出，提示安装 jq 获得更好格式 |
| 仓库有 50+ PR | 返回数量 = limit | "仅展示最近 50 个 PR，使用 `--limit 100` 查看更多" |

## 优雅降级原则

- 任何工具缺失都不应阻止核心流程
- `jq` 缺失 → 用 `gh` 内置 `--jq` 或原始输出
- `gh` 版本过低 → 降级使用兼容命令
- 网络错误 → 重试一次后给出明确的下一步操作

## 用户反馈模式

始终做到：
1. 清晰说明出了什么问题
2. 解释可能的原因
3. 给出具体的解决步骤
4. 提供替代方案（如果有）

### 示例

```
❌ 克隆 PR #1234 失败

原因：网络连接超时（gh 无法访问 api.github.com）

建议：
  1. 检查网络连接
  2. 确认 gh auth status 正常
  3. 重试：输入 c 1234

替代方案：
  手动克隆：
  git clone https://github.com/owner/repo.git owner-repo-pr-1234
  cd owner-repo-pr-1234
  gh pr checkout 1234
```
