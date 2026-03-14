# OpenClaw 开发引导

## 1. 简介

本引导文档帮助开发者快速上手 OpenClaw 项目开发，包括环境设置、代码修改、测试和调试。

---

## 2. 开发环境设置

### 2.1 前置要求

| 工具 | 版本 | 用途 |
|------|------|------|
| Node.js | ≥22.12 | 运行时 |
| pnpm | ≥10.23 | 包管理 |
| Git | latest | 版本控制 |

### 2.2 克隆和安装

```bash
# 克隆仓库
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# 安装依赖
pnpm install

# 构建项目
pnpm build

# 运行开发服务器
pnpm gateway:watch
```

### 2.3 配置开发环境

```bash
# 创建配置文件
mkdir -p ~/.openclaw
cat > ~/.openclaw/config.json <<EOF
{
  "gateway": {
    "bind": "loopback",
    "port": 18789,
    "auth": {
      "mode": "token"
    }
  },
  "models": {
    "providers": {
      "openai": {
        "apiKey": "your-api-key"
      }
    }
  }
}
EOF
```

---

## 3. 代码修改指南

### 3.1 添加新渠道

**场景**: 添加一个新的消息渠道（如微信）

**步骤 1**: 创建渠道目录

```bash
mkdir -p src/wechat/{handlers,pairs}
```

**步骤 2**: 实现 Channel 接口

```typescript
// src/wechat/channel.ts
import type { Channel, ChannelStatus } from "../channels/types";

export class WeChatChannel implements Channel {
  public id = "wechat";
  public type = "wechat";
  public status: ChannelStatus = { connected: false, lastSeen: new Date() };

  async connect(): Promise<void> {
    // 实现连接逻辑
  }

  async sendMessage(to: string, text: string): Promise<void> {
    // 实现发送消息
  }

  async disconnect(): Promise<void> {
    // 实现断开连接
  }
}
```

**步骤 3**: 注册渠道

```typescript
// src/channels/plugins/index.ts
import { WeChatChannel } from "../../wechat/channel";

export function createWeChatChannel(): WeChatChannel {
  return new WeChatChannel();
}
```

**步骤 4**: 添加配置类型

```typescript
// src/config/config.ts
export interface WeChatConfig {
  enabled: boolean;
  appId: string;
  appSecret: string;
  token: string;
}
```

**步骤 5**: 添加测试

```typescript
// src/wechat/channel.test.ts
import { describe, it, expect } from "vitest";
import { WeChatChannel } from "./channel";

describe("WeChatChannel", () => {
  it("should connect successfully", async () => {
    const channel = new WeChatChannel();
    await channel.connect();
    expect(channel.status.connected).toBe(true);
  });
});
```

### 3.2 添加新工具

**场景**: 添加一个新的 AI 工具（如天气查询）

**步骤 1**: 创建工具定义

```typescript
// src/tools/weather.ts
import type { Tool } from "./types";

export const weatherTool: Tool = {
  name: "weather.get",
  description: "Get current weather for a location",
  inputSchema: {
    type: "object",
    properties: {
      location: {
        type: "string",
        description: "City name or coordinates",
      },
    },
    required: ["location"],
  },

  async execute(input: { location: string }): Promise<any> {
    // 调用天气 API
    const response = await fetch(
      `https://api.weather.com/weather/${input.location}`
    );
    return response.json();
  },
};
```

**步骤 2**: 注册工具

```typescript
// src/tools/registry.ts
import { weatherTool } from "./weather";

export function createToolRegistry(): ToolRegistry {
  const registry = new ToolRegistry();
  registry.register(weatherTool);
  return registry;
}
```

**步骤 3**: 添加测试

```typescript
// src/tools/weather.test.ts
import { describe, it, expect, vi } from "vitest";
import { weatherTool } from "./weather";

