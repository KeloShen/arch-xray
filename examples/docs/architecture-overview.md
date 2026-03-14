# OpenClaw 架构概览

## 1. 系统简介

OpenClaw 是一个个人 AI 助手系统，运行在用户自己的设备上。它通过多种消息渠道（WhatsApp、Telegram、Slack、Discord 等 20+ 平台）与用户交互，能够调用各种工具（浏览器控制、Canvas 画布、媒体处理等）来完成复杂任务。

### 1.1 核心价值主张

- **本地优先 (Local-first)**: Gateway 运行在用户自己的设备上，数据本地存储
- **多渠道集成**: 支持 20+ 消息平台作为交互界面
- **可扩展架构**: 通过插件系统支持自定义通道和工具
- **隐私优先**: 敏感数据本地存储，支持端到端加密通道

### 1.2 技术栈

| 层次 | 技术选型 |
|------|----------|
| 运行时 | Node.js 22+ |
| 语言 | TypeScript (ESM) |
| 构建工具 | tsdown, pnpm |
| 测试框架 | Vitest |
| 数据库 | SQLite (会话存储) |
| WebSocket | 原生 WebSocket |
| 浏览器自动化 | Playwright |

## 2. 系统上下文图

![System Context Diagram](../assets/diagrams/context.svg)

### 2.1 外部参与者

| 参与者 | 描述 |
|--------|------|
| **用户** | 通过 CLI、WebChat、移动应用与系统交互 |
| **开发者** | 开发、部署和配置系统 |

### 2.2 外部系统

| 类别 | 系统 |
|------|------|
| **消息渠道** | WhatsApp, Telegram, Slack, Discord, Signal, iMessage/BlueBubbles, IRC, Matrix, Teams, LINE, Mattermost, Nextcloud Talk, Nostr, Synology Chat, Tlon, Twitch, Zalo 等 |
| **AI 服务** | OpenAI API (GPT/Codex), Anthropic API (Claude), 其他 LLM 提供商 |
| **设备应用** | macOS 菜单栏应用、iOS 节点应用、Android 节点应用 |
| **基础设施** | Tailscale (内网穿透), ClawHub (技能注册中心) |

## 3. 核心架构模式

### 3.1 控制平面/数据平面分离

```
┌─────────────────────────────────────────────────────────────┐
│                     Control Plane                           │
│  +─────────────+  +─────────────+  +─────────────────────+  │
│  │   Gateway   │◄─┤   Session   │◄─┤   Method Router     │  │
│  │  (WebSocket)│  │   Manager   │  │   (WS Methods)      │  │
│  +─────────────+  +─────────────+  +─────────────────────+  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ RPC / AC Protocol
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Plane                             │
│  +─────────────+  +─────────────+  +─────────────────────+  │
│  │   Pi Agent  │◄─┤   Tool      │◄─┤   AI Services       │  │
│  │  (Runtime)  │  │   Registry  │  │   (OpenAI/Anthropic)│  │
│  +─────────────+  +─────────────+  +─────────────────────+  │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 事件驱动架构

系统采用事件驱动模式，主要事件类型包括：

1. **消息事件 (MessageEvent)**: 来自渠道的 inbound/outbound 消息
2. **工具调用事件 (ToolCallEvent)**: Agent 请求工具执行
3. **会话事件 (SessionEvent)**: 会话生命周期管理
4. **系统事件 (SystemEvent)**: 钩子触发、定时任务等

### 3.3 插件化设计

所有消息渠道均以插件形式实现：

```typescript
interface Channel {
  id: string;
  type: ChannelType;
  status: ChannelStatus;
  connect(): Promise<void>;
  sendMessage(to: string, text: string): Promise<void>;
  disconnect(): Promise<void>;
}
```

## 4. 核心子系统

### 4.1 Gateway (网关)

**职责**: WebSocket 控制平面，管理所有客户端连接和消息路由

核心组件:
- WebSocketServer: 处理客户端连接
- AuthHandler: Token/密码验证
- MethodRouter: WS 方法分发
- SessionManager: 会话状态管理
- ChannelManager: 渠道连接管理
- NodeRegistry: 设备节点注册

相关文件:
- `src/gateway/server.impl.ts` - 主服务器实现
- `src/gateway/client.ts` - 客户端连接管理
- `src/gateway/server-methods.ts` - WS 方法处理

### 4.2 Pi Agent (AI 代理运行时)

**职责**: 执行 AI 对话、工具调用和流式响应

核心组件:
- ACPConnection: Agent-Client Protocol 连接
- SessionCore: 会话核心逻辑
- Translator: 事件翻译层
- ToolRegistry: 工具注册和执行
- AuthProfileManager: 认证配置管理
- FailoverHandler: 服务故障切换

相关文件:
- `src/acp/translator.ts` - 事件翻译
- `src/acp/session.ts` - 会话管理
- `src/agents/auth-profiles.ts` - 认证配置

### 4.3 渠道层 (Channels)

**职责**: 与外部消息平台通信

支持的渠道:
- 核心渠道：Telegram, WhatsApp, Slack, Discord, Signal, iMessage
- 扩展渠道：IRC, Matrix, Teams, LINE, Mattermost 等

实现模式:
```
src/
├── telegram/       # grammY SDK
├── whatsapp/       # Baileys
├── slack/          # Bolt SDK
├── discord/        # discord.js
├── signal/         # signal-cli
└── imessage/       # BlueBubbles API
```

### 4.4 工具层 (Tools)

**职责**: 提供 AI 可调用的工具

内置工具:
| 工具 | 描述 |
|------|------|
| Browser | Playwright 浏览器控制 |
| Canvas | A2UI 画布操作 |
| Media | 图片/音频/视频处理 |
| Node | 设备节点调用 |
| Sessions | 会话间通信 |
| Cron | 定时任务管理 |

## 5. 数据流

### 5.1 典型消息处理流程

```
用户 (Telegram)
    │
    ▼
