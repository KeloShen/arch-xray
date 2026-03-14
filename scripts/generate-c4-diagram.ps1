# generate-c4-diagram.ps1
# 生成 C4 PlantUML 架构图的 PowerShell 脚本
# 依赖：PlantUML

param(
    [Parameter(Mandatory=$true)]
    [string]$type,

    [string]$output = "./xray/assets/diagrams",

    [string]$config = "",

    [string]$baseDir = "."
)

# 帮助信息
function Show-Usage {
    Write-Host @"
用法：$($MyInvocation.MyCommand.Name) -type <diagram_type> [-output <output_dir>] [-config <config_file>]

选项:
  -type       图表类型：context, container, component, class (必需)
  -output     输出目录 (默认：./xray/assets/diagrams)
  -config     可选的配置文件路径
  -baseDir    项目根目录 (默认：当前目录)
  -help       显示帮助信息

示例:
  .\$($MyInvocation.MyCommand.Name) -type context
  .\$($MyInvocation.MyCommand.Name) -type container -output ./xray/assets
"@
    exit 1
}

# 验证 diagram 类型
$validTypes = @("context", "container", "component", "class")
if ($type -notin $validTypes) {
    Write-Host "错误：无效的图表类型 '$type'"
    Write-Host "有效类型：context, container, component, class"
    exit 1
}

# 创建输出目录
if (!(Test-Path $output)) {
    New-Item -ItemType Directory -Force -Path $output | Out-Null
}

# 检查 PlantUML 是否可用
function Test-PlantUML {
    # 方法 1: 检查 plantuml 命令
    $plantumlCmd = Get-Command plantuml -ErrorAction SilentlyContinue
    if ($plantumlCmd) {
        return @{ Found = $true; Command = "plantuml" }
    }

    # 方法 2: 检查常见安装路径
    $commonPaths = @(
        "C:\Program Files\PlantUML\plantuml.jar",
        "C:\Program Files (x86)\PlantUML\plantuml.jar",
        "$env:LOCALAPPDATA\plantuml.jar",
        "$env:USERPROFILE\plantuml.jar"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return @{ Found = $true; Command = "java -jar $path"; JarPath = $path }
        }
    }

    return @{ Found = $false }
}

