# OpenClaw 项目结构说明

## 1. 整体目录结构

```
openclaw/
├── src/                      # 源代码目录
│   ├── acp/                  # Agent-Client Protocol 实现
│   ├── agents/               # AI Agent 运行时
│   ├── gateway/              # Gateway 服务器
│   ├── channels/             # 消息渠道管理
│   ├── commands/             # CLI 命令
│   ├── config/               # 配置系统
│   ├── plugins/              # 插件系统
│   ├── telegram/             # Telegram 渠道实现
│   ├── whatsapp/             # WhatsApp 渠道实现
│   ├── slack/                # Slack 渠道实现
│   ├── discord/              # Discord 渠道实现
│   ├── signal/               # Signal 渠道实现
│   ├── imessage/             # iMessage 渠道实现
│   ├── media/                # 媒体处理管道
│   ├── browser/              # 浏览器控制
│   ├── canvas-host/          # Canvas 画布宿主
│   ├── memory/               # 记忆系统
│   ├── cron/                 # 定时任务
│   ├── hooks/                # 钩子系统
│   ├── pairing/              # 配对系统
│   ├── routing/              # 消息路由
│   ├── sessions/             # 会话管理
│   ├── secrets/              # 密钥管理
│   ├── security/             # 安全相关
│   ├── terminal/             # CLI 终端 UI
│   ├── wizard/               # 配置向导
│   └── ...                   # 其他模块
├── extensions/               # 插件/扩展
│   ├── bluebubbles/          # BlueBubbles 扩展
│   ├── matrix/               # Matrix 扩展
│   ├── msteams/              # Microsoft Teams 扩展
│   ├── voice-call/           # 语音通话扩展
│   └── ...                   # 其他扩展
├── apps/                     # 客户端应用
│   ├── macos/                # macOS 应用
│   ├── ios/                  # iOS 应用
│   └── android/              # Android 应用
├── docs/                     # 文档
│   ├── channels/             # 渠道文档
│   ├── gateway/              # Gateway 文档
│   ├── tools/                # 工具文档
│   └── ...                   # 其他文档
├── scripts/                  # 构建/测试脚本
├── test/                     # 测试文件
├── dist/                     # 构建输出
└── package.json              # 项目配置
```

## 2. 核心模块详解

### 2.1 Gateway (`src/gateway/`)

Gateway 是系统的 WebSocket 控制平面，负责：
- 处理所有客户端连接（CLI、WebChat、移动应用）
- 消息路由和事件分发
- 会话管理
- 渠道管理

**关键文件**:
| 文件 | 描述 |
|------|------|
| `server.impl.ts` | Gateway 服务器主实现 |
| `client.ts` | 客户端连接管理 |
| `server-methods.ts` | WebSocket 方法处理 |
| `channel-manager.ts` | 渠道管理 |
| `session-manager.ts` | 会话管理 |
| `node-registry.ts` | 设备节点注册 |

**工作流程**:
```
客户端连接 → AuthHandler → MethodRouter → 具体处理器
                                  ↓
                          EventDispatcher
                                  ↓
                          广播给订阅者
```

### 2.2 ACP (`src/acp/`)

Agent-Client Protocol 实现，负责：
- Agent 与 Gateway 之间的通信协议
- 会话状态管理
- 工具调用翻译

**关键文件**:
| 文件 | 描述 |
|------|------|
| `translator.ts` | 事件翻译层 |
| `session.ts` | 会话管理 |
| `server.ts` | ACP 服务器 |
| `commands.ts` | 命令处理 |
| `types.ts` | 类型定义 |

### 2.3 Agents (`src/agents/`)

Pi Agent 运行时，负责：
- AI 对话管理
- 工具调用
- 认证配置管理
- 故障切换

**关键文件**:
| 文件 | 描述 |
|------|------|
| `auth-profiles.ts` | 认证配置管理 |
| `agent-scope.ts` | Agent 作用域 |
| `skills/` | 技能管理 |
| `acp-spawn.ts` | Agent 派生 |

### 2.4 Channels (`src/channels/`)

消息渠道管理，负责：
- 统一管理所有消息渠道
- 消息路由
- 配对和允许名单

**关键文件**:
| 文件 | 描述 |
|------|------|
| `manager.ts` | 渠道管理器 |
| `plugins/` | 渠道插件 |
| `routing/` | 消息路由 |

### 2.5 渠道实现

每个渠道都有独立的实现目录：

**Telegram (`src/telegram/`)**:
```
src/telegram/
├── channel.ts          # 渠道实现
├── handlers/           # 消息处理器
├── pairs/              # 配对管理
└── config.ts           # 配置
```

**WhatsApp (`src/whatsapp/`)**:
```
src/whatsapp/
├── channel.ts          # 渠道实现
├── client/             # Baileys 客户端
├── handlers/           # 消息处理器
└── pairs/              # 配对管理
```

## 3. 文件互动关系

### 3.1 消息处理流程

```
src/telegram/handlers/message.ts
    │ (导入)
    ▼
src/telegram/channel.ts
    │ (使用 ChannelManager)
    ▼
src/channels/manager.ts
    │ (路由到 Gateway)
    ▼
src/gateway/client.ts
    │ (WebSocket 事件)
    ▼
src/acp/translator.ts
    │ (翻译为 Agent 事件)
    ▼
src/agents/auth-profiles.ts
    │ (选择认证配置)
    ▼
AI Service API
```

