# 详细工作流参考

## 目录命名规则

多仓库场景下，克隆目录使用 `<owner>-<repo>-pr-<编号>` 格式：

```
facebook-react-pr-28452/    # facebook/react 的 PR #28452
lodash-lodash-pr-4528/      # lodash/lodash 的 PR #4528
vuejs-core-pr-9012/         # vuejs/core 的 PR #9012
```

这样不同仓库的 PR 互不干扰，一目了然。

## 多仓库管理

技能维护一个仓库列表，支持快速切换：

- 最近使用过的仓库自动记录（最多 10 个）
- `/set-repo owner/repo` 添加新仓库或切换到已有仓库
- `repo owner/repo` 快速切换（简写形式）
- `/show-config` 展示当前配置和最近仓库列表

### 配置展示格式

```
⚙️  当前配置
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
当前仓库:   facebook/react
克隆路径:   ./
最近仓库:
  1. facebook/react (当前)
  2. lodash/lodash
  3. vuejs/core
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## PR 详情展示格式

### 完整信息（默认，输入 PR 编号时触发）

一次性展示：基本详情 + diff + 评论/审查 + 提交历史。

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 PR #1234 详情 (facebook/react)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
标题:       feat: add new button component
作者:       @john_doe
状态:       🟢 OPEN | 可合并: ✅
分支:       feature/button → main
创建时间:   2026-05-28
标签:       enhancement, UI
变更文件:   5 个文件 (+234 / -56)
提交数:     3
🔗 链接:    https://github.com/facebook/react/pull/1234
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 描述:
添加了一个新的按钮组件，支持多种样式和尺寸配置...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 代码变更 (diff) — 前 200 行:
 src/components/Button.tsx       |  45 ++++++++++++++
 src/components/Button.test.tsx  |  67 +++++++++++++++++++
 ...
 (共 5 个文件变更，完整 diff 可用 `gh pr diff 1234` 查看)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 审查状态:
  @reviewer1 [APPROVED] — "LGTM, nice work!" (2天前)
  @reviewer2 [COMMENTED] — "Consider adding aria labels" (1天前)

💬 评论 (3):
  @dev_helper — "需要更新 Storybook 吗？"
    ↳ @john_doe — "已更新，在另一个 PR #1235"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 提交历史 (3):
  abc1234  @john_doe     feat: add Button component variants
  def5678  @john_doe     style: format with prettier
  ghi9012  @john_doe     test: add Button unit tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 克隆后初始化流程

克隆到 `facebook-react-pr-1234/` 后自动检测项目类型：

### Node.js 项目
```
🔍 检测到 Node.js 项目 (package.json)
依赖: express, react, typescript ... (共 42 个包)
是否执行 npm install？ [y/n] (默认 y)
```

### Python 项目
```
🔍 检测到 Python 项目 (pyproject.toml)
是否创建虚拟环境并安装依赖？ [y/n] (默认 y)
→ python -m venv .venv && source .venv/bin/activate && pip install -e .
```

### Rust 项目
```
🔍 检测到 Rust 项目 (Cargo.toml)
是否执行 cargo build？ [y/n] (默认 y)
```

### 完成后
```
🎉 开发环境已就绪！
📂 当前工作目录: ./facebook-react-pr-1234
🌿 分支: feature/button
📏 大小: 12MB
```

## 自定义克隆路径

用户可通过 `/set-clone-path <路径>` 修改克隆根目录（默认为当前目录）：

```
/set-clone-path ~/dev/pr-review
```

之后克隆创建 `~/dev/pr-review/facebook-react-pr-<编号>`。

## 完整示例对话

**用户：** 帮我看看 facebook/react 有哪些 PR

**Claude：**
```
✅ 已设置仓库：facebook/react
正在获取开放 PR...

📋 仓库: facebook/react | 开放 PR 列表
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #28452  feat: new hook useOptimistic    @sebmarkbage   3天前
  #28400  fix: reconcile edge case        @acdlite       1周前
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
共 2 个开放 PR
```

**用户：** 看下 28452

**Claude：** [展示 PR #28452 完整信息：详情 + diff + 审查 + 提交]

**用户：** 克隆这个

**Claude：** [克隆到 facebook-react-pr-28452 → 检测 Node.js → npm install → 完成]

**用户：** 切到 lodash/lodash 看看

**Claude：** [切换仓库 → 展示 lodash/lodash 的 PR 列表]

**用户：** batch clone 4528,4500

**Claude：** [分别克隆到 lodash-lodash-pr-4528 和 lodash-lodash-pr-4500]
