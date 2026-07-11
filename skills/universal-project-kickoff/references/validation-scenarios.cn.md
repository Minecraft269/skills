# 验证场景

本文件提供一组验证场景，用于在执行 `universal-project-kickoff` 技能时进行 LLM 自检。按照场景描述执行扫描和匹配后，检查推荐结果是否符合预期。

## 测试场景

### 场景 1：标准 Spring Boot 项目

**项目特征：**
- 存在 `pom.xml`，含 `spring-boot-starter-parent`
- 存在 `src/main/java/` 目录
- 存在 `application.yml`

**预期指纹标签：** `java`, `spring-boot`, `maven`

**预期推荐（至少包含）：**
- `github-pr-manager`（always_recommend 默认）
- `universal-project-kickoff`（always_recommend 默认）

**验证点：**
- [ ] 所有与 `java`、`spring-boot`、`maven` 标签匹配的技能得分 > 0
- [ ] always_recommend 中的技能排在推荐列表最前面
- [ ] 推荐数量不超过 `max_recommendations`（默认 10）

---

### 场景 2：React + TypeScript 前端项目

**项目特征：**
- 存在 `package.json`，含 `react`、`typescript` dep
- 存在 `tsconfig.json`
- 存在 `vite.config.ts`

**预期指纹标签：** `typescript`, `react`, `nodejs`, `vite`

**预期推荐（至少包含）：**
- `quick-plugin-installer`（插件安装相关）
- `github-pr-manager`（always_recommend）

**验证点：**
- [ ] 与 `react`、`typescript` 标签匹配的得分+3 每标签
- [ ] 与 `frontend` 领域对齐的技能获得 category_bonus

---

### 场景 3：空项目 / 无任何配置文件

**项目特征：**
- 不存在任何可识别的配置文件
- 可能是一个空目录或仅有 README

**预期指纹标签：** 无（空集）

**验证点：**
- [ ] 不应报错或中断
- [ ] always_recommend 列表中的技能仍被推荐（作为通用推荐）
- [ ] always_recommend_plugins 中的插件仍被推荐

---

### 场景 4：Python FastAPI 项目

**项目特征：**
- 存在 `pyproject.toml`，含 `fastapi` dep
- 存在 `requirements.txt`，含 `fastapi`

**预期指纹标签：** `python`, `fastapi`

**验证点：**
- [ ] 不会因为 `pyproject.toml` 和 `requirements.txt` 同时存在而重复打分（去重）
- [ ] 与 `python` 标签匹配的技能获得+3

---

### 场景 5：Monorepo（多语言项目）

**项目特征：**
- 存在 `package.json`（前端子目录）
- 存在 `go.mod`（后端子目录）
- 存在 `docker-compose.yml`（根目录）

**预期指纹标签：** `javascript`/`typescript`, `nodejs`, `go`, `docker`, `orchestration`

**验证点：**
- [ ] 所有检测到的标签都被包含（不会因为找到第一个语言就停止）
- [ ] 推荐技能涵盖所有检测到的技术栈

---

### 场景 6：Flutter 移动端项目

**项目特征：**
- 存在 `pubspec.yaml`，含 `flutter` dep
- 存在 `android/` 和 `ios/` 目录

**预期指纹标签：** `flutter`, `dart`, `mobile`, `cross-platform`, `android`, `ios`

**验证点：**
- [ ] 移动端框架检测生效（Phase 4 新增的检测矩阵）
- [ ] `mobile` domain 的 category_bonus 正确应用

---

### 场景 7：纯 Docker 项目

**项目特征：**
- 仅存在 `Dockerfile` 和 `docker-compose.yml`
- 无其他语言配置文件

**预期指纹标签：** `docker`, `container`, `orchestration`

**验证点：**
- [ ] 不会因为没有语言标签而报错
- [ ] DevOps/Infra 类技能获得 category_bonus

---

### 场景 8：Java 8 老项目（版本检测）

**项目特征：**
- 存在 `pom.xml`，`<java.version>` 为 `1.8`
- 存在 `src/main/java/` 目录

**预期指纹标签：** `java`, `java-8`, `maven`

**验证点：**
- [ ] 版本标签 `java-8` 被正确提取
- [ ] 带 `java-21` 标签的技能仅获得+1（base `java` 匹配），而非+3

---

## 边界情况检查清单

| 边界情况 | 预期行为 |
|---------|---------|
| 空目录 | 不报错，仅推荐 always_recommend 列表 |
| 非 git 目录 | 正常扫描，不依赖 git context |
| Glob 超时 | 静默降级，标注部分扫描未完成 |
| 技能目录为空 | 仅推荐插件和命令 |
| settings.json 不存在 | 仅推荐技能，跳过插件扫描 |
| SKILL.md frontmatter 格式错误 | 跳过该技能，继续扫描其他 |
| 超大型项目（1000+ 文件） | 限制 Glob 深度，优先检查根目录配置文件 |

