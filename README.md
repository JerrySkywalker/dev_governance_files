# dev_governance_files

Windows 开发机目录治理与 MATLAB MCP 集成仓库。  
本仓库用于统一管理 `C:\Dev`（治理/稳定层）与 `V:\`（工作/高 IO 层）的职责边界，并提供可执行脚本完成目录初始化和 MATLAB MCP 落地。

## 项目目标

- 将目录治理规则文档化、脚本化、版本化。
- 固化 `C:\Dev` 与 `V:\` 的分层约定，降低长期维护成本。
- 提供 MATLAB MCP 的整机安装与项目级启用脚本，避免全局配置污染。

## 仓库结构

```text
dev_governance_files/
	README.md
	LICENSE
	README_directory_rules_full.md
	README_c_drive_rules.md
	README_v_drive_rules.md
	create_c_dev_structure.ps1
	create_v_devdrive_structure.ps1
	mcp/
		matlab/
			install_matlab_mcp_machine.ps1
			setup_project_matlab_mcp.ps1
			README_project_setup.md
	secrets/
		ssh/
			setup_ssh_key_store.ps1
			ssh_config.example
			README_ssh_key_store.md
```

## 文档导读

1. `README_directory_rules_full.md`：总规则与完整归类逻辑（优先阅读）。
2. `README_c_drive_rules.md`：`C:\Dev` 的目录职责与反模式。
3. `README_v_drive_rules.md`：`V:\` 的目录职责与反模式。
4. `mcp/matlab/README_project_setup.md`：项目级 MATLAB MCP 配置说明。
5. `secrets/ssh/README_ssh_key_store.md`：SSH 私钥保管区、权限治理与 OpenSSH 配置说明。

## 一键初始化（目录治理）

在仓库根目录执行：

```powershell
pwsh -File .\create_c_dev_structure.ps1
pwsh -File .\create_v_devdrive_structure.ps1
```

说明：

- 两个脚本用于创建建议目录结构。
- 重复执行应保持幂等，不应破坏已有文件。

## SSH 私钥保管区初始化

本仓库只保存 SSH 密钥治理规则、脚本和模板，不保存任何真实私钥。

初始化本机 SSH 私钥保管区：

```powershell
pwsh -File .\secrets\ssh\setup_ssh_key_store.ps1
```

迁移已有私钥：

pwsh -File .\secrets\ssh\setup_ssh_key_store.ps1 -SourceKey "C:\Dev\ssh_key\beijing.pem"

推荐实际私钥位置：

C:\Dev\secrets\ssh

推荐 OpenSSH 配置入口：

%USERPROFILE%\.ssh\config

## MATLAB MCP 使用流程

### 步骤 1：整机安装 MATLAB MCP 服务

执行：

```powershell
pwsh -File .\mcp\matlab\install_matlab_mcp_machine.ps1
```

常见参数：

```powershell
pwsh -File .\mcp\matlab\install_matlab_mcp_machine.ps1 -MatlabRoot "C:\Program Files\MATLAB\R2025b"
pwsh -File .\mcp\matlab\install_matlab_mcp_machine.ps1 -Force
pwsh -File .\mcp\matlab\install_matlab_mcp_machine.ps1 -SkipToolkit
```

脚本作用：

- 安装 MATLAB MCP Core Server 到 `C:\Dev\mcp\servers\matlab-mcp-core-server\bin`。
- 可选克隆/更新 MATLAB Agentic Toolkit 到 `C:\Dev\mcp\toolkits\matlab-agentic-toolkit`。
- 生成项目级模板 `C:\Dev\mcp\configs\codex\templates\matlab-project.config.toml`。

### 步骤 2：在目标项目启用 MATLAB MCP

在目标项目根目录运行：

```powershell
pwsh -File .\setup_project_matlab_mcp.ps1
```

或从本仓库直接指定项目路径：

```powershell
pwsh -File .\mcp\matlab\setup_project_matlab_mcp.ps1 -ProjectRoot "V:\src\your-project"
```

脚本会生成：

- `<project>\.codex\config.toml`
- `<project>\docs\MATLAB_MCP_PROJECT.md`

## 核心治理原则

- 工具链本体放 `C:\Dev\toolchains`。
- MCP 服务端本体与模板放 `C:\Dev\mcp`。
- 活跃工程放 `V:\src`。
- 构建、缓存、数据、临时内容放 `V:\build` / `V:\cache` / `V:\datasets` / `V:\scratch`。
- MATLAB MCP 推荐项目级启用，不建议常驻全局 `~/.codex/config.toml`。
- SSH 明文私钥放 `C:\Dev\secrets\ssh`，并设置严格 NTFS ACL。
- OneDrive 和 Git 仓库不得保存明文私钥，只可保存说明、公钥或加密备份。

## 典型工作流

1. 新机器初始化目录结构。
2. 安装 MATLAB MCP 整机服务。
3. 为具体项目生成项目级 `.codex/config.toml`。
4. 在 Codex 中通过 `/mcp` 验证 `matlab` server 可见。
5. 先跑只读检查，再进行小步改动与验证。

## Agent Notes

This section is for coding agents and automation tools.

### Intent

- Keep this repository as a governance baseline and script toolkit.
- Prefer precise updates over broad rewrites.

### Consistency Constraints

- Keep terminology stable: `C:\Dev` = governance/stable layer; `V:\` = working/high-IO layer.
- Do not introduce conflicting directory placement rules between markdown files.
- If semantics are changed in one rule file, update related files in the same commit.

### Script Constraints

- Preserve idempotency and safety defaults.
- Avoid destructive changes unless explicitly required and documented.
- Validate path assumptions and provide actionable error messages.

### Commit Guidance

- Suggested commit prefixes: `docs:`, `scripts:`, `governance:`, `mcp:`.
- For governance rule changes, include migration impact in commit body or PR description.

## 许可证

本仓库采用 MIT License，见 `LICENSE`。