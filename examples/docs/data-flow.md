# OpenClaw 数据流分析

## 1. 概述

本文档详细分析 OpenClaw 系统中的数据流，包括消息处理、工具调用、配置加载等关键流程。

---

## 2. 消息处理数据流

### 2.1 Inbound 消息流（从用户到 AI）

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         Inbound Message Flow                             │
└──────────────────────────────────────────────────────────────────────────┘

User (Telegram)
    │
    │ 1. 用户发送消息
    ▼
Telegram Bot API
    │
    │ 2. webhook/polling
    ▼
src/telegram/handlers/message.ts
    │ 3. 接收消息事件
    │    - 解析消息内容
    │    - 提取附件
    │    - 验证发送者
    ▼
src/telegram/channel.ts
    │ 4. Channel 实例处理
    │    - 转换为内部事件格式
    │    - 添加渠道元数据
    ▼
src/channels/manager.ts
    │ 5. ChannelManager 路由
    │    - 查找目标会话
    │    - 应用路由规则
    ▼
src/gateway/client.ts
    │ 6. GatewayClient 发送
    │    - WebSocket 事件
    │    - 事件类型：message.inbound
    ▼
src/gateway/server.impl.ts
    │ 7. WebSocket 服务器
    │    - 认证检查
    │    - 速率限制
    │    - 事件分发
    ▼
src/acp/translator.ts
    │ 8. Translator 翻译
    │    - Gateway 事件 → ACP 事件
    │    - 会话上下文加载
    ▼
src/agents/translator.ts
    │ 9. Agent 处理
    │    - Prompt 构建
    │    - 上下文窗口管理
    ▼
AI Service (OpenAI/Anthropic)
```

### 2.2 Outbound 消息流（从 AI 到用户）

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         Outbound Message Flow                            │
└──────────────────────────────────────────────────────────────────────────┘

AI Service
    │
    │ 1. 流式响应
    ▼
src/agents/translator.ts
    │ 2. Agent 处理响应
    │    - 解析流式内容
    │    - 提取工具调用
    ▼
src/acp/translator.ts
    │ 3. Translator 翻译
    │    - ACP 事件 → Gateway 事件
    │    - 流式转发
    ▼
src/gateway/server.impl.ts
    │ 4. WebSocket 服务器
    │    - 事件广播
    │    - 客户端推送
    ▼
src/gateway/client.ts
    │ 5. GatewayClient 分发
    │    - 路由到 ChannelManager
    ▼
src/channels/manager.ts
    │ 6. ChannelManager 路由
    │    - 查找目标渠道
    │    - 应用发送策略
    ▼
src/telegram/channel.ts
    │ 7. Channel 实例
    │    - 格式化消息
    │    - 处理附件
    ▼
src/telegram/handlers/message.ts
    │ 8. 发送消息
    │    - Telegram Bot API
    │    - 错误处理
    ▼
Telegram Bot API
    │
    │ 9. 推送给用户
    ▼
User (Telegram)
```

---

## 3. 工具调用数据流

### 3.1 工具执行流程

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         Tool Call Flow                                   │
└──────────────────────────────────────────────────────────────────────────┘

AI Model
    │
    │ 1. 返回 tool_call
    ▼
src/agents/translator.ts
    │ 2. 解析 tool_call
    │    - 提取工具名称
    │    - 提取参数
    │    - 验证 schema
    ▼
src/agents/tool-registry.ts
    │ 3. ToolRegistry 查找
    │    - 查找注册的工具
    │    - 权限检查
    │    - 预算检查
    ▼
src/browser/controller.ts (示例：Browser Tool)
    │ 4. 执行工具逻辑
    │    - 启动浏览器
    │    - 执行操作
    │    - 捕获结果
    ▼
src/agents/translator.ts
    │ 5. 收集结果
    │    - 格式化输出
    │    - 附加截图
    ▼
AI Model
    │
    │ 6. 处理工具结果
    ▼
(继续对话或返回最终响应)
```

### 3.2 Browser Tool 详细流程

```typescript
// src/browser/controller.ts
class BrowserController {
  private browser: Browser;

