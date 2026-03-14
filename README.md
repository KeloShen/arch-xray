# arch-xray 架构 X 光

> 系统架构分析技能 - 一眼看透你的代码库

---

## 这个技能能干什么？

**arch-xray** 是一个系统架构分析技能，当你面对新代码库感到迷茫时，它能帮你：

| 功能             | 说明                                                                     |
| ---------------- | ------------------------------------------------------------------------ |
| **生成架构图**   | 自动绘制 C4 标准的 PlantUML 图表（Context/Container/Component/Sequence） |
| **分析代码结构** | 解释文件夹组织、文件互动关系、函数调用链                                 |
| **技术栈识别**   | 识别项目使用的框架、库和核心技术                                         |
| **代码审查**     | 指出潜在 bug、安全漏洞、最佳实践建议                                     |
| **语言教学**     | 提供项目中使用的编程语言语法教学                                         |
| **开发引导**     | 提供实现新功能的详细步骤引导                                             |

---

## 输出示例

运行后会在项目根目录生成 `xray/` 目录：

```
xray/
├── README.md                        # 快速开始指南
├── docs/                            # 文档目录 - 直接打开查看
│   ├── architecture-overview.md     # 架构概览（含 SVG 图）
│   ├── component-details.md         # 组件详情
│   ├── data-flow.md                 # 数据流分析
│   ├── project-structure.md         # 项目结构说明
│   ├── code-review.md               # 代码审查报告
│   └── language-tutorials/          # 编程语言教程
│       ├── java-basics.md
│       └── typescript-basics.md
└── assets/
    └── diagrams/                    # PlantUML 源文件和 SVG 图片
        ├── context.puml / .svg      # 系统上下文图
        ├── container.puml / .svg    # 容器图
        ├── component-Core.puml / .svg
        └── class-Domain.puml / .svg
```

### 生成的架构图类型

1. **Context Diagram（系统上下文图）** - 展示系统与外部用户/系统的关系
2. **Container Diagram（容器图）** - 展示前端/后端/数据库等容器划分
3. **Component Diagram（组件图）** - 展示核心模块内部组件
4. **Class Diagram（类图）** - 展示关键类的设计和关系

### 架构图长什么样？

在 `docs/architecture-overview.md` 中，你会看到类似这样的内容：

```markdown
### 2.1 Context 视图（系统上下文）
![Context Diagram](../assets/diagrams/TxInsight_Context.svg)

### 2.2 Container 视图（容器图）
![Container Diagram](../assets/diagrams/TxInsight_Container.svg)
```

SVG 图片可以直接在 VSCode、Markdown 编辑器或浏览器中打开查看。

![Context Diagram](./assets/Sequence.svg)

![Container Diagram](./assets/Context.svg)

---

## 依赖要求

### 必需依赖

| 依赖            | 用途           | 是否必需 |
| --------------- | -------------- | -------- |
| **Claude Code** | 运行技能的载体 | ✅ 必需   |

### 可选依赖（用于生成 SVG 图片）

| 依赖         | 用途                                | 安装命令       |
| ------------ | ----------------------------------- | -------------- |
| **PlantUML** | 将 `.puml` 源文件渲染为 `.svg` 图片 | 见下方安装指引 |

**没有 PlantUML 也能用吗？** 可以！技能会正常分析代码并生成 `.puml` 源文件（纯文本），你可以后续安装 PlantUML 再渲染为 SVG，或使用在线渲染工具。

---

## PlantUML 安装指引

### macOS

```bash
brew install plantuml
```

### Linux

```bash
sudo apt-get install plantuml
```

### Windows（推荐）

```powershell
# 使用 Scoop（推荐）
scoop install plantuml

# 或使用 Chocolatey
choco install plantuml
```

### Windows（手动安装）

1. 访问 https://plantuml.com/download 下载 `plantuml.jar`
2. 安装 Java：`winget install Oracle.JavaRuntime.8`
3. 运行：`java -jar plantuml.jar -tsvg <input.puml>`

---

## 在线渲染 PlantUML（无需安装）

如果不想本地安装 PlantUML，可以使用在线工具渲染 `.puml` 文件：

### 方法 1：PlantText（推荐）

1. 访问 https://www.planttext.com/
2. 复制 `.puml` 文件内容粘贴到编辑器
3. 自动预览 SVG/PNG 图片，可右键下载

**优点：** 免费、无需注册、支持导出 PNG/SVG

