# env-health-check

跨平台检测 git、gh、jq、claude 等核心工具可用性，输出格式化健康报告。

## 触发方式

说「检查环境」「环境自检」「我的工具链是否就绪」即可触发。

## 检测范围

| 类别 | 检测项 |
|------|--------|
| 核心依赖 | git、gh、jq、claude、node、python |
| 服务状态 | gh 认证、MCP Server 配置 |
| 安装建议 | 缺失工具给出 Win/macOS/Linux 安装命令 |

## 工作流

1. 并行运行 `command -v` + `--version` 检测所有工具
2. 检查 `gh auth status` 和 MCP 配置
3. 输出格式化健康报告（✅/⚠️/❌）

## 联动

- 缺失工具 → 提示 **插件安装器**
- 环境就绪 → 提示 **技能发现**