  async open(url: string): Promise<void> {
    // 1. 创建浏览器上下文
    const context = await this.browser.newContext();

    // 2. 创建页面
    const page = await context.newPage();

    // 3. 导航到 URL
    await page.goto(url, { waitUntil: "networkidle" });

    // 4. 等待内容加载
    await page.waitForLoadState("domcontentloaded");
  }

  async screenshot(): Promise<Buffer> {
    // 1. 捕获截图
    const buffer = await page.screenshot();

    // 2. 压缩图片
    const compressed = await sharp(buffer)
      .resize(800, 600, { fit: "inside" })
      .jpeg({ quality: 80 })
      .toBuffer();

    return compressed;
  }

  async click(selector: string): Promise<void> {
    // 1. 等待元素
    await page.waitForSelector(selector);

    // 2. 点击
    await page.click(selector);

    // 3. 等待导航
    await page.waitForLoadState("networkidle");
  }
}
```

---

## 4. 配置加载数据流

### 4.1 启动时配置加载

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       Configuration Load Flow                            │
└──────────────────────────────────────────────────────────────────────────┘

Process Start
    │
    ▼
src/runtime.js
    │ 1. 入口点
    │
    ▼
src/config/config.ts
    │ 2. loadConfig()
    │    - 读取 ~/.openclaw/config.json
    │    - 解析 JSON
    │    - 应用默认值
    ▼
src/config/migration.ts
    │ 3. 配置迁移
    │    - 检查版本
    │    - 应用迁移
    ▼
src/config/plugin-auto-enable.ts
    │ 4. 插件自动启用
    │    - 扫描 extensions/
    │    - 更新 config
    ▼
src/plugins/runtime/
    │ 5. 插件加载
    │    - 动态导入
    │    - 注册服务
    ▼
src/gateway/server.impl.ts
    │ 6. Gateway 启动
    │    - 使用配置
    │    - 启动服务
```

### 4.2 配置热重载

```
Config File Change (config.json)
    │
    ▼
chokidar (File Watcher)
    │
    │ 1. 检测变化
    ▼
src/config/config-reload.ts
    │ 2. 触发热重载
    │    - 读取新配置
    │    - 验证配置
    ▼
src/config/issue-format.ts
    │ 3. 配置验证
    │    - 检查问题
    │    - 生成警告
    ▼
src/gateway/config-reload-plan.ts
    │ 4. 制定重载计划
    │    - 确定需要重载的组件
    │    - 最小化中断
    ▼
src/gateway/server.impl.ts
    │ 5. 应用重载
    │    - 更新配置
    │    - 重启受影响的服务
    ▼
Gateway Running
    │
    │ 6. 继续运行
```

---

## 5. 认证配置数据流

### 5.1 Auth Profile 加载

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       Auth Profile Load Flow                             │
└──────────────────────────────────────────────────────────────────────────┘

~/.openclaw/credentials/
    │
    │ 1. 凭证文件
    ▼
src/secrets/runtime.ts
    │ 2. prepareSecretsRuntimeSnapshot()
    │    - 读取所有凭证
    │    - 解密敏感数据
    ▼
src/agents/auth-profiles.ts
    │ 3. 加载 Auth Profiles
    │    - 解析配置
    │    - 验证凭证
    ▼
src/agents/auth-profiles/credential-state.ts
    │ 4. 评估凭证状态
    │    - 检查过期
    │    - 检查速率限制
    ▼
src/agents/auth-profiles/runtime.ts
    │ 5. 运行时快照
    │    - 缓存活跃配置
    │    - 设置故障切换
    ▼
src/agents/translator.ts
    │ 6. Agent 使用
    │    - 选择配置
    │    - API 调用
```

### 5.2 故障切换流程

```
AI API Request
    │
    ▼
src/agents/auth-profiles.ts
    │ 1. 获取活跃配置
    │    - resolveAuthProfileOrder()
    ▼
