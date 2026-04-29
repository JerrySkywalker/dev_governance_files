# MATLAB MCP 整机安装说明

## 1. 目标

本目录用于完成 MATLAB MCP 的整机级安装部署。

这里的“整机级安装”只做三件事：

1. 在 `C:\Dev\mcp` 下创建统一治理目录。
2. 下载并安装 MATLAB MCP Core Server 本体。
3. 可选克隆 MATLAB Agentic Toolkit。
4. 生成可复制到项目中的 Codex 配置模板。

它**不会**修改 Codex 全局配置：

```text
%USERPROFILE%\.codex\config.toml
```

这是为了避免 MATLAB MCP 在所有 Codex 会话中默认启用。

---

## 2. 推荐安装位置

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
        matlab-project.config.toml
  docs\
  logs\
```

---

## 3. 使用方法

在本目录运行：

```powershell
.\install_matlab_mcp_machine.ps1
```

常用参数：

```powershell
# 默认安装到 C:\Dev\mcp，默认 MATLAB 路径为 R2025b
.\install_matlab_mcp_machine.ps1

# 指定 MATLAB 安装路径
.\install_matlab_mcp_machine.ps1 -MatlabRoot "C:\Program Files\MATLAB\R2025b"

# 跳过 MATLAB Agentic Toolkit 克隆
.\install_matlab_mcp_machine.ps1 -SkipToolkit

# 强制重新下载 MATLAB MCP Core Server
.\install_matlab_mcp_machine.ps1 -Force
```

---

## 4. 安装完成后的产物

核心可执行文件：

```text
C:\Dev\mcp\servers\matlab-mcp-core-server\bin\matlab-mcp-core-server.exe
```

项目级 Codex 配置模板：

```text
C:\Dev\mcp\configs\codex\templates\matlab-project.config.toml
```

MATLAB Agentic Toolkit：

```text
C:\Dev\mcp\toolkits\matlab-agentic-toolkit
```

---

## 5. 整机安装后还需要做什么

完成整机安装后，不要急着运行 MATLAB MCP。

下一步应到具体项目中运行项目级配置脚本：

```powershell
.\setup_project_matlab_mcp.ps1
```

项目级配置脚本会在项目内生成：

```text
.codex/config.toml
docs/MATLAB_MCP_PROJECT.md
```

然后进入项目目录启动 Codex：

```powershell
cd <project>
codex
```

在 Codex 中执行：

```text
/mcp
```

确认 `matlab` server 已加载，再让 Codex 检测 MATLAB 版本和工具箱。

---

## 6. 全局配置检查

如果你之前把 MATLAB MCP 写进过全局配置，请手动检查：

```powershell
notepad "$env:USERPROFILE\.codex\config.toml"
```

删除类似段落：

```toml
[mcp_servers.matlab]
command = "..."
args = [...]
```

本目录提供的整机安装脚本只会提示是否发现全局 MATLAB MCP 段，不会擅自修改它。
