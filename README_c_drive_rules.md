# C 盘治理规则说明（C:\Dev）

## 1. 定位

`C:\Dev` 是本机的治理层、稳定层、兼容层，使用 NTFS。它负责承载：

- 手动管理的工具链
- 需要稳定路径的开发环境实例
- C-only 模式下的语言工具缓存
- MCP 服务端、Agentic Toolkit 与配置模板
- 共享资源
- 机器级脚本与文档
- Dev Drive 虚拟磁盘文件
- 历史兼容内容

它不负责承载常规高频构建输出、大型实验数据和活跃工程工作集。若某类缓存必须脱离可替换 VHD，才允许按明确规则放入 `C:\Dev\cache`。

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

Miniconda 推荐路径：

```text
C:\Dev\toolchains\miniconda3
```

### `C:\Dev\envs`

需要长期稳定路径的开发环境实例目录。

适合放：

- conda envs
- 其他确实需要跨项目复用、路径稳定、可重建的开发环境实例

C-only Python / Conda 模式推荐路径：

```text
C:\Dev\envs\conda
```

说明：`envs` 不是工具链本体目录，也不是项目源码目录。它承载的是可重建但需要稳定路径的本机开发环境状态。

### `C:\Dev\cache`

C-only 模式下的轻量语言工具缓存目录。

适合放：

- pip cache
- conda 包缓存

推荐结构：

```text
C:\Dev\cache\
  pip\
  conda-pkgs\
```

说明：`C:\Dev\cache` 不是所有缓存的新归宿。只有当某类语言工具缓存需要脱离可替换 VHD，或需要与工具链保持同卷稳定性时，才放在这里。常规构建缓存、大型下载缓存和临时缓存仍默认放到 `V:\cache`。

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

### `C:\Dev\resources`

共享资源与公共资产目录。

适合放：

- STK 卫星数据
- 地形 / 影像 / 模板
- 通用参数模板
- 多项目复用数据包

### `C:\Dev\scripts`

机器级脚本目录。

适合放：

- 环境初始化脚本
- 目录创建脚本
- 备份脚本
- 挂载脚本
- 常用 PowerShell 脚本

### `C:\Dev\docs`

机器级治理文档目录。

适合放：

- 路径规范说明
- 环境部署说明
- 迁移记录
- 故障排查说明

### `C:\Dev\volumes`

虚拟磁盘文件目录。

适合放：

- Dev Drive 的 `.vhdx`

推荐示例：

```text
C:\Dev\volumes\dev-main.vhdx
```

### `C:\Dev\backups`

轻量备份与配置导出目录。

适合放：

- 环境变量导出
- 配置备份
- conda 迁移前导出
- 小型关键文件备份

Python / Conda 迁移备份推荐路径：

```text
C:\Dev\backups\conda
```

### `C:\Dev\legacy`

历史兼容目录，仅限 NTFS 的旧工程与旧资源保留区。

适合放：

- 古早 Qt 项目
- 依赖旧编译器的工程
- 必须使用 NTFS 的旧脚本链路

### `C:\Dev\secrets`

本机敏感凭据保管区。

适合放：

- SSH 私钥
- 本机使用但不应进入云同步或 Git 仓库的轻量凭据

推荐结构：

```text
C:\Dev\secrets\
  ssh\
    beijing.pem
```

要求：

- 不放入 OneDrive。
- 不放入 Git 仓库。
- 使用严格 NTFS ACL。
- OpenSSH 通过 `%USERPROFILE%\.ssh\config` 引用此处私钥。

---

## 3. Python / Conda 配置规则

C-only Python / Conda 模式用于避免 Python 工具链依赖可替换 VHD。

推荐路径：

```text
C:\Dev\toolchains\miniconda3      # Miniconda 本体
C:\Dev\envs\conda                # conda 环境
C:\Dev\cache\conda-pkgs          # conda 包缓存
C:\Dev\cache\pip                 # pip 缓存
C:\Dev\backups\conda             # 迁移前备份
```

配置原则：

- Miniconda 安装时不加入系统 PATH。
- Miniconda 安装时不注册为系统默认 Python。
- PowerShell 中的 conda hook 由 dotfiles 管理。
- 不在 base 环境中堆项目依赖。
- `pip` 优先通过 `python -m pip` 调用。
- Hermes / Codex / 其他工具自己的 venv 不进入全局 PATH。

---

## 4. MCP 配置规则

MCP 服务端可以统一放在 `C:\Dev\mcp`，但 MATLAB MCP 不建议写入 Codex 全局配置：

```text
%USERPROFILE%\.codex\config.toml
```

推荐做法：

1. 在 `C:\Dev\mcp` 中统一管理 MCP 服务端和模板。
2. 全局 Codex 配置只保留通用设置，不放 `[mcp_servers.matlab]`。
3. 哪个项目需要 MATLAB MCP，就在哪个项目仓库内放：`<repo>\.codex\config.toml`。

项目级 MATLAB MCP 配置模板可以保存在：

```text
C:\Dev\mcp\configs\codex\templates\matlab-project.config.toml
```

---

## 5. 不应放在 C:\Dev 的内容

下列内容不应作为常规做法放在 `C:\Dev`：

- 活跃项目源码（应优先放到 `V:\src`）
- 构建输出（应放到 `V:\build`）
- 常规大型缓存（应放到 `V:\cache`）
- 大型实验数据（应放到 `V:\datasets`）
- 一次性临时文件（应放到 `V:\scratch`）
- 项目专属 `.codex\config.toml`（应放到对应项目仓库内）

例外：C-only Python / Conda 模式下，pip cache 与 conda 包缓存可以放入 `C:\Dev\cache`。

---

## 6. 典型目录示例

```text
C:\Dev\
  toolchains\
    flutter\
    vcpkg\
    qt\
    qt-legacy\
    android-sdk\
    miniconda3\
  envs\
    conda\
  cache\
    pip\
    conda-pkgs\
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
    conda\
  legacy\
    src\
    build\
    resources\
  secrets\
    ssh\
```

---

## 7. 规则总结

- `C:\Dev` 管稳定、兼容、共享、长期维护的内容。
- 工具链统一放在 `C:\Dev\toolchains`。
- C-only Python / Conda 模式下，envs 与语言工具缓存放在 `C:\Dev\envs` / `C:\Dev\cache`。
- MCP 服务端、Agentic Toolkit 和配置模板统一放在 `C:\Dev\mcp`。
- 共享资源统一放在 `C:\Dev\resources`。
- 老旧兼容工程优先保留在 `C:\Dev\legacy`。
- 不把 `C:\Dev` 当作活跃工程、构建输出、常规大型缓存或大型实验数据盘使用。
- 不把 MATLAB MCP 的项目启用配置写死在全局 Codex 配置中。
