#!/bin/bash
# collect-structure.sh
# 收集项目结构信息的脚本
# 输出项目的目录树、文件类型统计、依赖关系等信息

set -e

# 默认配置
BASE_DIR="."
OUTPUT_FILE="./output/project-structure.txt"
EXCLUDE_PATTERN="node_modules|.git|.venv|dist|build|target|vendor"
MAX_DEPTH=3

# 帮助信息
usage() {
    cat << EOF
用法：$0 [--base-dir <dir>] [--output <file>] [--exclude <pattern>] [--depth <num>]

选项:
  -b, --base-dir     项目根目录 (默认：当前目录)
  -o, --output       输出文件路径 (默认：./output/project-structure.txt)
  -e, --exclude      排除的目录模式 (默认：node_modules|.git|.venv|dist|build|target|vendor)
  -d, --depth        扫描深度 (默认：3)
  -h, --help         显示帮助信息

示例:
  $0 --base-dir /path/to/project --output structure.txt
  $0 --exclude "node_modules|.git" --depth 5
EOF
    exit 1
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--base-dir)
            BASE_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -e|--exclude)
            EXCLUDE_PATTERN="$2"
            shift 2
            ;;
        -d|--depth)
            MAX_DEPTH="$2"
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

# 创建输出目录
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "=== 项目结构收集工具 ==="
echo "项目根目录：$BASE_DIR"
echo "输出文件：$OUTPUT_FILE"
echo "排除模式：$EXCLUDE_PATTERN"
echo "扫描深度：$MAX_DEPTH"
echo ""

# 开始收集
{
    echo "# 项目结构分析报告"
    echo ""
    echo "**生成时间:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**项目根目录:** $BASE_DIR"
    echo ""

    # 1. 目录树
    echo "## 1. 目录树结构"
    echo ""
    echo '```'
    if command -v tree &> /dev/null; then
        tree -L "$MAX_DEPTH" -I "$EXCLUDE_PATTERN" "$BASE_DIR"
    else
        # 如果 tree 不可用，使用 find 模拟
        find "$BASE_DIR" -maxdepth "$MAX_DEPTH" -type d \
            ! -path "*/\.*" \
            ! -path "*/node_modules/*" \
            ! -path "*/.venv/*" \
            ! -path "*/dist/*" \
            ! -path "*/build/*" \
            ! -path "*/target/*" \
            ! -path "*/vendor/*" \
            | sort | sed 's|[^/]*/|  |g'
    fi
    echo '```'
    echo ""

    # 2. 文件类型统计
    echo "## 2. 文件类型统计"
    echo ""
    echo '| 文件类型 | 数量 | 总大小 |'
    echo '|----------|------|--------|'

    # 统计各种文件类型
    for ext in java js ts py go rs vue json yaml yml xml sql sh md txt csv; do
        count=$(find "$BASE_DIR" -type f -name "*.$ext" \
            ! -path "*/node_modules/*" \
            ! -path "*/.venv/*" \
            ! -path "*/dist/*" \
            ! -path "*/build/*" \
            2>/dev/null | wc -l | tr -d ' ')
        if [[ "$count" -gt 0 ]]; then
            size=$(find "$BASE_DIR" -type f -name "*.$ext" \
                ! -path "*/node_modules/*" \
                ! -path "*/.venv/*" \
                ! -path "*/dist/*" \
                ! -path "*/build/*" \
                -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1)
            echo "| .$ext | $count | $size |"
        fi
    done
    echo ""

    # 3. 项目配置文件
    echo "## 3. 项目配置文件"
    echo ""
    echo '```'
    for config in "package.json" "pom.xml" "build.gradle" "requirements.txt" \
                  "Cargo.toml" "go.mod" "pyproject.toml" "tsconfig.json" \
                  ".gitignore" "Dockerfile" "docker-compose.yml" "Makefile"; do
        if [[ -f "$BASE_DIR/$config" ]]; then
            echo "找到：$config"
        fi
    done
    echo '```'
    echo ""

    # 4. 源代码目录
    echo "## 4. 源代码目录"
    echo ""
    echo '```'
    for src_dir in "src" "app" "lib" "components" "views" "api" "models" "controllers" "services"; do
        if [[ -d "$BASE_DIR/$src_dir" ]]; then
            echo "源代码目录：$src_dir"
            find "$BASE_DIR/$src_dir" -maxdepth 2 -type d 2>/dev/null | head -10
            echo ""
        fi
    done
    echo '```'
    echo ""

    # 5. 依赖关系分析
    echo "## 5. 依赖关系分析"
    echo ""

    # JavaScript/TypeScript 依赖
    if [[ -f "$BASE_DIR/package.json" ]]; then
        echo "### JavaScript/TypeScript 依赖"
        echo '```json'
        cat "$BASE_DIR/package.json" | head -50
        echo '```'
        echo ""
    fi

    # Java 依赖
    if [[ -f "$BASE_DIR/pom.xml" ]]; then
        echo "### Java 依赖 (Maven)"
        echo '```xml'
        grep -A 5 "<dependency>" "$BASE_DIR/pom.xml" | head -50
        echo '```'
        echo ""
    fi

    if [[ -f "$BASE_DIR/build.gradle" ]]; then
        echo "### Java 依赖 (Gradle)"
        grep "implementation\\|compileOnly\\|runtimeOnly" "$BASE_DIR/build.gradle" | head -30
        echo ""
    fi

    # Python 依赖
    if [[ -f "$BASE_DIR/requirements.txt" ]]; then
        echo "### Python 依赖"
        echo '```'
        cat "$BASE_DIR/requirements.txt"
        echo '```'
        echo ""
    fi

    # 6. 入口文件
    echo "## 6. 入口文件"
    echo ""
    for entry in "main.js" "main.ts" "main.py" "Main.java" "App.vue" "index.js" "index.tsx"; do
        found=$(find "$BASE_DIR" -name "$entry" -type f \
            ! -path "*/node_modules/*" \
            ! -path "*/.venv/*" \
            ! -path "*/dist/*" \
            2>/dev/null | head -5)
        if [[ -n "$found" ]]; then
            echo "**$entry:**"
            echo '```'
            echo "$found"
            echo '```'
            echo ""
        fi
    done

    # 7. 数据库相关文件
    echo "## 7. 数据库相关文件"
    echo ""
    echo '```'
    find "$BASE_DIR" -name "*.sql" -type f \
        ! -path "*/node_modules/*" \
        ! -path "*/.venv/*" \
        2>/dev/null | head -10
    echo '```'
    echo ""

    # 8. API 相关文件
    echo "## 8. API 相关文件"
    echo ""
    echo '```'
    find "$BASE_DIR" -type f \( -name "*controller*" -o -name "*handler*" -o -name "*route*" -o -name "*api*" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/.venv/*" \
        ! -path "*/dist/*" \
        2>/dev/null | head -20
    echo '```'
    echo ""

    # 9. 测试文件
    echo "## 9. 测试文件"
    echo ""
    echo '```'
    find "$BASE_DIR" -type f \( -name "*test*" -o -name "*spec*" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/.venv/*" \
        ! -path "*/dist/*" \
        2>/dev/null | head -20
    echo '```'
    echo ""

} > "$OUTPUT_FILE"

echo "项目结构分析完成！"
echo "输出文件：$OUTPUT_FILE"
echo ""
echo "文件预览:"
head -50 "$OUTPUT_FILE"
