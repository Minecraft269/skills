# MCP Server 配置模板库

常见 MCP Server 的完整配置模板，可直接填入 `~/.claude/settings.json` 的 `mcpServers` 字段。

## 开发工具

### GitHub
```json
{
  "github": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-github"],
    "env": {
      "GITHUB_TOKEN": "<your-github-token>"
    }
  }
}
```

### GitLab
```json
{
  "gitlab": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-gitlab"],
    "env": {
      "GITLAB_TOKEN": "<your-gitlab-token>"
    }
  }
}
```

### Linear
```json
{
  "linear": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-linear"],
    "env": {
      "LINEAR_API_KEY": "<your-linear-api-key>"
    }
  }
}
```

### Jira
```json
{
  "jira": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-jira"],
    "env": {
      "JIRA_API_TOKEN": "<your-jira-token>",
      "JIRA_HOST": "https://your-domain.atlassian.net",
      "JIRA_EMAIL": "<your-email>"
    }
  }
}
```

## 数据库

### PostgreSQL / Supabase
```json
{
  "postgres": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-postgres"],
    "env": {
      "DATABASE_URL": "postgresql://user:password@host:5432/dbname"
    }
  }
}
```

### SQLite
```json
{
  "sqlite": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-sqlite"],
    "env": {
      "SQLITE_DB_PATH": "/path/to/database.db"
    }
  }
}
```

## 搜索与文档

### Context7
```json
{
  "context7": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@context7/mcp-server"]
  }
}
```

### Brave Search
```json
{
  "brave-search": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-brave-search"],
    "env": {
      "BRAVE_API_KEY": "<your-brave-api-key>"
    }
  }
}
```

### Exa Search
```json
{
  "exa": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-exa"],
    "env": {
      "EXA_API_KEY": "<your-exa-api-key>"
    }
  }
}
```

## 浏览器与测试

### Playwright
```json
{
  "playwright": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@playwright/mcp-server"]
  }
}
```

### Puppeteer
```json
{
  "puppeteer": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-puppeteer"]
  }
}
```

## 文件系统

### Filesystem
```json
{
  "filesystem": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-filesystem"],
    "env": {
      "ALLOWED_DIRECTORIES": "/path/to/allowed/dir1,/path/to/allowed/dir2"
    }
  }
}
```

## 通信与协作

### Slack
```json
{
  "slack": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-slack"],
    "env": {
      "SLACK_BOT_TOKEN": "<your-slack-bot-token>"
    }
  }
}
```

### Notion
```json
{
  "notion": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-notion"],
    "env": {
      "NOTION_API_KEY": "<your-notion-api-key>"
    }
  }
}
```

## 监控

### Sentry
```json
{
  "sentry": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-sentry"],
    "env": {
      "SENTRY_AUTH_TOKEN": "<your-sentry-auth-token>",
      "SENTRY_ORG": "<your-org-slug>"
    }
  }
}
```

## 自定义 MCP 类型

### Python（uvx）
```json
{
  "my-python-mcp": {
    "type": "stdio",
    "command": "uvx",
    "args": ["my-mcp-package"],
    "env": {
      "MY_API_KEY": "<your-api-key>"
    }
  }
}
```

### Node.js 本地
```json
{
  "my-node-mcp": {
    "type": "stdio",
    "command": "node",
    "args": ["./my-mcp-server/index.js"]
  }
}
```

### SSE（Server-Sent Events）
```json
{
  "my-sse-mcp": {
    "type": "sse",
    "url": "https://my-mcp-server.example.com/sse"
  }
}
```

### streamable-http
```json
{
  "my-http-mcp": {
    "type": "streamable-http",
    "url": "https://my-mcp-server.example.com/mcp"
  }
}
```

## 安装提示

1. 将选中的配置块复制到 `~/.claude/settings.json` 的 `mcpServers` 对象中
2. 将 `<your-xxx>` 替换为环境变量或实际值
3. 重启 Claude Code 以加载新的 MCP Server
4. 验证 MCP 工具是否在可用工具列表中