### 3.2 配置加载流程

```
src/config/config.ts
    │ (加载配置文件)
    ▼
~/.openclaw/config.json
    │ (解析配置)
    ▼
src/config/plugin-auto-enable.ts
    │ (自动启用插件)
    ▼
src/plugins/runtime/
    │ (加载插件)
    ▼
extensions/*/
```

## 4. 命名约定

### 4.1 文件和目录

- **目录名**: 小写，连字符分隔（`kebab-case`）
  - ✅ `src/gateway/`, `src/auth-profiles/`
  - ❌ `src/Gateway/`, `src/auth_profiles/`

- **文件名**: 小写，连字符分隔
  - ✅ `server.impl.ts`, `channel-manager.ts`
  - ❌ `Server.ts`, `channelManager.ts`

- **测试文件**: 与源文件同名 + `.test.ts`
  - ✅ `server.test.ts`, `channel.test.ts`

### 4.2 代码命名

```typescript
// 类：PascalCase
class GatewayClient { }

// 接口：PascalCase
interface ChannelConfig { }

// 类型别名：PascalCase
type SessionKey = { };

// 函数和变量：camelCase
function startGateway() { }
const channelManager = new ChannelManager();

// 常量：UPPER_SNAKE_CASE
const MAX_RETRIES = 3;
const DEFAULT_PORT = 18789;

// 枚举：PascalCase
enum ChannelType {
  Telegram = "telegram",
  WhatsApp = "whatsapp"
}
```

## 5. 导入/导出模式

### 5.1 统一导出点

```typescript
// src/gateway/server.ts - 统一导出
export { truncateCloseReason } from "./server/close-reason.js";
export type { GatewayServer, GatewayServerOptions } from "./server.impl.js";
export { startGatewayServer } from "./server.impl.js";
```

### 5.2 避免循环依赖

```typescript
// ❌ 错误：循环依赖
// a.ts
import { b } from "./b.js";
export function a() { return b(); }

// b.ts
import { a } from "./a.js";
export function b() { return a(); }

// ✅ 正确：使用共同依赖
// types.ts
export interface Service {
  doSomething(): void;
}

// a.ts
import type { Service } from "./types.js";
export class ServiceA implements Service { }

// b.ts
import type { Service } from "./types.js";
export class ServiceB implements Service { }
```

## 6. 测试文件组织

### 6.1 测试文件位置

测试文件与源文件 colocated（放在一起）：

```
src/
├── gateway/
│   ├── server.impl.ts      # 源文件
│   └── server.impl.test.ts # 测试文件
├── agents/
│   ├── auth-profiles.ts
│   └── auth-profiles.test.ts
```

### 6.2 测试文件命名

```typescript
// 单元测试
src/gateway/auth.test.ts

// 集成测试
src/gateway/auth.integration.test.ts

// 端到端测试
src/gateway/auth.e2e.test.ts

// 实时测试（需要真实 API key）
src/gateway/auth.live.test.ts

// 特定场景测试
src/gateway/auth.retry.test.ts
```

## 7. 配置文件

### 7.1 package.json 脚本

```json
{
  "scripts": {
    "build": "pnpm build",
    "dev": "pnpm gateway:watch",
    "test": "pnpm test",
    "lint": "pnpm check",
    "format": "pnpm format"
  }
}
```

### 7.2 TypeScript 配置

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

## 8. 构建输出

```
dist/
├── entry.js                # 入口文件
├── gateway/
│   ├── server.impl.js
│   ├── client.js
│   └── ...
├── acp/
│   ├── translator.js
│   ├── session.js
│   └── ...
├── agents/
│   ├── auth-profiles.js
│   └── ...
└── plugin-sdk/             # 插件 SDK
    ├── index.js
    ├── core.js
    └── ...
```

## 9. 插件开发

### 9.1 插件结构

```
extensions/my-channel/
├── src/
│   └── channel.ts          # 渠道实现
├── package.json
└── tsconfig.json
```

### 9.2 插件 SDK 导入

```typescript
// ✅ 正确：导入特定模块
import { ChannelBase } from "openclaw/plugin-sdk/core";
import type { ChannelConfig } from "openclaw/plugin-sdk/types";

// ❌ 避免：导入整个 SDK
import * as sdk from "openclaw/plugin-sdk";
```

## 10. 代码质量和风格

### 10.1  linting

```bash
# 运行 lint
pnpm check

# 自动修复
pnpm lint:fix
```

### 10.2 格式化

```bash
# 检查格式
pnpm format

# 自动格式化
pnpm format:fix
```

### 10.3 类型检查

```bash
# 运行 TypeScript 检查
pnpm tsgo
```

## 11. 调试技巧

### 11.1 日志输出

```typescript
import { createSubsystemLogger } from "../logging/subsystem.js";

const log = createSubsystemLogger("gateway");
const logChannels = log.child("channels");

logChannels.info("Channel connected", { channelId: "telegram" });
```

### 11.2 调试模式

```bash
# 启用详细日志
OPENCLAW_LOG_LEVEL=debug pnpm openclaw gateway

# 启用诊断事件
OPENCLAW_DIAGNOSTICS=1 pnpm openclaw gateway
```

## 12. 进一步阅读

- [架构概览](./architecture-overview.md)
- [TypeScript 教程](./language-tutorials/typescript-basics.md)
- [开发引导](./guides/)

https://docs.openclaw.ai/gateway
https://docs.openclaw.ai/plugins
