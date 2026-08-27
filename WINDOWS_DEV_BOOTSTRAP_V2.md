# Jerry Windows 开发机引导 V2 / Jerry Windows Developer Bootstrap V2

## 规范状态与来源 / Normative status and source

本文件定义新 Jerry Windows 开发机的目录和 Python 工具链治理顺序。它是
**源码治理**，不授权修改任何设备、生产系统、Codex 实例、dotfiles 或已挂载
卷。目录清单的唯一机器可读来源是
[`config/windows-dev-directory-manifest-v1.json`](config/windows-dev-directory-manifest-v1.json)。
PowerShell 入口和验证都通过
[`tools/windows-dev/WindowsDevStructure.psm1`](tools/windows-dev/WindowsDevStructure.psm1)
读取该清单；不得在脚本中维护第二份路径列表。

This document defines the order for a new Jerry Windows workstation. It is
source governance only. The manifest is the only machine-readable topology
source; scripts and verification consume it rather than duplicate governed
paths.

## 规范生命周期 / Canonical lifecycle

1. **A — C 稳定层**：创建或验证 `C:\Dev` 稳定治理骨架。
2. **B — 安装前父目录**：确认 C 骨架包含后续工具、缓存、环境和备份所需的
   全部父目录。
3. **C — Dev Drive 准入**：若本机使用 Dev Drive，验证预期 `V:` 已挂载，且是
   Fixed、ReFS 卷。若 `V:` 缺失、不可检查或不适合，安全拒绝；绝不创建、挂载、
   格式化、替换或删除 VHDX。
4. **D — V 工作层**：只在 C 已通过且 V 已准入后，创建或验证 `V:\` 工作骨架。
5. **E — 软件安装**：仅在适用的目录拓扑有效后，由单独授权的流程安装包和工具。
6. **F — dotfiles / profile / 环境接线**：仅在软件安装之后运行；目录引导不执行它。
7. **G — 应用语义迁移**：例如 CHS，最后才可由自己的授权流程执行。

`bootstrap_windows_dev_structure.ps1 -Stage All` 是 Dev Drive 机器的标准 A–D
入口。`-Stage C` 只完成前置 C 工作；如果该机器计划使用 Dev Drive，它本身
不授权进入 E。`-Stage V` 与兼容 V 入口都会先验证完整的 C 拓扑。

The entrypoint has no package-manager, VHDX, profile, dotfiles, or application
migration command. Its successful result means only that the directory stage is
complete; it is not an installation approval.

```powershell
pwsh -NoProfile -File .\bootstrap_windows_dev_structure.ps1 -Stage All
```

`create_c_dev_structure.ps1`, `create_c_python_conda_structure.ps1`, and
`create_v_devdrive_structure.ps1` remain as compatibility entrypoints. They
are thin consumers of the same manifest and helper.

## 目录边界 / Directory boundaries

`C:\Dev` 是稳定治理层。清单保留既有 `toolchains`、MCP、资源、脚本、文档、
卷、备份、legacy 和 secrets 区域，并要求以下现代 Python / uv / Conda 布局：

| 作用 / Purpose | Canonical path |
| --- | --- |
| 稳定 CLI/shim 表面 / stable CLI and shim surface | `C:\Dev\tools\bin` |
| uv 长驻 CLI 工具状态 / uv persistent CLI-tool state | `C:\Dev\tools\uv-tools` |
| uv 管理的 Python runtime 状态 / uv-managed Python runtime state | `C:\Dev\tools\uv-python` |
| uv 缓存 / uv cache | `C:\Dev\cache\uv` |
| Miniconda 本体 / Miniconda root | `C:\Dev\toolchains\miniconda3` |
| Conda 环境 / Conda environments | `C:\Dev\envs\conda` |
| Conda 包缓存 / Conda package cache | `C:\Dev\cache\conda-pkgs` |
| pip 缓存 / pip cache | `C:\Dev\cache\pip` |
| Conda 备份 / Conda backups | `C:\Dev\backups\conda` |

`V:\` 是高 IO、可重建的工作层：`src`、`build`、`cache`、`datasets`、`scratch`
及现有有用的 cache/data 子目录。Python/Conda 缓存默认保持 C-only；只有
显式 `-IncludePythonCaches` 才会创建 `V:\cache\pip` 和
`V:\cache\conda-pkgs`。这两个目录从不属于默认 V 骨架。

## Python、uv 与 Conda 治理 / Python, uv, and Conda governance

- `uv` 二进制由 `winget` 的 `astral-sh.uv` 管理；目录引导不会安装它。
- `uv` 的状态使用上表的 `bin`、`uv-tools`、`uv-python`、`cache\uv` 路径。
- 不要求、也不建立规范性的全局系统 Python。
- bare `python` 和 bare `pip` 不是稳定的基础设施接口。
- Miniconda 保持在 `C:\Dev\toolchains\miniconda3`，安装时
  `AddToPath=false`、`RegisterPython=false`，不拥有 `conda init`。
- Conda 的懒加载 PowerShell hook 由 dotfiles 管理；项目依赖不堆入 base。
- uv-managed Python、Hermes/Codex/private venv 均不进入全局 PATH。

## 基础设施 Python 解析规则 / Infrastructure Python resolution policy

任何需要 Python 的基础设施必须解析一个**正向验证过的受管解释器**，而不是
假定 bare `python` 可用。概念顺序为：

```text
caller-supplied interpreter
  -> governed uv-managed Python
  -> another positively validated interpreter
  -> fail with an actionable diagnostic
```

调用方声明最低 Python 版本和需要的标准库能力。每个候选解释器至少必须：可执行
启动、满足该最低版本、并成功导入所需标准库（例如需要时 `tomllib`）。WindowsApps
alias 只是一条解析到的路径，不是可用 Python 进程的证据。

Infrastructure must not silently fall back to a global PATH interpreter. A
failure must report the checked resolution classes and tell the caller how to
provide or install a governed interpreter; it must not register a system Python
as a workaround.

## SKYFORGE-01 / CHS 经验边界 / CHS lesson

SKYFORGE-01 的当前证据是：bare `python` 只解析到 WindowsApps，无法得到可用
Python 进程；CHS 当前假定 `python`/`py`；live Codex 未被修改。这是一个 CHS
解析缺口，不是安装或注册全局系统 Python 的理由。

所需后续工作归属 `jerry-dotfiles`：CHS 必须支持上述受管 Python 解析策略。本
Goal 不编辑 `jerry-dotfiles`，也不触碰 zenbookduo runtime configuration。

The required next action is therefore a dotfiles-owned governed Python resolver,
not a global-Python change and not a live Codex mutation.

## 源码验证 / Source validation

```powershell
pwsh -NoProfile -File .\tests\windows-dev\Test-WindowsDevBootstrap.ps1
pwsh -NoProfile -File .\tests\repo-health\Test-RepoHealthHarnessContract.ps1
pwsh -NoProfile -File .\tests\repo-health\Test-AgentContextContract.ps1
```

The bootstrap test parses every entrypoint, checks manifest uniqueness and
safety invariants, verifies C/V temporary-directory idempotence, verifies that
V Python caches are opt-in, and proves refusal for an absent drive. It never
calls a bootstrap script against `C:\Dev` or `V:\`.
