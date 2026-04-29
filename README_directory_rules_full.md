# Windows 开发机目录治理总规则（C:\Dev + V:\）

## 1. 总体设计思想

本机目录治理采用双层结构：

- `C:\Dev`：治理层 / 稳定层 / NTFS
- `V:\`：工作层 / 高 IO 层 / Dev Drive（ReFS）

这两层的职责不同：

- `C:\Dev` 负责保存需要长期维护、路径稳定、兼容性优先的内容。
- `V:\` 负责保存活跃工程、构建输出、缓存、大型数据与临时工作内容。

本方案的核心目标是：

1. 工具链与工程分离。
2. 共享资源与项目私有资源分离。
3. 稳定层与高吞吐工作层分离。
4. 老旧兼容内容与现代开发内容分离。
5. MCP 服务端本体与项目级 MCP 启用配置分离。

---

## 2. 一级目录总览

### C:\Dev

- `toolchains`：手动管理的工具链本体
- `mcp`：MCP 服务端、Agentic Toolkit、配置模板与日志
- `resources`：共享资源与公共资产
- `scripts`：机器级脚本
- `docs`：机器级治理文档
- `volumes`：虚拟磁盘文件（如 Dev Drive 的 `.vhdx`）
- `backups`：轻量备份与配置导出
- `legacy`：仅限 NTFS 的历史兼容区

### V:\

- `src`：活跃源码工程
- `build`：构建输出与中间产物
- `cache`：可清理缓存
- `datasets`：大型项目数据与实验数据
- `scratch`：一次性临时工作区

---

## 3. 归类规则

### 3.1 工具本体

凡是 SDK、编译器、包管理器、运行时、手动安装工具链，都放到 `C:\Dev\toolchains`。

例如：

- Flutter SDK
- vcpkg
- Qt
- Qt legacy
- Android SDK（若手动管理）
- Miniconda

### 3.2 MCP / Agent 集成层

凡是 MCP 服务端、Agentic Toolkit、MCP 配置模板、MCP 使用说明和 MCP 运行日志，都统一放到 `C:\Dev\mcp`。

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

servers：MCP 服务端本体。
toolkits：如 MATLAB Agentic Toolkit 这类 agent 辅助工具包。
configs\codex\templates：Codex 项目级配置模板。
docs：MCP 安装、迁移、故障排查说明。
logs：MCP 相关调试日志。

MATLAB MCP 的推荐安装位置：

C:\Dev\mcp\servers\matlab-mcp-core-server\bin\matlab-mcp-core-server.exe

MATLAB Agentic Toolkit 的推荐位置：

C:\Dev\mcp\toolkits\matlab-agentic-toolkit

### 3.3 MCP 配置原则

MCP 服务端本体可以统一安装在 C:\Dev\mcp，但不建议把 MATLAB MCP Server 长期写入全局 Codex 配置：

%USERPROFILE%\.codex\config.toml

原因是全局配置会影响所有 Codex 会话，容易出现“每次打开 Codex 都尝试唤起 MATLAB”的问题。

推荐做法是：

全局 ~/.codex/config.toml 只保留通用 Codex 配置。
删除全局配置中的 [mcp_servers.matlab] 段落。
在需要 MATLAB 的具体项目仓库中创建项目级配置：
<repo>\.codex\config.toml

例如博士论文代码工程：

V:\src\thesis-code\.codex\config.toml

项目级 MATLAB MCP 配置模板：

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

说明：

--matlab-root 应改成当前机器实际 MATLAB 安装路径。
不建议在模板中写死 --initial-working-folder。项目级配置启用时，优先让 MATLAB 从当前项目根目录启动；只有在某个项目确实需要固定启动目录时，再在该项目配置中单独添加。
--initialize-matlab-on-startup=false 用于避免 Codex 启动时立即预热 MATLAB。
若需要连接已经打开的 MATLAB，再把 --matlab-session-mode=new 改为 --matlab-session-mode=existing，并在 MATLAB 中按 MCP Server Toolkit 要求共享会话。

### 3.4 共享资源

凡是被多个项目复用的公共资源，都放到 C:\Dev\resources。

例如：

STK 卫星数据
地形 / 影像 / 底图
模板场景
通用参考数据
共享参数模板

### 3.5 项目源码

凡是 Git 仓库、活跃开发工程、频繁修改的项目代码，都放到 V:\src。

项目自己的 Codex 配置、AGENTS.md、测试脚本和项目说明文档也随项目源码放在 V:\src\<project> 内。

例如：

V:\src\thesis-code\
  .codex\
    config.toml
  AGENTS.md
  startup.m
  src\
  scripts\
  tests\

### 3.6 构建输出

凡是可再生的构建结果、中间目录、自动生成报告，都放到 V:\build。

### 3.7 缓存

凡是可以删除后重新生成的缓存，都放到 V:\cache。

例如：

pub cache
Gradle cache
vcpkg downloads
vcpkg binary cache
pip cache
conda 包缓存
temp

### 3.8 数据集

凡是体积较大、用于实验或分析的数据输入输出，都放到 V:\datasets。

例如：

蒙特卡洛仿真结果
STK 导出结果
遥测原始数据
大型 CSV / MAT / HDF5

### 3.9 临时工作区

凡是短期试验、临时导入导出、预计后续删除的内容，都放到 V:\scratch。

### 3.10 旧工程兼容区

凡是依赖 NTFS 行为、老 32 位编译链、古早 Qt 工程、旧脚本链路的内容，都放到 C:\Dev\legacy。

## 4. 典型归类示例

### Flutter
SDK：C:\Dev\toolchains\flutter
项目：V:\src\<project>
缓存：V:\cache\pub、V:\cache\gradle
构建输出：V:\build\<project>

### vcpkg
本体：C:\Dev\toolchains\vcpkg
downloads：V:\cache\vcpkg-downloads
binary cache：V:\cache\vcpkg-bincache
项目：V:\src\<project>

### Qt
新版 Qt：C:\Dev\toolchains\qt
老版 Qt：C:\Dev\toolchains\qt-legacy
特殊旧项目：C:\Dev\legacy\src
旧项目构建输出：C:\Dev\legacy\build

### MATLAB MCP / Codex
MATLAB MCP Core Server：C:\Dev\mcp\servers\matlab-mcp-core-server\bin
MATLAB Agentic Toolkit：C:\Dev\mcp\toolkits\matlab-agentic-toolkit
Codex 项目级配置模板：C:\Dev\mcp\configs\codex\templates
博士论文项目配置：V:\src\thesis-code\.codex\config.toml
博士论文项目规则：V:\src\thesis-code\AGENTS.md

### STK 数据与资源
共享卫星数据：C:\Dev\resources\stk\satellites
地形：C:\Dev\resources\stk\terrain
影像：C:\Dev\resources\stk\imagery
模板场景：C:\Dev\resources\stk\templates
某项目专用场景：V:\src\<project>\assets\stk
导出结果：V:\datasets\stk-exports

## 5. 六条核心规则
工具本体进 C:\Dev\toolchains。
MCP 服务端、Toolkit 和配置模板进 C:\Dev\mcp。
共享资产进 C:\Dev\resources。
活跃工程进 V:\src。
构建输出、缓存、数据和临时文件进 V:\build / V:\cache / V:\datasets / V:\scratch。
历史兼容内容进 C:\Dev\legacy。

## 6. 最终目录结构
C:\Dev\
  toolchains\
  mcp\
    servers\
      matlab-mcp-core-server\
        bin\
        releases\
    toolkits\
      matlab-agentic-toolkit\
    configs\
      codex\
        templates\
    docs\
    logs\
  resources\
  scripts\
  docs\
  volumes\
  backups\
  legacy\

V:\
  src\
  build\
  cache\
  datasets\
  scratch\

## 7. 补充说明
Dev Drive 的 .vhdx 文件建议放在 C:\Dev\volumes。
默认安装的软件可继续使用其默认安装路径，不必强行纳入本治理结构。
本治理结构仅管理“你主动控制的目录”，不试图接管整个系统盘的所有软件安装。
MATLAB MCP 这类重型 MCP 不建议放在 Codex 全局配置中长期启用。
项目级 MCP 配置必须跟随项目仓库管理，便于复现、迁移和小步回滚。