### 方法 2：PlantUML 在线服务器

1. 访问 https://www.plantuml.com/plantuml/
2. 粘贴 `.puml` 代码或使用 URL 参数直接渲染

**示例 URL 格式：**
```
https://www.plantuml.com/plantuml/img/<encoded-puml-code>
```

### 方法 3：VSCode 插件（本地预览）

1. 安装 "PlantUML" 插件（作者：jebbs）
2. 打开 `.puml` 文件
3. 按 `Alt+D` 预览图表

**优点：** 离线可用、实时预览、支持导出

---

## 如何触发使用

### 自动触发

当你表达以下意图时，技能会**自动激活**：

- "我想学习这个代码库"
- "这个系统是怎么工作的？"
- "帮我分析一下架构"
- "这个文件是做什么的？"
- "如何实现 X 功能？"
- "这个代码有 bug 吗？"
- "帮我画个架构图"
- "我不懂这个语言，能教我吗？"

### 手动触发

在 Claude Code 或 Claude.ai 中，直接输入：

```
/arch-xray
```

然后描述你的需求即可。

---

## 使用示例

### 示例 1：分析整个项目

```
帮我分析这个项目的架构，我想了解整体结构
```

**输出：**

- 生成 Context + Container 图
- 编写架构概览文档
- 识别技术栈和核心模块

### 示例 2：查看特定模块

```
分析一下 src/services 目录下的组件关系
```

**输出：**

- 生成 Component 图
- 解释文件互动关系
- 提供调用链分析

### 示例 3：代码审查

```
这段代码有什么潜在问题吗？
```

**输出：**

- 指出 bug 风险和安全漏洞
- 提供改进建议
- 给出最佳实践

### 示例 4：学习新技术

```
这个项目用了 TypeScript，我不太懂，能教我吗？

**输出：**
- TypeScript 基础语法教程
- 结合项目实际代码示例
- 解释为什么这样设计

---

## 常见问题解决

### Q1: SVG 图片无法显示

**症状：** Markdown 中图片位置显示为空白或 broken image

**解决方法：**
1. 检查图片路径是否正确（应该是 `../assets/diagrams/xxx.svg`）
2. 确认 `.svg` 文件确实存在于 `xray/assets/diagrams/` 目录
3. 在 VSCode 中右键图片 → "Open Image" 验证文件是否损坏

### Q2: PlantUML 未安装

**症状：** 看到警告 "PlantUML 未安装，将只生成 .puml 源文件"

**解决方法：**
- 按照上方 "PlantUML 安装指引" 安装即可
- 安装后重新运行技能，或手动运行渲染命令：
  ```bash
  # macOS/Linux
  plantuml -tsvg xray/assets/diagrams/*.puml

  # Windows PowerShell
  plantuml -tsvg xray/assets/diagrams/*.puml
```

### Q3: Windows 上无法运行脚本

**症状：** 运行 `./scripts/generate-c4-diagram.sh` 报错

**解决方法：**

- 使用 PowerShell 版本：
  ```powershell
  .\scripts\generate-c4-diagram.ps1 -type context
  ```

### Q4: 技能没有自动触发

**症状：** 描述了需求但技能没有激活

**解决方法：**

- 尝试更明确地表达意图，使用上述触发关键词
- 手动输入 `/arch-xray` 强制触发
- 检查技能名称是否正确（是 `arch-xray` 不是 `arch-xary`）

### Q5: 分析卡住或超时

**症状：** 技能运行很长时间没有输出

**解决方法：**

- 大型项目可以分模块分析，例如："只分析 src/core 目录"
- 关闭不必要的后台进程
- 重启 Claude Code 会话

---

## 技术特点

| 特点         | 说明                                   |
| ------------ | -------------------------------------- |
| **离线兼容** | 使用标准 PlantUML 语法，无需远程库依赖 |
| **跨平台**   | 支持 macOS、Linux、Windows             |
| **多语言**   | 可分析任何编程语言项目                 |
| **C4 标准**  | 遵循国际通用的架构可视化方法           |
| **相对路径** | 输出文档可在任意位置打开查看           |

---

## 更多信息

- 技能定义文件：`SKILL.md`
- 脚本使用说明：`scripts/generate-c4-diagram.sh` / `scripts/generate-c4-diagram.ps1`
- 输出结构详解：`OUTPUT_STRUCTURE.md`

---

*arch-xray - 让架构一目了然*
