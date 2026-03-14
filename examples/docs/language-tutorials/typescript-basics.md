# TypeScript 基础教程 - OpenClaw 代码示例

本教程通过 OpenClaw 项目中的实际代码示例，帮助你学习 TypeScript 的核心概念。

## 目录

1. [TypeScript 是什么？](#1-typescript-是什么)
2. [基础类型](#2-基础类型)
3. [接口和类型别名](#3-接口和类型别名)
4. [泛型](#4-泛型)
5. [异步编程](#5-异步编程)
6. [模块系统](#6-模块系统)
7. [类与面向对象](#7-类与面向对象)
8. [高级类型](#8-高级类型)

---

## 1. TypeScript 是什么？

### 1.1 是什么

TypeScript 是 JavaScript 的超集，由微软开发。它在 JavaScript 的基础上添加了**类型系统**。

```typescript
// JavaScript - 运行时才能发现错误
function add(a, b) {
  return a + b;
}
add(1, "2"); // 得到 "12"，可能不是你想要的

// TypeScript - 编译时就能发现错误
function add(a: number, b: number): number {
  return a + b;
}
add(1, "2"); // 编译错误：类型不匹配
```

### 1.2 有什么用

- **类型安全**: 在编译时发现类型错误
- **智能提示**: IDE 提供更好的代码补全
- **重构友好**: 更容易安全地重构代码
- **文档即代码**: 类型本身就是文档

### 1.3 为什么要用

在 OpenClaw 这样的大型项目中，TypeScript 帮助：
- 防止数百万行代码中的类型错误
- 让多人协作更安全
- 减少运行时 bug

---

## 2. 基础类型

### 2.1 基本类型

```typescript
// 布尔值
const isGatewayRunning: boolean = true;

// 数字
const port: number = 18789;
const maxRetries: number = 3;

// 字符串
const gatewayHost: string = "localhost";
const welcomeMessage: string = `Gateway running on port ${port}`;

// 数组
const channels: string[] = ["telegram", "whatsapp", "slack"];
const ports: number[] = [18789, 18790, 18791];

// 元组 (固定长度的数组)
const config: [string, number] = ["localhost", 18789];

// any (谨慎使用)
let unknownValue: any = "could be anything";
```

### 2.2 OpenClaw 示例

```typescript
// src/gateway/server.impl.ts
const MAX_PROMPT_BYTES = 2 * 1024 * 1024;  // 2MB 限制

// src/config/config.ts
export interface GatewayConfig {
  bind: string;      // "loopback" | "any"
  port: number;      // 18789
  auth: {
    mode: string;    // "token" | "password"
  };
}
```

### 2.3 联合类型

```typescript
// 可以是多种类型之一
type ChannelId = string | number;
type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";

// OpenClaw 示例
type ChannelType =
  | "telegram"
  | "whatsapp"
  | "slack"
  | "discord"
  | "signal"
  | "imessage";
```

### 2.4 类型别名

```typescript
// 为复杂类型创建简短的别名
type SessionKey = {
  channelId?: string;
  accountId?: string;
  roomId?: string;
  threadId?: string;
};

// 使用
const key: SessionKey = {
  channelId: "telegram",
  accountId: "user123"
};
```

---

## 3. 接口和类型别名

### 3.1 接口定义

```typescript
// 接口定义对象的形状
interface Channel {
  id: string;
  type: string;
  status: ChannelStatus;
  connect(): Promise<void>;
  sendMessage(to: string, text: string): Promise<void>;
  disconnect(): Promise<void>;
}
```

### 3.2 OpenClaw 实际示例

```typescript
// src/channels/types.ts (简化示例)
interface ChannelConfig {
  enabled: boolean;
  type: ChannelType;
  credentials: Record<string, string>;
  settings?: ChannelSettings;
}

interface ChannelStatus {
  connected: boolean;
  lastSeen: Date;
  error?: string;
}

// 实现接口的类
class TelegramChannel implements Channel {
  id: string;
  type: string = "telegram";
  status: ChannelStatus;

  async connect(): Promise<void> {
    // 连接逻辑
  }

  async sendMessage(to: string, text: string): Promise<void> {
    // 发送消息逻辑
  }

  async disconnect(): Promise<void> {
    // 断开连接逻辑
  }
}
```

### 3.3 类型别名 vs 接口

```typescript
// 类型别名
type AuthConfig = {
  mode: "token" | "password";
  token?: string;
};

// 接口
interface AuthConfig {
  mode: "token" | "password";
  token?: string;
}

// 区别：接口可以合并（declaration merging），类型别名不行
// 推荐：对象形状用 interface，其他用 type
```

---

## 4. 泛型

### 4.1 是什么

泛型允许你创建可重用的、类型安全的组件。

```typescript
// 没有泛型 - 需要为每个类型写重载
function wrapInArray<T>(value: T): T[] {
  return [value];
}

// 使用
const strings: string[] = wrapInArray("hello");
const numbers: number[] = wrapInArray(42);
```

### 4.2 OpenClaw 示例

```typescript
// src/infra/fixed-window-rate-limit.ts (简化)
function createFixedWindowRateLimiter<TConfig extends RateLimitConfig>(
  config: TConfig
): RateLimiter<TConfig> {
  // 实现
}

// 泛型约束
interface RateLimitConfig {
  maxRequests: number;
  windowMs: number;
}
```

### 4.3 泛型工具类型

```typescript
// Partial - 所有属性可选
type PartialConfig = Partial<GatewayConfig>;

// Required - 所有属性必填
type RequiredConfig = Required<GatewayConfig>;

// Pick - 选择特定属性
type AuthOnly = Pick<GatewayConfig, "auth">;

// Omit - 排除特定属性
type WithoutAuth = Omit<GatewayConfig, "auth">;
```

---

## 5. 异步编程

### 5.1 Promise 基础

```typescript
// 创建 Promise
function connectToGateway(): Promise<void> {
  return new Promise((resolve, reject) => {
    // 异步操作
    if (success) {
      resolve();
    } else {
      reject(new Error("Connection failed"));
    }
  });
}
```

### 5.2 async/await

```typescript
// OpenClaw 示例 - src/gateway/client.ts
async function startGateway(): Promise<void> {
  const config = loadConfig();
  const connection = buildGatewayConnectionDetails({ config });
  const creds = await resolveGatewayConnectionAuth({
    config,
    connection
  });

  const gateway = new GatewayClient({
    url: connection.url,
    token: creds.token,
    // ...
  });

  gateway.start();
  await gatewayReady;  // 等待 gateway 就绪
}
```

### 5.3 错误处理

```typescript
async function safeOperation(): Promise<Result> {
  try {
    const result = await riskyOperation();
    return { success: true, data: result };
  } catch (error) {
    if (error instanceof NetworkError) {
      return { success: false, error: "Network failed" };
    }
    throw error;  // 重新抛出未知错误
  }
}
```

### 5.4 Promise 组合

```typescript
// Promise.all - 并行执行多个
const [channels, nodes, sessions] = await Promise.all([
  loadChannels(),
  loadNodes(),
  loadSessions()
]);

// Promise.race - 谁快用谁
const result = await Promise.race([
  fetchWithTimeout(),
  timeout(5000)
]);

// Promise.allSettled - 等待所有完成
const results = await Promise.allSettled([
  task1(),
  task2(),
  task3()
]);
```

---

## 6. 模块系统

### 6.1 ES Modules

```typescript
// 导出
export const PORT = 18789;
export function startGateway() { /* ... */ }
export default GatewayServer;

// 导入
import GatewayServer, { PORT, startGateway } from "./gateway";
```

### 6.2 OpenClaw 模块结构

```typescript
// src/gateway/server.ts - 统一导出
export { truncateCloseReason } from "./server/close-reason.js";
export type { GatewayServer, GatewayServerOptions } from "./server.impl.js";
export { startGatewayServer } from "./server.impl.js";
```

### 6.3 循环依赖避免

```typescript
// ❌ 错误：循环依赖
// a.ts
import { b } from "./b";
export const a = 1;

// b.ts
import { a } from "./a";
export const b = 2;

// ✅ 正确：使用接口解耦
// types.ts
export interface Service {
  doSomething(): void;
}

// a.ts
import type { Service } from "./types";
export class ServiceA implements Service { /* ... */ }

// b.ts
import type { Service } from "./types";
export class ServiceB implements Service { /* ... */ }
```

---

## 7. 类与面向对象

### 7.1 类定义

```typescript
class GatewayClient {
  // 属性
  private url: string;
  private token: string;
  public isConnected: boolean = false;

  // 构造函数
  constructor(options: GatewayOptions) {
    this.url = options.url;
    this.token = options.token;
  }

  // 方法
  public start(): void {
    // 启动逻辑
  }

  public stop(): void {
    // 停止逻辑
  }
}
```

### 7.2 继承

```typescript
// 基类
abstract class Channel {
  abstract connect(): Promise<void>;
  abstract sendMessage(to: string, text: string): Promise<void>;
}

// 派生类
class TelegramChannel extends Channel {
  async connect(): Promise<void> {
    // Telegram 特定实现
  }

  async sendMessage(to: string, text: string): Promise<void> {
    // Telegram 特定实现
  }
}
```

### 7.3 OpenClaw 示例

```typescript
// src/agents/auth-profiles.ts (简化)
class AuthProfileManager {
  private profiles: Map<string, AuthProfile> = new Map();

  async getActiveProfile(): Promise<AuthProfile> {
    // 获取活跃配置
  }

  async markProfileFailure(profileId: string): Promise<void> {
    // 标记配置失败
  }
}
```

---

## 8. 高级类型

### 8.1 字面量类型

```typescript
type HttpMethod = "GET" | "POST" | "PUT" | "DELETE";
type LogLevel = "debug" | "info" | "warn" | "error";

// OpenClaw 示例
type GatewayClientMode = "cli" | "gui" | "daemon";
```

### 8.2 映射类型

```typescript
// 将属性变为只读
type ReadonlyConfig = Readonly<GatewayConfig>;

// 将属性变为可选
type PartialSession = Partial<GatewaySession>;
```

### 8.3 条件类型

```typescript
// 提取函数返回类型
type GatewayType = ReturnType<typeof createGateway>;

// 提取参数类型
type ConfigType = Parameters<typeof loadConfig>[0];
```

### 8.4 模板字面类型

```typescript
// 基于字符串的模式创建类型
type EventName<T extends string> = `${T}Event`;
type GatewayEventName = EventName<"gateway">;  // "gatewayEvent"

// OpenClaw 实际使用
type HookEventType =
  | "gateway.start"
  | "gateway.stop"
  | "channel.connect"
  | "channel.disconnect";
```

---

## 9. 实战练习

### 9.1 实现一个简单的 Rate Limiter

```typescript
interface RateLimitConfig {
  maxRequests: number;
  windowMs: number;
}

class RateLimiter {
  private requests: number[] = [];
  private config: RateLimitConfig;

  constructor(config: RateLimitConfig) {
    this.config = config;
  }

  async acquire(): Promise<void> {
    const now = Date.now();

    // 移除窗口外的请求
    this.requests = this.requests.filter(
      time => now - time < this.config.windowMs
    );

    if (this.requests.length >= this.config.maxRequests) {
      throw new Error("Rate limit exceeded");
    }

    this.requests.push(now);
  }
}

// 使用
const limiter = new RateLimiter({ maxRequests: 100, windowMs: 60000 });
await limiter.acquire();
```

### 9.2 实现一个类型安全的 EventEmitter

```typescript
type EventMap = {
  "gateway.start": () => void;
  "gateway.stop": (reason: string) => void;
  "message.receive": (msg: MessageEvent) => void;
};

class TypedEventEmitter {
  private listeners: Map<keyof EventMap, Function[]> = new Map();

  on<K extends keyof EventMap>(event: K, callback: EventMap[K]): void {
    const callbacks = this.listeners.get(event) || [];
    callbacks.push(callback);
    this.listeners.set(event, callbacks);
  }

  emit<K extends keyof EventMap>(
    event: K,
    ...args: Parameters<EventMap[K]>
  ): void {
    const callbacks = this.listeners.get(event) || [];
    callbacks.forEach(cb => cb(...args));
  }
}
```

---

## 10. 最佳实践

### 10.1 类型安全

```typescript
// ✅ 好的实践
function processMessage(message: MessageEvent): void {
  // 类型安全
}

// ❌ 避免
function processMessage(message: any): any {
  // 失去类型安全
}
```

### 10.2 窄化类型

```typescript
function handleValue(value: string | number): void {
  if (typeof value === "string") {
    // value 在这里是 string
    console.log(value.toUpperCase());
  } else {
    // value 在这里是 number
    console.log(value.toFixed(2));
  }
}
```

### 10.3 使用 const 断言

```typescript
// 让编译器推断最具体的类型
const config = {
  port: 18789,
  bind: "loopback"
} as const;

// config.port 是 18789 (字面量类型)，而不是 number
// config.bind 是 "loopback" (字面量类型)，而不是 string
```

---

## 下一步

- 阅读 [项目结构说明](./project-structure.md) 了解代码组织
- 阅读 [架构概览](./architecture-overview.md) 了解系统设计
- 查看 OpenClaw 源码中的实际实现

https://docs.openclaw.ai
