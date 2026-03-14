# OpenClaw 组件详情

本文档详细介绍 OpenClaw 系统中的核心组件。

---

## 1. Gateway 组件

### 1.1 概述

Gateway 是 OpenClaw 的 WebSocket 控制平面，负责管理所有客户端连接、消息路由和事件分发。

**位置**: `src/gateway/`

**核心职责**:
- WebSocket 服务器管理
- 客户端认证和授权
- 消息路由和事件分发
- 会话管理
- 渠道管理
- 节点注册

### 1.2 核心组件

#### WebSocketServer (`src/gateway/server.impl.ts`)

```typescript
interface GatewayServer {
  // 启动服务器
  start(): Promise<void>;

  // 停止服务器
  stop(): Promise<void>;

  // 广播事件给所有客户端
  broadcast(event: GatewayEvent): void;

  // 发送事件给特定客户端
  sendTo(clientId: string, event: GatewayEvent): void;
}
```

**关键方法**:
| 方法 | 描述 |
|------|------|
| `start()` | 启动 WebSocket 服务器 |
| `stop()` | 停止服务器，关闭所有连接 |
| `broadcast()` | 广播事件给所有连接的客户端 |
| `handleConnection()` | 处理新 WebSocket 连接 |

#### AuthHandler (`src/gateway/auth.ts`)

```typescript
interface AuthHandler {
  // 验证请求
  authenticate(request: Request): Promise<AuthResult>;

  // 检查速率限制
  checkRateLimit(ip: string): Promise<boolean>;
}
```

**认证流程**:
```
客户端连接
    │
    ▼
检查 Token/密码
    │
    ▼
验证有效？───否───► 拒绝连接
    │
    是
    ▼
检查速率限制
    │
    ▼
通过？───否───► 拒绝连接
    │
    是
    ▼
建立连接
```

#### SessionManager (`src/gateway/session-utils.ts`)

```typescript
interface SessionManager {
  // 获取或创建会话
  getOrCreateSession(key: SessionKey): Promise<GatewaySession>;

  // 更新会话
  updateSession(id: string, updates: Partial<GatewaySession>): Promise<void>;

  // 删除会话
  deleteSession(id: string): Promise<void>;

  // 列出所有会话
  listSessions(): Promise<GatewaySession[]>;
}
```

### 1.3 配置选项

```json
{
  "gateway": {
    "bind": "loopback",
    "port": 18789,
    "auth": {
      "mode": "token"
    },
    "tailscale": {
      "mode": "off"
    },
    "media": {
      "ttlHours": 168
    }
  }
}
```

---

## 2. Pi Agent 组件

### 2.1 概述

Pi Agent 是 AI 代理运行时，负责执行 AI 对话、工具调用和流式响应。

**位置**: `src/agents/` 和 `src/acp/`

**核心职责**:
- AI 对话管理
- 工具调用执行
- 流式响应处理
- 认证配置管理
- 故障切换

### 2.2 核心组件

#### Translator (`src/acp/translator.ts`)

```typescript
class AcpGatewayAgent {
  // 处理 Gateway 事件
  handleGatewayEvent(event: GatewayEvent): Promise<void>;

  // 处理 Gateway 重连
  handleGatewayReconnect(): void;

  // 处理 Gateway 断开
  handleGatewayDisconnect(reason: string): void;
}
```

**职责**:
- Gateway 事件 → ACP 事件翻译
- ACP 事件 → Gateway 事件翻译
- 会话上下文管理
- 工具调用处理

#### AuthProfileManager (`src/agents/auth-profiles.ts`)

```typescript
class AuthProfileManager {
  // 获取活跃配置
  getActiveProfile(): Promise<AuthProfile>;

  // 标记配置失败
  markProfileFailure(profileId: string): Promise<void>;

  // 解析配置顺序
  resolveAuthProfileOrder(): AuthProfile[];
}
```

