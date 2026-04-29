# MATLAB MCP 项目级配置说明

## 1. 目标

本文件说明如何在某个具体项目中启用 MATLAB MCP。

与整机安装不同，项目级配置只影响当前项目：

```text
<project>\.codex\config.toml
```

这样可以避免 MATLAB MCP 被全局启用。

---

## 2. 适用场景

适合以下项目：

- 博士论文 MATLAB 代码工程
- MATLAB 仿真工程
- 需要 Codex 直接检查、运行 MATLAB 脚本的项目
- 需要进行 MATLAB smoke test 的项目

不建议对所有项目都启用 MATLAB MCP。MATLAB 启动较重，应按项目启用。

---

## 3. 使用方法

### 3.1 将脚本复制到项目根目录

把下面脚本复制到目标工程根目录：

```text
mcp/matlab/setup_project_matlab_mcp.ps1
```

例如：

```text
V:\src\thesis-code\
  setup_project_matlab_mcp.ps1
  startup.m
  src\
  scripts\
  tests\
```

### 3.2 在项目根目录运行

```powershell
.\setup_project_matlab_mcp.ps1
```

如果你的 MATLAB 安装路径不是默认值：

```powershell
.\setup_project_matlab_mcp.ps1 -MatlabRoot "C:\Program Files\MATLAB\R2025b"
```

如果你已经有 `.codex/config.toml`，并且希望替换其中的 MATLAB MCP 段：

```powershell
.\setup_project_matlab_mcp.ps1 -OverwriteMatlabSection
```

---

## 4. 生成内容

脚本会生成：

```text
<project>\
  .codex\
    config.toml
  docs\
    MATLAB_MCP_PROJECT.md
```

其中 `.codex/config.toml` 会包含：

```toml
[mcp_servers.matlab]
command = "C:\\Dev\\mcp\\servers\\matlab-mcp-core-server\\bin\\matlab-mcp-core-server.exe"
args = [
  "--matlab-root=C:\\Program Files\\MATLAB\\R2025b",
  "--matlab-display-mode=nodesktop",
  "--matlab-session-mode=new",
  "--initialize-matlab-on-startup=false",
  "--disable-telemetry=true",
  "--initial-working-folder=<project>"
]
```

---

## 5. 验证方法

进入项目目录：

```powershell
cd <project>
codex
```

如果 Codex 提示是否信任该项目，选择信任。

进入 Codex 后执行：

```text
/mcp
```

应能看到 `matlab` server。

然后输入：

```text
请检测 MATLAB 版本和已安装工具箱。
```

如果成功，说明项目级 MATLAB MCP 已启用。

---

## 6. 建议的第一次 MATLAB MCP 任务

不要一上来就让 Codex 大规模整理工程。推荐先执行只读检查：

```text
请使用 MATLAB MCP 对当前工程做只读环境检查，不要修改任何文件。
要求：
1. 检测 MATLAB 版本和工具箱；
2. 检查当前工作目录；
3. 尝试执行 startup('force', true)；
4. 使用 check_matlab_code 检查 startup.m；
5. 不运行任何大型实验；
6. 汇报 MATLAB 是否可用、路径链是否正常、下一步建议。
```

---

## 7. 论文代码工程建议

对于博士论文 MATLAB 工程，建议项目级 `AGENTS.md` 中写明：

1. 默认只读审计。
2. 不删除 `outputs`、`mats`、`figs`、`logs`。
3. 不擅自改变数值算法、参数网格和论文图表口径。
4. 长耗时实验只生成命令，不默认执行。
5. 每次修改小步提交 Git commit。

项目级 MCP 只解决“Codex 能调用 MATLAB”的问题，不解决“能否安全重构”的问题。安全重构仍依赖工程规则、Git 分支和 smoke tests。