## 使用方式

执行技能后，对照本文件中的场景和边界情况进行验证。若发现推荐结果与预期不符，检查：
1. 指纹检测是否正确识别了所有配置文件
2. 标签匹配算法是否应用了正确的权重
3. 是否有 always_recommend/never_recommend 规则干扰

---

## 完整走查示例

### 示例 1: Java Spring Boot 项目

**输入:** 用户打开包含 `pom.xml` 的项目，pom.xml 中有 `spring-boot-starter-parent`。

**项目指纹:** `java, spring-boot, maven`

**推荐技能 (top 5):**
| # | 名称 | 描述 | 匹配理由 | 来源 |
|---|------|------|---------|------|
| 1 | `springboot-patterns` | Spring Boot 开发模式 | Spring Boot 框架直接匹配 | community |
| 2 | `java-pro` | Java 专业开发 | Java 语言匹配 | community |
| 3 | `springboot-tdd` | TDD 开发流程 | Spring Boot + 测试匹配 | community |
| 4 | `springboot-security` | Spring Boot 安全 | Spring Boot 框架匹配 | community |
| 5 | `git-workflow` | Git 工作流 | 通用开发技能 | community |

**推荐插件:**
| # | 名称 | 描述 | 匹配理由 | 类型 |
|---|------|------|---------|------|
| 1 | `plugin:github:github` | GitHub PR/Issue 管理 | 通用开发插件 | MCP |
| 2 | `plugin:context7:context7` | 文档查询 | 查阅 Spring Boot 文档 | MCP |

**用户选择 github 和 context7 后，指令发现展示:**
MCP 工具: `mcp__github__create_pull_request`（创建 PR，提交代码后需要发起合并请求时）、`mcp__context7__query-docs`（查询文档，需要查阅 Spring Boot API 时）。Slash 命令: `/commit`（规范化提交）、`/code-review`（审查代码）、`/create-pr`（创建 Pull Request）。

### 示例 2: React + Vite 前端项目

**输入:** 用户打开包含 `package.json` (react, vite deps) 和 `vite.config.ts` 的项目。

**项目指纹:** `javascript/typescript, react, vite, nodejs`

**推荐技能 (top 5):**
| # | 名称 | 描述 | 匹配理由 | 来源 |
|---|------|------|---------|------|
| 1 | `react-best-practices` | React 最佳实践 | React 框架直接匹配 | community |
| 2 | `frontend-patterns` | 前端开发模式 | 前端领域匹配 | community |
| 3 | `javascript-pro` | JS 专业开发 | JavaScript 语言匹配 | community |
| 4 | `vite-patterns` | Vite 构建模式 | Vite 工具匹配 | community |
| 5 | `ui-ux-designer` | UI/UX 设计 | 前端领域相关 | community |

**推荐插件:**
| # | 名称 | 描述 | 匹配理由 | 类型 |
|---|------|------|---------|------|
| 1 | `plugin:playwright:playwright` | 浏览器自动化测试 | 前端 E2E 测试 | MCP |
| 2 | `plugin:github:github` | PR 管理 | 通用开发插件 | MCP |

**用户选择后指令:** `mcp__github__search_code`（搜索代码）、`mcp__github__create_pull_request`（创建 PR）。Slash 命令: `/frontend-design`（前端设计）、`/code-review`（审查代码）、`/commit`（提交）。

### 示例 3: 未知/空项目

**输入:** 空目录或无任何已知配置文件的目录。

**项目指纹:** （无 — 空目录或未检测到已知配置文件）

**检测结果:** "🆕 未检测到已知项目类型。以下是通用推荐："

**推荐技能 (通用):**
| # | 名称 | 描述 | 匹配理由 | 来源 |
|---|------|------|---------|------|
| 1 | `git-workflow` | Git 工作流 | 通用开发技能 | community |
| 2 | `code-review` | 代码审查 | 通用开发技能 | community |
| 3 | `commit` | 规范化提交 | 通用开发技能 | community |
| 4 | `file-organizer` | 文件整理 | 通用辅助技能 | community |

**推荐插件 (通用):**
| # | 名称 | 描述 | 匹配理由 | 类型 |
|---|------|------|---------|------|
| 1 | `plugin:github:github` | PR/Issue 管理 | 通用开发插件 | MCP |
| 2 | `plugin:longhand:longhand` | 会话记忆 | 通用辅助插件 | MCP |

**用户选择后指令:** `/commit`（提交代码时）、`/code-review`（审查代码时）、`/discover`（重新发现时）

**行为:** 提示用户："如需查看所有已安装的能力，可以为你导出完整列表。"
