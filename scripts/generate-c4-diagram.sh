#!/bin/bash
# generate-c4-diagram.sh
# 生成 C4 PlantUML 架构图的脚本
# 依赖：PlantUML

# 检测操作系统，Windows 用户请使用 PowerShell 版本
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$(uname)" == "MINGW"* ]]; then
    echo "============================================"
    echo "  检测到 Windows 系统"
    echo "============================================"
    echo ""
    echo "请使用 PowerShell 版本脚本:"
    echo "  .\scripts\generate-c4-diagram.ps1 -type <context|container|component|class>"
    echo ""
    echo "示例:"
    echo "  .\scripts\generate-c4-diagram.ps1 -type context"
    echo "  .\scripts\generate-c4-diagram.ps1 -type container -output ./xray/assets"
    echo ""
    echo "============================================"
    echo ""
    exit 1
fi

set -e

# 默认配置
OUTPUT_DIR="./xray/assets/diagrams"
DIAGRAM_TYPE=""
CONFIG_FILE=""
BASE_DIR="."

# 帮助信息
usage() {
    cat << EOF
用法：$0 --type <diagram_type> [--output <output_dir>] [--config <config_file>]

选项:
  -t, --type      图表类型：context, container, component, class (必需)
  -o, --output    输出目录 (默认：./xray/assets/diagrams)
  -c, --config    可选的配置文件路径
  -b, --base-dir  项目根目录 (默认：当前目录)
  -h, --help      显示帮助信息

示例:
  $0 --type context --output ./xray/assets/diagrams
  $0 --type container --config custom.conf
  $0 --type component -o ./xray/assets
EOF
    exit 1
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            DIAGRAM_TYPE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -b|--base-dir)
            BASE_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "未知选项：$1"
            usage
            ;;
    esac
done

# 验证必需参数
if [[ -z "$DIAGRAM_TYPE" ]]; then
    echo "错误：必须指定 --type 参数"
    usage
fi

# 验证 diagram 类型
case $DIAGRAM_TYPE in
    context|container|component|class)
        ;;
    *)
        echo "错误：无效的图表类型 '$DIAGRAM_TYPE'"
        echo "有效类型：context, container, component, class"
        exit 1
        ;;
esac

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检查 PlantUML 是否可用
check_plantuml() {
    if command -v plantuml &> /dev/null; then
        PLANTUML_CMD="plantuml"
    elif [ -f "/usr/local/bin/plantuml" ]; then
        PLANTUML_CMD="/usr/local/bin/plantuml"
    elif [ -f "$HOME/plantuml.jar" ]; then
        # 需要 Java 运行 JAR
        if command -v java &> /dev/null; then
            PLANTUML_CMD="java -jar $HOME/plantuml.jar"
        else
            echo "警告：发现 PlantUML JAR 但未安装 Java"
            PLANTUML_CMD=""
        fi
    else
        echo "警告：PlantUML 未安装，将只生成 .puml 源文件"
        echo ""
        echo "安装方法:"
        echo "  macOS:   brew install plantuml"
        echo "  Linux:   sudo apt-get install plantuml"
        echo "  Windows: 使用 PowerShell 脚本或 scoop install plantuml"
        echo "  或下载 JAR: https://plantuml.com/download (需要 Java)"
        echo ""
        echo "在线渲染（无需安装）:"
        echo "  1. PlantText: https://www.planttext.com/"
        echo "  2. PlantUML Server: https://www.plantuml.com/plantuml/"
        echo "  3. VSCode 插件：安装 'PlantUML' 插件 (Alt+D 预览)"
        echo ""
        PLANTUML_CMD=""
    fi
}

# 生成 Context Diagram (使用本地宏，不依赖远程库)
generate_context() {
    local output_file="$OUTPUT_DIR/context.puml"
    echo "生成 Context Diagram..."

    cat > "$output_file" << 'EOF'
@startuml Context
title 系统上下文图

skinparam backgroundColor #FFFFFF
skinparam shadowing false

' 人员
actor "用户" as user
actor "管理员" as admin

' 系统边界
package "系统名称" as system {
  component "Web 应用" as webApp
  component "API 服务" as api
  database "数据库" as db
}

' 外部系统
component "外部服务" as external

' 关系
user --> webApp : 使用 (HTTPS)
admin --> webApp : 管理 (HTTPS)
webApp --> api : 调用 (REST API)
api --> db : 读写 (JDBC)
api --> external : 集成 (API)

legend right
  | ================ |
  | Actor: 人员 |
  | Component: 应用/服务 |
  | Database: 数据库 |
  | ================ |
endlegend

@enduml
EOF

    echo "已生成：$output_file"
    render_diagram "$output_file"
}