src/agents/auth-profiles/runtime.ts
    │ 2. 按优先级排序
    │    - 基于 lastGood
    │    - 基于 cooldown
    ▼
AI API Call (Profile 1)
    │
    │ 3. 请求失败
    ▼
src/agents/auth-profiles.ts
    │ 4. markAuthProfileFailure()
    │    - 设置 cooldown
    │    - 更新 lastUsed
    ▼
src/agents/auth-profiles/runtime.ts
    │ 5. 获取下一个配置
    │    - 跳过 cooldown 的
    │    - 选择下一个
    ▼
AI API Call (Profile 2)
    │
    │ 6. 请求成功
    ▼
Update lastGood
    │
    ▼
返回结果
```

---

## 6. 会话管理数据流

### 6.1 会话创建

```
User Message (First Message)
    │
    ▼
src/gateway/server.impl.ts
    │ 1. 接收消息
    │    - 提取会话键
    ▼
src/gateway/session-utils.ts
    │ 2. resolveSessionKey()
    │    - 从消息提取
    │    - 标准化键
    ▼
src/sessions/store.ts
    │ 3. 查找会话
    │    - SQLite 查询
    │    - 未找到则创建
    ▼
src/gateway/server.impl.ts
    │ 4. 创建会话
    │    - 设置默认配置
    │    - 初始化上下文
    ▼
src/acp/session.ts
    │ 5. ACP 会话跟踪
    │    - 注册会话
    │    - 绑定流
```

### 6.2 会话上下文管理

```
Session Load
    │
    ▼
src/gateway/sessions.ts
    │ 1. 从 SQLite 加载
    │    - 读取历史消息
    │    - 限制数量
    ▼
src/acp/translator.ts
    │ 2. 构建上下文
    │    - 格式化消息
    │    - 附加工具调用
    ▼
src/context-engine/
    │ 3. 上下文窗口管理
    │    - 计算 token 数
    │    - 截断如果超限
    ▼
src/context-engine/compaction.ts
    │ 4. 可选压缩
    │    - LLM 总结
    │    - 保留关键信息
```

---

## 7. 媒体处理数据流

### 7.1 图片上传处理

```
User Uploads Image
    │
    ▼
Channel Handler
    │ 1. 接收文件
    │    - 下载附件
    │    - 保存到临时目录
    ▼
src/media/pipeline.ts
    │ 2. 媒体管道处理
    │    - 文件类型检测
    │    - 病毒扫描（可选）
    ▼
src/media/image.ts
    │ 3. 图片处理
    │    - 使用 sharp 调整大小
    │    - 压缩
    │    - 格式转换
    ▼
src/media/storage.ts
    │ 4. 存储
    │    - 移动到永久目录
    │    - 更新数据库
    ▼
AI Service
    │ 5. 发送分析
    │    - Vision API
    │    - 获取描述
```

### 7.2 音频处理

```
User Sends Voice Message
    │
    ▼
Channel Handler
    │ 1. 接收音频
    │    - OGG/MP3 格式
    ▼
src/media/audio.ts
    │ 2. 音频处理
    │    - 使用 ffmpeg 转换
    │    - 标准化音量
    ▼
src/tts/transcribe.ts
    │ 3. 语音转文字
    │    - Whisper API
    │    - 或本地模型
    ▼
AI Service
    │ 4. 文本处理
    │    - 正常对话流
```

---

## 8. 事件总线数据流

### 8.1 系统事件流

```
Event Occurs (e.g., gateway.start)
    │
    ▼
src/infra/system-events.ts
    │ 1. enqueueSystemEvent()
    │    - 创建事件对象
    │    - 加入队列
    ▼
src/infra/event-dispatcher.ts
    │ 2. 分发事件
    │    - 查找订阅者
    │    - 并行调用
    ▼
Subscribers
    │    - Hooks
    │    - Cron Jobs
    │    - Webhooks
    │    - Audit Log
```

### 8.2 钩子执行流

```
Hook Trigger (e.g., message.send)
    │
    ▼
src/hooks/manager.ts
    │ 1. 获取钩子配置
    │    - 从 config 读取
    ▼