describe("weatherTool", () => {
  it("should return weather data", async () => {
    global.fetch = vi.fn(() =>
      Promise.resolve({
        json: () => Promise.resolve({ temp: 25, condition: "sunny" }),
      })
    );

    const result = await weatherTool.execute({ location: "Shanghai" });
    expect(result.temp).toBe(25);
  });
});
```

### 3.3 修改现有功能

**场景**: 修改 Gateway 认证逻辑

**步骤 1**: 定位相关代码

```bash
# 搜索认证相关代码
pnpm grep -r "auth" src/gateway/
```

**步骤 2**: 理解现有实现

```typescript
// src/gateway/auth.ts
export async function authenticateRequest(
  req: Request,
  config: GatewayConfig
): Promise<AuthResult> {
  // 现有实现
}
```

**步骤 3**: 修改并测试

```typescript
// 修改后
export async function authenticateRequest(
  req: Request,
  config: GatewayConfig
): Promise<AuthResult> {
  // 新增：检查速率限制
  const rateLimitOk = await checkRateLimit(req.ip);
  if (!rateLimitOk) {
    return { success: false, reason: "rate_limited" };
  }

  // 原有逻辑
  // ...
}
```

**步骤 4**: 运行测试

```bash
pnpm test -- src/gateway/auth.test.ts
```

---

## 4. 测试指南

### 4.1 运行测试

```bash
# 运行所有测试
pnpm test

# 运行特定测试
pnpm test -- src/gateway/auth.test.ts

# 运行带过滤的测试
pnpm test -- -t "authentication"

# 运行覆盖率测试
pnpm test:coverage

# 运行实时测试（需要真实 API key）
pnpm test:live
```

### 4.2 编写测试

```typescript
// src/example.test.ts
import { describe, it, expect, vi, beforeEach } from "vitest";
import { someFunction } from "./example";

describe("someFunction", () => {
  beforeEach(() => {
    // 每个测试前重置
    vi.clearAllMocks();
  });

  it("should return expected value", () => {
    const result = someFunction("input");
    expect(result).toBe("expected");
  });

  it("should handle errors", async () => {
    await expect(someFunction(null)).rejects.toThrow("Invalid input");
  });

  it("should call dependency", async () => {
    const mockDependency = vi.fn().mockResolvedValue("mocked");
    await someFunction("input", mockDependency);
    expect(mockDependency).toHaveBeenCalledWith("input");
  });
});
```

### 4.3 测试最佳实践

```typescript
// ✅ 好的测试命名
describe("GatewayClient", () => {
  describe("connect", () => {
    it("should establish WebSocket connection", async () => {});
    it("should reject invalid credentials", async () => {});
    it("should handle connection timeout", async () => {});
  });
});

// ✅ 使用测试数据工厂
function createMockSession(overrides = {}): GatewaySession {
  return {
    id: "test-session",
    key: { channelId: "telegram" },
    displayName: "Test Session",
    ...overrides,
  };
}

// ✅ 清理资源
afterEach(() => {
  cleanupResources();
});
```

---

## 5. 调试指南

### 5.1 日志调试

```bash
# 启用详细日志
OPENCLAW_LOG_LEVEL=debug pnpm openclaw gateway

# 启用诊断事件
OPENCLAW_DIAGNOSTICS=1 pnpm openclaw gateway

# 查看 macOS 日志
./scripts/clawlog.sh
```

### 5.2 VS Code 调试配置

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Gateway Debug",
      "type": "node",
      "request": "launch",
      "cwd": "${workspaceFolder}",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["openclaw", "gateway"],
      "console": "integratedTerminal",
      "env": {
        "OPENCLAW_LOG_LEVEL": "debug"
      }
    },
    {
      "name": "Test Debug",
      "type": "node",
      "request": "launch",
      "cwd": "${workspaceFolder}",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["test", "--run", "${file}"],
      "console": "integratedTerminal"
    }
  ]
}
```

### 5.3 常见问题排查

**问题 1**: Gateway 启动失败

```bash
# 检查端口占用
lsof -i :18789

# 检查配置
openclaw doctor

# 查看日志
tail -f ~/.openclaw/logs/gateway.log
```

**问题 2**: 渠道连接失败

```bash
# 检查渠道配置
pnpm openclaw channels status

# 重新配对
pnpm openclaw pairing approve <channel> <code>

# 检查日志
pnpm openclaw gateway --verbose
```

**问题 3**: AI API 调用失败

```bash
# 检查认证配置
pnpm openclaw config get models

# 测试 API 连接
pnpm test:live -- src/agents/anthropic.setup-token.live.test.ts
```

---

## 6. 代码质量

### 6.1 运行代码检查

```bash
# 运行 lint
pnpm check

# 运行格式化检查
pnpm format

# 运行类型检查
pnpm tsgo
```

