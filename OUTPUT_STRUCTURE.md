# arch-xray 输出目录结构

## 目录结构

```
xray/
├── docs/                          # 文档目录 - 用户直接查看
│   ├── architecture-overview.md   # 架构概览（包含 SVG 架构图）
│   ├── component-details.md       # 组件详情
│   ├── data-flow.md               # 数据流分析
│   ├── project-structure.md       # 项目结构说明
│   ├── code-review.md             # 代码审查报告
│   ├── language-tutorials/        # 编程语言教程
│   │   ├── java-basics.md
│   │   ├── typescript-basics.md
│   │   └── ...
│   └── guides/                    # 开发引导文档
│       └── feature-*.md
└── assets/                        # 资源目录 - 图片和源文件
    ├── diagrams/                  # PlantUML 源文件和 SVG 图片
    │   ├── context.puml           # 系统上下文图（源文件）
    │   ├── context.svg            # 系统上下文图（渲染后）
    │   ├── container.puml         # 容器图（源文件）
    │   ├── container.svg          # 容器图（渲染后）
    │   ├── component-*.puml       # 组件图（源文件）
    │   └── component-*.svg        # 组件图（渲染后）
    └── templates/                 # 可选的模板文件
```

## 路径规范

### 文档中引用图片的路径

在 `xray/docs/*.md` 中引用 SVG 图片时，使用相对路径：

```markdown
![Context Diagram](../assets/diagrams/TxInsight_Context.svg)
```

**路径计算：**
- 文档位置：`xray/docs/architecture-overview.md`
- 图片位置：`xray/assets/diagrams/TxInsight_Context.svg`
- 相对路径：`../assets/diagrams/文件名.svg`

## 使用方式

### 查看文档
直接在 `xray/docs/` 目录中打开 Markdown 文件，图片会自动加载。

### 在 VSCode 中预览
1. 安装 Markdown Preview Enhanced 插件
2. 右键点击任意 `.md` 文件
3. 选择 "Open Preview to the Side"

### 在浏览器中查看
```bash
# macOS
open xray/docs/architecture-overview.md

# 或使用 VSCode
code xray/docs/architecture-overview.md
```

## 命名规范

### 文件命名
- 文档：`kebab-case.md`（如 `architecture-overview.md`）
- 图表：`{项目名}_{图类型}.svg`（如 `TxInsight_Context.svg`）
- 教程：`{语言}-{级别}.md`（如 `java-basics.md`）
- 引导：`feature-{功能名}.md`（如 `feature-add-auth.md`）

### 图表类型
- `Context` - 系统上下文图
- `Container` - 容器图
- `Component` - 组件图
- `Sequence` - 序列图
- `Class` - 类图