# 生成 Container Diagram
generate_container() {
    local output_file="$OUTPUT_DIR/container.puml"
    echo "生成 Container Diagram..."

    cat > "$output_file" << 'EOF'
@startuml Container
title 容器图 - 系统架构详解

skinparam backgroundColor #FFFFFF
skinparam shadowing false

' 人员
actor "用户" as user

' 前端应用
package "前端应用" as frontend {
  component "Web 应用" as webApp
}

' 后端服务
package "API 服务" as backend {
  component "Controller" as controller
  component "Service" as service
  component "Repository" as repository
}

' 数据库
database "数据库" as db
component "缓存" as cache

' 关系
user --> webApp : 使用 (HTTPS)
webApp --> controller : 调用 (REST)
controller --> service : 调用
service --> repository : 调用
repository --> db : 读写 (SQL)
service --> cache : 读写 (Redis)

legend right
  | ================ |
  | Actor: 人员 |
  | Component: 应用/服务 |
  | Database: 数据库 |
  | ================ |
endlegend

@enduml
EOF

    echo "已生成：$output_file"
    render_diagram "$output_file"
}

# 生成 Component Diagram
generate_component() {
    local component_name="${2:-Core}"
    local output_file="$OUTPUT_DIR/component-${component_name}.puml"
    echo "生成 Component Diagram: $component_name..."

    cat > "$output_file" << EOF
@startuml Component-${component_name}
title 组件图 - ${component_name} 模块

skinparam backgroundColor #FFFFFF
skinparam shadowing false

package "${component_name} 容器" as container {
  component "组件 1" as component1
  component "组件 2" as component2
  component "组件 3" as component3
  database "数据库" as database
}

component1 --> component2 : 调用
component2 --> component3 : 发布事件
component3 --> database : 持久化

legend right
  | ================ |
  | Component: 组件 |
  | Database: 数据库 |
  | ================ |
endlegend

@enduml
EOF

    echo "已生成：$output_file"
    render_diagram "$output_file"
}

# 生成 Class Diagram
generate_class() {
    local class_name="${2:-Domain}"
    local output_file="$OUTPUT_DIR/class-${class_name}.puml"
    echo "生成 Class Diagram: $class_name..."

    cat > "$output_file" << EOF
@startuml Class-${class_name}
title 类图 - ${class_name}

skinparam backgroundColor #FFFFFF
skinparam shadowing false

class User {
    -id: Long
    -username: String
    -email: String
    +login()
    +logout()
}

class Service {
    -repository: Repository
    +processData(): Result
    +validate(): Boolean
}

class Repository {
    -entityManager: EntityManager
    +findByID(id): Entity
    +save(entity): void
}

User --> Service : 使用
Service --> Repository : 依赖
Repository ..> User : 管理

@enduml
EOF

    echo "已生成：$output_file"
    render_diagram "$output_file"
}

# 渲染 PlantUML 为 SVG
render_diagram() {
    local puml_file="$1"

    if [[ -z "$PLANTUML_CMD" ]]; then
        echo "跳过渲染：PlantUML 未安装"
        return
    fi

    echo "正在渲染：$puml_file"

    # PlantUML 默认输出到同目录，需要移动到输出目录
    $PLANTUML_CMD -tsvg "$puml_file" -o "$OUTPUT_DIR"

    echo "已生成 SVG: ${puml_file%.puml}.svg"
}

# 分析项目结构并生成对应的图表
analyze_and_generate() {
    echo "正在分析项目结构..."

    # 识别项目类型
    if [[ -f "$BASE_DIR/package.json" ]]; then
        echo "检测到：Node.js/JavaScript 项目"
    fi

    if [[ -f "$BASE_DIR/pom.xml" ]] || [[ -f "$BASE_DIR/build.gradle" ]]; then
        echo "检测到：Java/Maven 或 Gradle 项目"
    fi

    if [[ -f "$BASE_DIR/requirements.txt" ]] || [[ -f "$BASE_DIR/setup.py" ]]; then
        echo "检测到：Python 项目"
    fi

    if [[ -d "$BASE_DIR/.git" ]]; then
        echo "检测到：Git 仓库"
    fi

    # 扫描主要目录
    echo ""
    echo "主要目录结构:"
    find "$BASE_DIR" -maxdepth 2 -type d -not -path "*/\.*" -not -path "*/node_modules/*" -not -path "*/.venv/*" | head -20
}

# 主函数
main() {
    echo "=== C4 PlantUML 图表生成器 ==="
    echo "图表类型：$DIAGRAM_TYPE"
    echo "输出目录：$OUTPUT_DIR"
    echo ""

    check_plantuml

    case $DIAGRAM_TYPE in
        context)
            generate_context
            ;;
        container)
            generate_container
            ;;
        component)
            generate_component "$@"
            ;;
        class)
            generate_class "$@"
            ;;
    esac

    echo ""
    echo "=== 生成完成 ==="
    echo "输出文件位置：$OUTPUT_DIR"
    ls -la "$OUTPUT_DIR"/*.puml "$OUTPUT_DIR"/*.svg 2>/dev/null || true
}

main "$@"