**故障切换逻辑**:
```
API 请求失败
    │
    ▼
标记当前配置失败
    │
    ▼
设置 cooldown 时间
    │
    ▼
获取下一个配置
    │
    ▼
重试请求
    │
    ▼
成功？───否───► 继续下一个
    │
    是
    ▼
更新 lastGood
    │
    ▼
返回结果
```

#### ToolRegistry (`src/agents/tools/`)

```typescript
class ToolRegistry {
  // 注册工具
  register(tool: Tool): void;

  // 执行工具
  execute(toolName: string, input: Record<string, unknown>): Promise<any>;

  // 列出所有工具
  listTools(): Tool[];
}
```

**内置工具**:
| 工具 | 描述 | 位置 |
|------|------|------|
| `browser.open` | 打开网页 | `src/browser/` |
| `browser.screenshot` | 捕获截图 | `src/browser/` |
| `canvas.reset` | 重置画布 | `src/canvas-host/` |
| `media.image` | 处理图片 | `src/media/` |
| `node.invoke` | 调用节点 | `src/gateway/` |
| `sessions.send` | 会话间消息 | `src/sessions/` |

---

## 3. Channels 组件

### 3.1 概述

Channels 组件负责与外部消息平台通信，提供统一的消息抽象。

**位置**: `src/channels/` 和各渠道目录

**核心职责**:
- 渠道连接管理
- 消息收发
- 配对和允许名单
- 错误处理和重连

### 3.2 统一接口

```typescript
interface Channel {
  // 渠道 ID
  id: string;

  // 渠道类型
  type: ChannelType;

  // 渠道状态
  status: ChannelStatus;

  // 连接
  connect(): Promise<void>;

  // 发送消息
  sendMessage(to: string, text: string, attachments?: Attachment[]): Promise<void>;

  // 断开连接
  disconnect(): Promise<void>;
}
```

### 3.3 渠道实现

#### Telegram (`src/telegram/`)

```typescript
class TelegramChannel implements Channel {
  private bot: Bot;
  private config: TelegramConfig;

  async connect(): Promise<void> {
    // 使用 grammY SDK 连接
    this.bot = new Bot(this.config.token);

    // 注册处理器
    this.bot.on("message", async (ctx) => {
      await this.handleMessage(ctx);
    });

    // 启动轮询
    await this.bot.start({
      onStart: () => console.log("Telegram bot started"),
    });
  }
}
```

#### WhatsApp (`src/whatsapp/`)

```typescript
class WhatsAppChannel implements Channel {
  private client: makeWASocket;
  private config: WhatsAppConfig;

  async connect(): Promise<void> {
    // 使用 Baileys 库连接
    this.client = makeWASocket({
      auth: this.config.credentials,
      printQRInTerminal: true,
    });

    // 注册事件处理器
    this.client.ev.on("messages.upsert", async ({ messages }) => {
      await this.handleMessages(messages);
    });
  }
}
```

### 3.4 配对系统

```typescript
// src/pairing/manager.ts
class PairingManager {
  // 生成配对码
  async generateCode(channelId: string): Promise<string>;

  // 验证配对码
  async verifyCode(channelId: string, code: string): Promise<boolean>;

  // 批准配对
  async approve(channelId: string, code: string): Promise<void>;

  // 添加到允许名单
  async addToAllowlist(channelId: string, userId: string): Promise<void>;
}
```

**配对流程**:
```
未知用户发送消息
    │
    ▼
检查允许名单
    │
    ▼
在列表中？───是───► 处理消息
    │
    否
    ▼
生成配对码
    │
    ▼
发送配对码给用户
    │
    ▼
用户提交配对码
    │
    ▼
验证配对码
    │
    ▼
正确？───否───► 拒绝
    │
    是
    ▼
添加到允许名单
    │
    ▼
处理消息
```

---

## 4. Storage 组件

### 4.1 概述

Storage 组件负责数据持久化，使用 SQLite 作为主要存储引擎。

