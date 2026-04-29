# MCP 治理层说明

## 1. 目录定位

`mcp/` 是 `dev_dev_governance_file` 中专门用于管理 MCP（Model Context Protocol）相关自动化配置、脚本和文档的目录。

它解决的是“整机治理”和“项目启用”之间的边界问题：

- **整机治理层**：负责下载、安装、更新和归档 MCP Server 本体、Toolkit、配置模板和说明文档。
- **项目启用层**：负责在某个具体项目中生成 `.codex/config.toml`，让 Codex 只在该项目中启用对应 MCP Server。

这套设计避免把 MATLAB MCP 这类重型工具写入 Codex 全局配置，从而避免“每次打开 Codex 都尝试唤起 MATLAB”的问题。

---

## 2. 推荐目录结构

```text
dev_dev_governance_file/
  mcp/
    README.md
    matlab/
      README_machine_install.md
      install_matlab_mcp_machine.ps1
      README_project_setup.md
      setup_project_matlab_mcp.ps1
```

其中：

- `mcp/README.md`：说明 MCP 治理层的总体原则。
- `mcp/matlab/README_machine_install.md`：说明整机层 MATLAB MCP 安装逻辑。
- `mcp/matlab/install_matlab_mcp_machine.ps1`：自动下载安装 MATLAB MCP Core Server 和可选的 MATLAB Agentic Toolkit；不写全局 Codex 配置。
- `mcp/matlab/README_project_setup.md`：说明某个项目如何启用 MATLAB MCP。
- `mcp/matlab/setup_project_matlab_mcp.ps1`：拖入项目根目录后运行，自动生成项目级 `.codex/config.toml` 和项目说明 Markdown。

---

## 3. 分层原则

### 3.1 整机层：安装 MCP 本体

整机层只负责把 MCP 相关工具放到固定位置，例如：

```text
C:\Dev\mcp\
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
```

整机层不应修改：

```text
%USERPROFILE%\.codex\config.toml
```

### 3.2 项目层：启用 MCP

项目层负责在具体工程中生成：

```text
<project>\
  .codex\
    config.toml
  docs\
    MATLAB_MCP_PROJECT.md
```

这样，只有当 Codex 在该项目中运行，并且该项目被信任时，才会启用项目级 MATLAB MCP 配置。

---

## 4. 推荐使用方式

### 第一步：整机安装

在 `dev_dev_governance_file/mcp/matlab` 中运行：

```powershell
.\install_matlab_mcp_machine.ps1
```

这一步会：

1. 创建 `C:\Dev\mcp` 下的标准目录。
2. 下载 MATLAB MCP Core Server Windows 可执行文件。
3. 可选克隆 MATLAB Agentic Toolkit。
4. 生成 Codex 项目级配置模板。
5. 检查全局 Codex 配置中是否残留 MATLAB MCP 段，但不会自动修改全局配置。

### 第二步：项目启用

把下面脚本复制到需要启用 MATLAB MCP 的工程根目录：

```text
mcp/matlab/setup_project_matlab_mcp.ps1
```

然后在该工程根目录运行：

```powershell
.\setup_project_matlab_mcp.ps1
```

这一步会生成：

```text
.codex/config.toml
docs/MATLAB_MCP_PROJECT.md
```

---

## 5. 核心约束

1. MCP Server 本体统一归整机治理层。
2. MCP 是否启用交给具体项目决定。
3. MATLAB MCP 不写入 Codex 全局配置。
4. 项目级配置必须随项目一起可复现、可审计、可回滚。
5. 长耗时 MATLAB 实验不应默认由 MCP 自动运行，应先进行只读审计和 smoke test。
