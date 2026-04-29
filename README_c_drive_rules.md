# C 盘治理规则说明（C:\Dev）

## 1. 定位

`C:\Dev` 是本机的治理层、稳定层、兼容层，使用 NTFS。它负责承载：

- 手动管理的工具链
- MCP 服务端、Agentic Toolkit 与配置模板
- 共享资源
- 机器级脚本与文档
- Dev Drive 虚拟磁盘文件
- 历史兼容内容

它不负责承载高频构建输出、大体量缓存和活跃工程工作集。

---

## 2. 一级目录含义

### `C:\Dev\toolchains`

手动管理的工具链本体目录。

适合放：

- Flutter SDK
- vcpkg
- Qt
- Qt legacy
- Android SDK（若手动管理）
- Miniconda

### `C:\Dev\mcp`

MCP / Agent 集成层目录。

适合放：

- MCP 服务端本体
- MATLAB MCP Core Server
- MATLAB Agentic Toolkit
- Codex 项目级 MCP 配置模板
- MCP 安装与迁移文档
- MCP 调试日志

推荐结构：

```text
C:\Dev\mcp\
  servers\
    matlab-mcp-core-server\
      bin\
        matlab-mcp-core-server.exe
      releases\
  toolkits\
    matlab-agentic-toolkit\
  configs\
    codex\
      templates\
  docs\
  logs\
```

其中：

servers：放 MCP 服务端程序。
toolkits：放 MATLAB Agentic Toolkit 等辅助工具包。
configs\codex\templates：放可复制到项目中的 Codex 配置模板。
docs：放 MCP 安装、迁移和故障排查说明。
logs：放 MCP 运行与调试日志。

### `C:\Dev\resources`

共享资源与公共资产目录。

适合放：

STK 卫星数据
地形 / 影像 / 模板
通用参数模板
多项目复用数据包

### `C:\Dev\scripts`

机器级脚本目录。

适合放：

环境初始化脚本
目录创建脚本
备份脚本
挂载脚本
常用 PowerShell 脚本

### `C:\Dev\docs`

机器级治理文档目录。

适合放：

路径规范说明
环境部署说明
迁移记录
故障排查说明

### `C:\Dev\volumes`

虚拟磁盘文件目录。

适合放：

Dev Drive 的 .vhdx

推荐示例：

C:\Dev\volumes\dev-main.vhdx

### `C:\Dev\backups`

轻量备份与配置导出目录。

适合放：

环境变量导出
配置备份
小型关键文件备份

### `C:\Dev\legacy`

历史兼容目录，仅限 NTFS 的旧工程与旧资源保留区。

适合放：

古早 Qt 项目
依赖旧编译器的工程
必须使用 NTFS 的旧脚本链路

## 3. MCP 配置规则

MCP 服务端可以统一放在 C:\Dev\mcp，但 MATLAB MCP 不建议写入 Codex 全局配置：

%USERPROFILE%\.codex\config.toml

推荐做法：

在 C:\Dev\mcp 中统一管理 MCP 服务端和模板。
全局 Codex 配置只保留通用设置，不放 [mcp_servers.matlab]。
哪个项目需要 MATLAB MCP，就在哪个项目仓库内放：
<repo>\.codex\config.toml

项目级 MATLAB MCP 配置模板可以保存在：

C:\Dev\mcp\configs\codex\templates\matlab-project.config.toml

模板内容示例：

[mcp_servers.matlab]
command = "C:\\Dev\\mcp\\servers\\matlab-mcp-core-server\\bin\\matlab-mcp-core-server.exe"
args = [
  "--matlab-root=C:\\Program Files\\MATLAB\\R2025b",
  "--matlab-display-mode=nodesktop",
  "--matlab-session-mode=new",
  "--initialize-matlab-on-startup=false"
]
startup_timeout_sec = 60
tool_timeout_sec = 600
enabled_tools = [
  "detect_matlab_toolboxes",
  "check_matlab_code",
  "evaluate_matlab_code",
  "run_matlab_file",
  "run_matlab_test_file"
]

博士论文项目中的实际配置位置示例：

V:\src\thesis-code\.codex\config.toml

## 4. 不应放在 C:\Dev 的内容

下列内容不应作为常规做法放在 C:\Dev：

活跃项目源码（应优先放到 V:\src）
构建输出（应放到 V:\build）
大量缓存（应放到 V:\cache）
大型实验数据（应放到 V:\datasets）
一次性临时文件（应放到 V:\scratch）
项目专属 .codex\config.toml（应放到对应项目仓库内）

## 5. 典型目录示例
C:\Dev\
  toolchains\
    flutter\
    vcpkg\
    qt\
    qt-legacy\
    android-sdk\
    miniconda3\
  mcp\
    servers\
      matlab-mcp-core-server\
        bin\
          matlab-mcp-core-server.exe
        releases\
    toolkits\
      matlab-agentic-toolkit\
    configs\
      codex\
        templates\
    docs\
    logs\
  resources\
    stk\
      satellites\
      terrain\
      imagery\
      templates\
    common-data\
  scripts\
  docs\
  volumes\
    dev-main.vhdx
  backups\
  legacy\
    src\
    build\
    resources\

## 6. 规则总结
C:\Dev 管稳定、兼容、共享、长期维护的内容。
工具链统一放在 C:\Dev\toolchains。
MCP 服务端、Agentic Toolkit 和配置模板统一放在 C:\Dev\mcp。
共享资源统一放在 C:\Dev\resources。
老旧兼容工程优先保留在 C:\Dev\legacy。
不把 C:\Dev 当作活跃工程、构建输出、缓存盘或大型实验数据盘使用。
不把 MATLAB MCP 的项目启用配置写死在全局 Codex 配置中。