# 显示安装指引
function Show-InstallGuide {
    $os = Get-CimInstance Win32_OperatingSystem
    $osName = $os.Caption

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "  PlantUML 未安装" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "请选择以下任一方式安装 PlantUML："
    Write-Host ""
    Write-Host "【方法 1】使用 Scoop (推荐):" -ForegroundColor Cyan
    Write-Host "  scoop install plantuml"
    Write-Host ""
    Write-Host "【方法 2】使用 Chocolatey:" -ForegroundColor Cyan
    Write-Host "  choco install plantuml"
    Write-Host ""
    Write-Host "【方法 3】手动下载 JAR:" -ForegroundColor Cyan
    Write-Host "  1. 访问 https://plantuml.com/download"
    Write-Host "  2. 下载 plantuml.jar"
    Write-Host "  3. 安装 Java: winget install Oracle.JavaRuntime.8"
    Write-Host "  4. 运行：java -jar plantuml.jar -tsvg <input.puml>"
    Write-Host ""
    Write-Host "【方法 4】使用 WSL:" -ForegroundColor Cyan
    Write-Host "  1. 安装 WSL: wsl --install"
    Write-Host "  2. 在 WSL 中运行：sudo apt-get install plantuml"
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host ""

    # 检查包管理器
    $scoop = Get-Command scoop -ErrorAction SilentlyContinue
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    $winget = Get-Command winget -ErrorAction SilentlyContinue

    if ($scoop) {
        Write-Host "检测到 Scoop，建议运行：scoop install plantuml" -ForegroundColor Green
    } elseif ($choco) {
        Write-Host "检测到 Chocolatey，建议运行：choco install plantuml" -ForegroundColor Green
    } elseif ($winget) {
        Write-Host "检测到 winget，可先安装 Scoop 或 Chocolatey" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "注意：当前脚本将只生成 .puml 源文件，无法渲染为 SVG 图片。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "【在线渲染】（无需安装）" -ForegroundColor Cyan
    Write-Host "  1. PlantText: https://www.planttext.com/"
    Write-Host "  2. PlantUML Server: https://www.plantuml.com/plantuml/"
    Write-Host "  3. VSCode 插件：安装 'PlantUML' 插件 (Alt+D 预览)"
    Write-Host ""
}

# 生成 Context Diagram
function Generate-Context {
    $outputFile = Join-Path $output "context.puml"
    Write-Host "生成 Context Diagram..." -ForegroundColor Cyan

    $content = @'
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
'@

    Set-Content -Path $outputFile -Value $content -Encoding UTF8
    Write-Host "已生成：$outputFile" -ForegroundColor Green

    return $outputFile
}

# 生成 Container Diagram
function Generate-Container {
    $outputFile = Join-Path $output "container.puml"
    Write-Host "生成 Container Diagram..." -ForegroundColor Cyan

    $content = @'
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
'@

    Set-Content -Path $outputFile -Value $content -Encoding UTF8
    Write-Host "已生成：$outputFile" -ForegroundColor Green

    return $outputFile
}

# 生成 Component Diagram
function Generate-Component {
    param([string]$componentName = "Core")

    $outputFile = Join-Path $output "component-$componentName.puml"
    Write-Host "生成 Component Diagram: $componentName..." -ForegroundColor Cyan

    $content = @"
@startuml Component-$componentName
title 组件图 - $componentName 模块

skinparam backgroundColor #FFFFFF
skinparam shadowing false

package "$componentName 容器" as container {
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
"@

    Set-Content -Path $outputFile -Value $content -Encoding UTF8
    Write-Host "已生成：$outputFile" -ForegroundColor Green

    return $outputFile
}

# 生成 Class Diagram
function Generate-Class {
    param([string]$className = "Domain")

    $outputFile = Join-Path $output "class-$className.puml"
    Write-Host "生成 Class Diagram: $className..." -ForegroundColor Cyan

    $content = @"
@startuml Class-$className
title 类图 - $className

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
"@

    Set-Content -Path $outputFile -Value $content -Encoding UTF8
    Write-Host "已生成：$outputFile" -ForegroundColor Green

    return $outputFile
}

# 渲染 PlantUML 为 SVG
function Render-Diagram {
    param([string]$pumlFile, $plantumlInfo)

    if (!$plantumlInfo.Found) {
        Write-Host "跳过渲染：PlantUML 未安装" -ForegroundColor Yellow
        return
    }

    Write-Host "正在渲染：$pumlFile" -ForegroundColor Cyan

    # 解析命令
    $parts = $plantumlInfo.Command -split ' '
    $cmd = $parts[0]
    $args = $parts[1..($parts.Length-1)] + @("-tsvg", $pumlFile, "-o", $output)

    try {
        & $cmd @args
        $svgFile = $pumlFile -replace '\.puml$', '.svg'
        Write-Host "已生成 SVG: $svgFile" -ForegroundColor Green
    }
    catch {
        Write-Host "渲染失败：$_" -ForegroundColor Red
    }
}

# 主函数
function Main {
    Write-Host "=== C4 PlantUML 图表生成器 (PowerShell) ===" -ForegroundColor Cyan
    Write-Host "图表类型：$type"
    Write-Host "输出目录：$output"
    Write-Host ""

    # 检查 PlantUML
    $plantumlInfo = Test-PlantUML

    if (!$plantumlInfo.Found) {
        Show-InstallGuide
    }

    # 生成对应的图表
    $pumlFile = ""
    switch ($type) {
        "context" { $pumlFile = Generate-Context }
        "container" { $pumlFile = Generate-Container }
        "component" { $pumlFile = Generate-Component }
        "class" { $pumlFile = Generate-Class }
    }

    # 渲染为 SVG
    if ($pumlFile) {
        Render-Diagram -pumlFile $pumlFile -plantumlInfo $plantumlInfo
    }

    Write-Host ""
    Write-Host "=== 生成完成 ===" -ForegroundColor Green
    Write-Host "输出文件位置：$output"

    # 列出生成的文件
    Get-ChildItem -Path $output -Filter "*.puml" | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor Gray
    }
    Get-ChildItem -Path $output -Filter "*.svg" | ForEach-Object {
        Write-Host "  $($_.Name) (SVG)" -ForegroundColor Green
    }
}

# 处理 help 参数
if ($type -eq "help" -or $type -eq "-help" -or $type -eq "--help") {
    Show-Usage
}

Main