### 6.2 自动修复

```bash
# 自动格式化
pnpm format:fix

# 自动修复 lint 问题
pnpm lint:fix
```

### 6.3 代码风格指南

```typescript
// ✅ 使用类型注解
const port: number = 18789;

// ✅ 使用接口定义对象形状
interface Config {
  port: number;
  host: string;
}

// ✅ 错误处理
try {
  await riskyOperation();
} catch (error) {
  log.error("Operation failed", error);
  throw new GatewayError("Failed to complete operation");
}

// ❌ 避免使用 any
function process(data: any) {}  // ❌
function process(data: unknown) {}  // ✅

// ❌ 避免魔法数字
setTimeout(callback, 30000);  // ❌
const CONNECTION_TIMEOUT_MS = 30000;
setTimeout(callback, CONNECTION_TIMEOUT_MS);  // ✅
```

---

## 7. 提交代码

### 7.1 提交规范

```bash
# 使用提供的脚本
./scripts/committer "feat: add weather tool" src/tools/weather.ts

# 或者手动提交
git add src/tools/weather.ts
git commit -m "feat: add weather tool

- Implement weather.get tool
- Add unit tests
- Update documentation"
```

### 7.2 提交类型

| 类型 | 描述 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档更新 |
| style | 代码格式 |
| refactor | 重构 |
| test | 测试相关 |
| chore | 构建/工具 |

### 7.3 创建 PR

```bash
# 推送到分支
git push origin feature/weather-tool

# 创建 PR（使用 GitHub CLI）
gh pr create \
  --title "feat: add weather tool" \
  --body "Implements weather.get tool for querying current weather." \
  --base main
```

---

## 8. 架构决策

### 8.1 何时添加新文件

```
单一职责原则：
- 如果一个函数超过 50 行，考虑拆分
- 如果一个文件超过 500 行，考虑拆分
- 如果一个模块有多个职责，考虑拆分
```

### 8.2 何时添加新依赖

```bash
# 评估新依赖
# 1. 是否必须？
# 2. 是否有更轻量的替代？
# 3. 是否维护活跃？
# 4. 是否有安全风险？

# 添加依赖
pnpm add <package>

# 添加开发依赖
pnpm add -D <package>
```

### 8.3 何时编写文档

- 添加新功能时
- 修改公共 API 时
- 修复复杂 bug 时
- 添加配置选项时

---

## 9. 性能优化

### 9.1 性能分析

```bash
# 运行性能测试
pnpm test:perf:budget

# 分析热点
pnpm test:perf:hotspots
```

### 9.2 优化建议

```typescript
// ✅ 使用缓存
const cache = new Map<string, unknown>();
async function getCached(key: string) {
  if (cache.has(key)) return cache.get(key);
  const value = await compute(key);
  cache.set(key, value);
  return value;
}

// ✅ 批量操作
const batch = db.transaction((items) => {
  for (const item of items) {
    db.prepare("INSERT ...").run(item);
  }
});

// ✅ 流式处理
async function* streamData() {
  for await (const chunk of source) {
    yield process(chunk);
  }
}
```

---

## 10. 安全实践

### 10.1 输入验证

```typescript
// ✅ 验证用户输入
function validateMessage(text: unknown): string {
  if (typeof text !== "string") {
    throw new Error("Message must be a string");
  }
  if (text.length > MAX_MESSAGE_LENGTH) {
    throw new Error("Message too long");
  }
  return text;
}
```

### 10.2 密钥管理

```typescript
// ✅ 从环境变量或配置文件读取
const apiKey = process.env.OPENAI_API_KEY;

// ❌ 不要硬编码
const apiKey = "sk-xxx";  // ❌
```

### 10.3 速率限制

```typescript
// ✅ 实施速率限制
const limiter = createRateLimiter({
  maxRequests: 100,
  windowMs: 60000,
});

await limiter.acquire();  // 可能被拒绝
```

---

## 11. 进一步阅读

- [架构概览](./architecture-overview.md)
- [项目结构](./project-structure.md)
- [代码审查报告](./code-review.md)
- [TypeScript 教程](./language-tutorials/typescript-basics.md)

https://docs.openclaw.ai/gateway
https://docs.openclaw.ai/plugins