src/hooks/executor.ts
    │ 2. 执行钩子
    │    - HTTP POST
    │    - 超时处理
    │    - 重试逻辑
    ▼
External Webhook
    │ 3. 外部服务处理
    │    - 返回结果
    ▼
src/hooks/manager.ts
    │ 4. 处理结果
    │    - 记录审计日志
    │    - 继续或中断
```

---

## 9. 数据持久化流

### 9.1 SQLite 写入流

```
Data to Persist (e.g., Session Update)
    │
    ▼
src/sessions/store.ts
    │ 1. 准备数据
    │    - 序列化
    │    - 验证
    ▼
src/infra/database.ts
    │ 2. 数据库操作
    │    - 获取连接
    │    - 执行 SQL
    ▼
better-sqlite3
    │ 3. 同步写入
    │    - WAL 模式
    │    - 事务支持
    ▼
Disk (~/.openclaw/sessions.db)
```

### 9.2 配置写入流

```
Config Change
    │
    ▼
src/config/config.ts
    │ 1. 验证配置
    │    - Schema 验证
    │    - 业务规则检查
    ▼
src/config/config.ts
    │ 2. 原子写入
    │    - 写入临时文件
    │    - 重命名覆盖
    ▼
~/.openclaw/config.json.tmp
    │
    │ 3. 原子重命名
    ▼
~/.openclaw/config.json
```

---

## 10. 性能优化点

### 10.1 缓存策略

| 数据类型 | 缓存位置 | 过期策略 |
|----------|----------|----------|
| 配置 | 内存 | 文件变化时 |
| 会话元数据 | 内存 + SQLite | 每次访问更新 |
| Auth Profile | 内存 | cooldown 或成功/失败 |
| 渠道状态 | 内存 | 定期刷新 |
| 技能列表 | 内存 | 5 分钟 TTL |

### 10.2 批量操作

```typescript
// 批量数据库写入
const batch = db.transaction((updates) => {
  for (const update of updates) {
    db.prepare("UPDATE sessions SET ...").run(update);
  }
});

batch(sessionUpdates);
```

### 10.3 流式处理

```typescript
// 流式响应处理
async function* streamResponse(agentStream: AsyncIterable<string>) {
  for await (const chunk of agentStream) {
    // 立即转发给客户端，不等待完整响应
    yield chunk;
  }
}
```

---

## 11. 错误恢复流

### 11.1 渠道重连

```
Channel Disconnect Detected
    │
    ▼
src/channels/manager.ts
    │ 1. 检测断开
    │    - 状态更新
    │    - 记录错误
    ▼
src/channels/reconnect.ts
    │ 2. 重连逻辑
    │    - 指数退避
    │    - 最大重试次数
    ▼
Channel.connect()
    │ 3. 重新连接
    │    - 成功：更新状态
    │    - 失败：继续退避
```

### 11.2 Gateway 重启

```
Gateway Crash
    │
    ▼
Process Manager (launchd/systemd)
    │ 1. 检测进程退出
    │
    ▼
Restart Policy
    │ 2. 决定是否重启
    │    - 退出码检查
    │    - 重启延迟
    ▼
Gateway Start
    │ 3. 重新启动
    │    - 加载配置
    │    - 恢复连接
```

---

## 12. 监控和可观测性

### 12.1 日志流

```
Application Log
    │
    ▼
src/logging/subsystem.ts
    │ 1. 结构化日志
    │    - JSON 格式
    │    - 元数据附加
    ▼
Console / File
    │
    ▼
Log Aggregator (可选)
    │
    ▼
Monitoring Dashboard
```

### 12.2 指标收集

```typescript
// 性能指标
metrics.histogram("gateway.request.duration", durationMs);
metrics.counter("gateway.messages.inbound", 1);
metrics.gauge("gateway.sessions.active", activeSessions);
```

---

**文档更新日期**: 2026-03-14

https://docs.openclaw.ai/gateway
https://docs.openclaw.ai/concepts/architecture