**位置**: `src/sessions/` 和 `src/infra/database.ts`

### 4.2 数据库表

#### sessions 表

```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  key_channel_id TEXT,
  key_account_id TEXT,
  key_room_id TEXT,
  key_thread_id TEXT,
  display_name TEXT,
  thinking_level TEXT,
  model TEXT,
  total_tokens INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### pairing 表

```sql
CREATE TABLE pairing (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel_id TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at DATETIME NOT NULL,
  approved BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### allowlist 表

```sql
CREATE TABLE allowlist (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(channel_id, user_id)
);
```

### 4.3 数据库操作

```typescript
// src/infra/database.ts
class Database {
  // 执行查询
  query<T>(sql: string, params?: any[]): T[];

  // 执行更新
  run(sql: string, params?: any[]): void;

  // 事务
  transaction<T>(fn: () => T): T;
}

// 使用示例
const db = new Database("~/.openclaw/sessions.db");

// 插入会话
db.run(
  "INSERT INTO sessions (id, display_name) VALUES (?, ?)",
  [sessionId, displayName]
);

// 查询会话
const sessions = db.query<GatewaySession>(
  "SELECT * FROM sessions WHERE key_channel_id = ?",
  [channelId]
);
```

---

## 5. Config 组件

### 5.1 概述

Config 组件负责配置加载、验证和热重载。

**位置**: `src/config/`

### 5.2 配置结构

```typescript
interface OpenClawConfig {
  // Gateway 配置
  gateway: GatewayConfig;

  // 渠道配置
  channels: {
    telegram?: TelegramConfig;
    whatsapp?: WhatsAppConfig;
    slack?: SlackConfig;
    // ...
  };

  // 模型配置
  models: {
    providers: {
      openai?: OpenAIConfig;
      anthropic?: AnthropicConfig;
      // ...
    };
  };

  // 认证配置
  auth?: AuthConfig;

  // 密钥配置
  secrets?: SecretsConfig;
}
```

### 5.3 配置加载

```typescript
// src/config/config.ts
function loadConfig(): OpenClawConfig {
  // 1. 读取配置文件
  const configPath = "~/.openclaw/config.json";
  const configText = fs.readFileSync(configPath, "utf-8");

  // 2. 解析 JSON
  const config = JSON.parse(configText);

  // 3. 应用默认值
  const withDefaults = applyDefaults(config);

  // 4. 迁移（如果需要）
  const migrated = migrateConfig(withDefaults);

  // 5. 验证
  validateConfig(migrated);

  return migrated;
}
```

### 5.4 热重载

```typescript
// src/config/config-reload.ts
function watchConfigChanges(): void {
  chokidar.watch(configPath).on("change", async () => {
    // 1. 读取新配置
    const newConfig = loadConfig();

    // 2. 验证配置
    const issues = validateConfig(newConfig);
    if (issues.length > 0) {
      log.warn("Config validation failed", issues);
      return;
    }

    // 3. 制定重载计划
    const plan = createReloadPlan(oldConfig, newConfig);

    // 4. 应用重载
    await applyReload(plan);

    // 5. 更新配置
    oldConfig = newConfig;
  });
}
```

---

## 6. Plugins 组件

### 6.1 概述

Plugins 组件提供扩展机制，支持自定义渠道、工具和其他功能。

**位置**: `src/plugins/` 和 `extensions/`

### 6.2 插件接口

```typescript
interface Plugin {
  // 插件元数据
  name: string;
  version: string;
  description?: string;

  // 激活插件
  activate(context: PluginContext): Promise<void>;

  // 停用插件
  deactivate(): Promise<void>;
}
```

### 6.3 插件生命周期

```
Plugin Load
    │
    ▼
Validate Manifest
    │
    ▼
activate()
    │
    ▼
Register Services
    │    - Channels
    │    - Tools
    │    - Hooks
    │
    ▼
Plugin Active
    │
    ▼
deactivate()
    │
    ▼
Cleanup Resources
    │
    ▼
Plugin Unloaded
```

### 6.4 开发插件

```typescript
// extensions/my-channel/src/index.ts
import type { Plugin, PluginContext } from "openclaw/plugin-sdk";

export default class MyChannelPlugin implements Plugin {
  name = "my-channel";
  version = "1.0.0";

  async activate(context: PluginContext): Promise<void> {
    // 注册渠道
    context.registerChannel(new MyChannel());

    // 注册工具
    context.registerTool(myTool);
  }

  async deactivate(): Promise<void> {
    // 清理资源
  }
}
```

---

## 7. 组件互动关系

### 7.1 运行时互动

```
┌─────────────────────────────────────────────────────────────┐
│                         User                                │
└─────────────────────────────────────────────────────────────┘
    │
    │ sends message
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Channel (Telegram)                       │
│  - Receive message                                          │
│  - Convert to internal format                               │
└─────────────────────────────────────────────────────────────┘
    │
    │ routes to
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    ChannelManager                           │
│  - Find target session                                      │
│  - Apply routing rules                                      │
└─────────────────────────────────────────────────────────────┘
    │
    │ forwards to
    ▼
┌─────────────────────────────────────────────────────────────┐
│                      Gateway                                │
│  - WebSocket server                                         │
│  - Auth check                                               │
│  - Event broadcast                                          │
└─────────────────────────────────────────────────────────────┘
    │
    │ RPC/AC Protocol
    ▼
┌─────────────────────────────────────────────────────────────┐
│                      Pi Agent                               │
│  - Session Core                                             │
│  - Tool Registry                                            │
│  - Auth Profile Manager                                     │
└─────────────────────────────────────────────────────────────┘
    │
    │ API call
    ▼
┌─────────────────────────────────────────────────────────────┐
│                   AI Service (OpenAI)                       │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 数据持久化互动

```
┌─────────────────────────────────────────────────────────────┐
│                   Runtime Components                        │
└─────────────────────────────────────────────────────────────┘
    │
    │ read/write
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Storage Layer                            │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │  sessions.db  │  │  pairing.db   │  │ allowlist.db  │   │
│  │   (SQLite)    │  │   (SQLite)    │  │   (SQLite)    │   │
│  └───────────────┘  └───────────────┘  └───────────────┘   │
└─────────────────────────────────────────────────────────────┘
    │
    │ file I/O
    ▼
┌─────────────────────────────────────────────────────────────┐
│               ~/.openclaw/ (config directory)               │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. 故障排查

### 8.1 Gateway 问题

| 症状 | 可能原因 | 解决方案 |
|------|----------|----------|
| 无法启动 | 端口被占用 | `lsof -i :18789` 检查端口 |
| 认证失败 | Token 错误 | 检查 `config.json` 中的 token |
| 连接断开 | 网络问题 | 检查防火墙和 DNS |

### 8.2 渠道问题

| 症状 | 可能原因 | 解决方案 |
|------|----------|----------|
| 无法连接 | 凭证错误 | 重新运行配对流程 |
| 消息发送失败 | API 限制 | 检查速率限制 |
| 重复消息 | 事件重复处理 | 检查事件去重逻辑 |

### 8.3 Agent 问题

| 症状 | 可能原因 | 解决方案 |
|------|----------|----------|
| API 调用失败 | 认证过期 | 刷新 OAuth token |
| 工具调用失败 | 工具未注册 | 检查 ToolRegistry |
| 响应慢 | 上下文太大 | 使用 `/compact` 命令 |

---

## 9. 进一步阅读

- [架构概览](./architecture-overview.md)
- [数据流分析](./data-flow.md)
- [项目结构](./project-structure.md)
- [开发引导](./guides/getting-started.md)

https://docs.openclaw.ai/gateway
https://docs.openclaw.ai/plugins
