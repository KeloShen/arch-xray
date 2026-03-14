# arch-xray 架构 X 光

> **一眼看透你的代码库 · 30 分钟从陌生到上手**

---

## 🎯 能做什么？

| 功能              | 说明                                                                |
| ----------------- | ------------------------------------------------------------------- |
| 📐**生成架构图**   | C4 标准 PlantUML 图表（Context/Container/Component/Sequence/Class） |
| 🔍**分析代码结构** | 文件夹组织、文件互动、函数调用链                                    |
| 🛠️**技术栈识别**   | 自动识别框架、库和核心技术                                          |
| 📋**代码审查**     | 指出 bug、安全漏洞、最佳实践建议                                    |
| 📚**语言教学**     | 项目使用的编程语言语法教学                                          |
| 🧭**开发引导**     | 实现新功能的详细步骤                                                |

---

## 📸 效果示例（以分析 OpenClaw 为例）

运行 arch-xray 后，生成完整的分析报告：

```
xray/
├── docs/
│   ├── architecture-overview.md     # 架构概览（含 SVG 图）
│   ├── component-details.md         # 组件详情
│   ├── data-flow.md                 # 数据流分析
│   ├── project-structure.md         # 项目结构说明
│   ├── code-review.md               # 代码审查报告
│   └── language-tutorials/          # 编程语言教程
└── assets/diagrams/
    ├── context.svg                  # 系统上下文图
    ├── container.svg                # 容器图
    ├── component-gateway.svg        # Gateway 组件图
    ├── component-agent.svg          # Agent 组件图
    └── class-core.svg               # 核心类图
```

### 📊 生成的架构图

#### L1 - 系统上下文图 (Context Diagram)

![Context Diagram](./examples/assets/diagrams/context.svg)

展示系统与外部用户/系统的关系

---

#### L2 - 容器图 (Container Diagram)

![Container Diagram](./examples/assets/diagrams/container.svg)

展示前端/后端/数据库等容器划分

---

#### L3 - 组件图 (Component Diagram)

![Component - Gateway](./examples/assets/diagrams/component-gateway.svg)

**Gateway 服务内部组件**

![Component - Agent](./examples/assets/diagrams/component-agent.svg)

**Pi Agent 运行时内部组件**

---

#### L4 - 类图 (Class Diagram)

![Class Diagram](./examples/assets/diagrams/class-core.svg)

核心类的设计和关系

---

### 📄 生成的文档示例

#### 架构概览文档

生成类似 [architecture-overview.md](./examples/docs/architecture-overview.md) 的文档，包含：

- 系统简介与核心价值
- 技术栈识别与说明
- 核心子系统详解
- 数据流分析
- 安全设计说明
- 部署架构图解

#### 代码审查报告

生成类似 [code-review.md](./examples/docs/code-review.md) 的报告，包含：

| 维度     | 评分  | 说明                             |
| -------- | ----- | -------------------------------- |
| 代码质量 | 4.5/5 | 类型安全、结构清晰、测试覆盖率高 |
| 安全性   | 4/5   | 良好的安全实践，少数需要注意的点 |
| 可维护性 | 4.5/5 | 模块化设计、命名规范、文档完善   |
| 性能     | 4/5   | 合理的优化，有进一步提升空间     |
| 测试覆盖 | 4/5   | 测试覆盖率高，部分边界情况可加强 |

**具体问题分析示例：**

```typescript
// ⚠️ 发现的问题：文件大小超过建议值
src/gateway/server.impl.ts    ~1200 行
src/agents/auth-profiles.ts   ~900 行

// ✅ 建议：拆分为更小的模块
src/gateway/
├── server.impl.ts        # 主入口
├── server.auth.ts        # 认证逻辑
├── server.methods.ts     # WS 方法处理
├── server.channels.ts    # 渠道管理
└── server.sessions.ts    # 会话管理
```

**安全风险示例：**

| 风险等级 | 问题                 | 建议                     |
| :------- | -------------------- | ------------------------ |
| 🔴 高     | Prompt 缺少大小限制  | 添加 2MB 限制防止 DoS    |
| 🟡 中     | 输入缺少类型验证     | 使用 Zod 等库进行验证    |
| 🟢 低     | 错误信息可能泄露细节 | 内部错误不直接返回给用户 |

---

## 🚀 Quick Start

### 1. 安装 PlantUML

**macOS**

```bash
brew install plantuml
```

**Linux**

```bash
sudo apt-get install plantuml
```

**Windows**

```powershell
scoop install plantuml
# 或
choco install plantuml
```

> 💡 **懒人方法**：直接告诉 AI Agent
> "检测我的运行系统环境，帮我安装 plantuml"

### 2. 安装 arch-xray

使用 [OpenSkills](https://github.com/numman-ali/openskills) 加载技能：

```bash
# 安装 OpenSkills（可选）
npm i -g openskills

# 一键安装 arch-xray
npx openskills install keloshen/arch-xray

# 确认安装
npx openskills list
```

---

## 💡 如何使用

### 自动触发

当你说这些话时，技能会**自动激活**：

- "我想学习这个代码库"
- "这个系统是怎么工作的？"
- "帮我分析一下架构"
- "如何实现 X 功能？"
- "帮我画个架构图"

### 手动触发

在 Claude Code / Cursor 中输入：

```
/arch-xray
```

然后描述你的需求即可。

---

## 📖 使用示例

| 场景             | 命令                            | 输出                                  |
| ---------------- | ------------------------------- | ------------------------------------- |
| **分析整个项目** | `帮我分析这个项目的架构`        | Context + Container 图 + 架构概览文档 |
| **查看特定模块** | `分析 src/services 目录`        | Component 图 + 文件互动分析           |
| **代码审查**     | `这段代码有什么潜在问题？`      | 风险清单 + 改进建议                   |
| **学习新技术**   | `这个项目用了 TypeScript，教我` | 语法教程 + 项目实例                   |
| **开发新功能**   | `如何添加一个新的 API 端点？`   | 逐步引导 + 相关文件清单               |

---

## 📁 完整输出结构

查看 [examples/](./examples/) 目录，包含完整的 OpenClaw 分析报告：

- [架构概览](./examples/docs/architecture-overview.md)
- [组件详情](./examples/docs/component-details.md)
- [数据流分析](./examples/docs/data-flow.md)
- [代码审查报告](./examples/docs/code-review.md)
- [项目结构说明](./examples/docs/project-structure.md)
- [TypeScript 教程](./examples/docs/language-tutorials/typescript-basics.md)

---

> *arch-xray - 让架构一目了然*