Telegram Handler
    │
    ▼
ChannelManager
    │
    ▼
Gateway WebSocket
    │
    ▼
Pi Agent (Session Core)
    │
    ▼
AI Service (OpenAI/Anthropic)
    │
    ▼
Response Generator
    │
    ▼
Gateway WebSocket
    │
    ▼
MessageRouter
    │
    ▼
Telegram Handler
    │
    ▼
用户 (Telegram)
```

### 5.2 工具调用流程

```
Pi Agent (Session Core)
    │
    ▼
Tool Registry
    │
    ▼
Browser Tool / Canvas Tool / Media Tool
    │
    ▼
Execute Tool Logic
    │
    ▼
Return Result
    │
    ▼
Response Generator
    │
    ▼
Stream to Gateway
```

## 6. 存储设计

### 6.1 SQLite 数据库

| 表名 | 描述 |
|------|------|
| `sessions` | 会话元数据、上下文 |
| `pairing` | 渠道配对信息 |
| `allowlist` | 允许的用户列表 |
| `memory` | 长期记忆存储 (可选) |

### 6.2 JSON 配置文件

| 文件 | 描述 |
|------|------|
| `~/.openclaw/config.json` | 主配置文件 |
| `~/.openclaw/credentials/` | 认证凭证 |
| `~/.openclaw/sessions/` | 会话数据 |

## 7. 安全设计

### 7.1 认证模式

| 模式 | 描述 |
|------|------|
| Token 认证 | JWT/Bearer Token |
| 密码认证 | 共享密码 (用于 Tailscale Funnel) |
| Tailscale | 可选的 tailnet 集成 |

### 7.2 隐私保护

- 配对机制：未知 DM 发送者需要配对码
- 白名单：允许的用户列表
- 本地存储：敏感数据本地保存
- 可选加密：支持端到端加密通道

## 8. 部署架构

### 8.1 单机部署

```
┌─────────────────────────────────────┐
│         User's Device               │
│  +───────────────────────────────+  │
│  │     OpenClaw Gateway          │  │
│  │  +─────────────────────────+  │  │
│  │  │   Pi Agent (RPC)        │  │  │
│  │  +─────────────────────────+  │  │
│  │  +─────────────────────────+  │  │
│  │  │   SQLite Storage        │  │  │
│  │  +─────────────────────────+  │  │
│  +───────────────────────────────+  │
└─────────────────────────────────────┘
```

### 8.2 远程网关部署

```
┌─────────────────────────────────────┐
│         Linux Server                │
│  +───────────────────────────────+  │
│  │     OpenClaw Gateway          │  │
│  │  +─────────────────────────+  │  │
│  │  │   SQLite Storage        │  │  │
│  │  +─────────────────────────+  │  │
│  +───────────────────────────────+  │
└─────────────────────────────────────┘
              │
         Tailscale/SSH
              │
    ┌─────────┼─────────┐
    │         │         │
    ▼         ▼         ▼
macOS App  iOS App  Android App
```

## 9. 关键设计决策

### 9.1 为什么选择 WebSocket 作为控制平面？

- **实时双向通信**: 支持流式响应和实时事件推送
- **低延迟**: 相比 HTTP 轮询，延迟更低
- **连接保持**: 长连接减少握手开销

### 9.2 为什么分离 Gateway 和 Agent？

- **关注点分离**: Gateway 处理网络和路由，Agent 处理 AI 逻辑
- **可扩展性**: 可以独立扩展两个组件
- **灵活性**: Agent 可以本地或远程运行

### 9.3 为什么使用插件化渠道设计？

- **可维护性**: 每个渠道独立开发和测试
- **可扩展性**: 轻松添加新渠道
- **选择性加载**: 只加载需要的渠道

## 10. 进一步阅读

- [项目结构说明](./project-structure.md)
- [组件详情](./component-details.md)
- [数据流分析](./data-flow.md)
- [代码审查报告](./code-review.md)

https://docs.openclaw.ai/gateway
https://docs.openclaw.ai/concepts/architecture
