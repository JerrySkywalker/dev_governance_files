# dev_governance_files

[English](README.md)

这是 Jerry 本地与云端开发流程使用的版本化治理、Harness、操作手册、
计划与工程经验仓库。

## 当前有效内容

本仓库现在具有明确的 Agent 上下文契约。并非所有文档都是执行指令。

- `AGENTS.md`：简短的 Agent 路由与安全规则。
- `.agent/context-manifest-v1.json`：机器可读的上下文分类。
- `docs/jerry-series/harness/`：当前有效的 Repository-Health Harness 规范。
- `config/repo-health-harness-v1.json`：Harness 活动参数的唯一数值来源。
- `docs/jerry-series/playbooks/`：按条件读取的操作方法。
- `docs/jerry-series/decisions/`：已接受决策的规范性理由。
- `docs/jerry-series/retrospectives/`：Wave 与事故的历史经验。
- `docs/jerry-series/plans/`：历史计划或当前 Goal 显式绑定的计划，不提供默认值。

Harness 任务应从
[`docs/jerry-series/harness/README.zh-CN.md`](docs/jerry-series/harness/README.zh-CN.md)
开始。

Windows 开发机目录与 Python/uv/Conda 引导治理见
[`WINDOWS_DEV_BOOTSTRAP_V2.md`](WINDOWS_DEV_BOOTSTRAP_V2.md)。目录 manifest 是
唯一来源；引导入口只处理目录拓扑，不修改工作站的软件包、profile、dotfiles 或
设备状态。

## Agent 上下文类别

| 类别 | 默认行为 |
| --- | --- |
| `AGENT_INSTRUCTION` | 自动发现的简短指令 |
| `ACTIVE_NORMATIVE` | 任务匹配时读取，是当前事实来源 |
| `CONDITIONAL_OPERATIONAL` | 环境或层级匹配时读取 |
| `ACTIVE_NORMATIVE_RATIONALE` | 用于理解已接受决策 |
| `HISTORICAL_REFERENCE` | 仅显式历史回顾；禁止执行 |
| `ARCHIVE_EXPLICIT_ONLY` | 仅显式审计或当前 Goal 绑定 |
| `MACHINE_GENERATED` | 只能通过源文件或生成器修改 |

## Harness 标识

```text
MODEL_ID=JERRY_HARNESS_MODEL_V1
BASELINE_ID=JERRY_AUTONOMY_CI_PARAMS_V1
CONTEXT_MANIFEST_ID=JERRY_AGENT_CONTEXT_V1
```

Harness 实例由以下部分组成：

```text
版本选择
+ 控制向量 <A,B,P>
+ 操作层 L
+ 证明向量 <V,E,F,G>
+ 分域预算账本
+ Goal 范围
+ 当前 Receipt 状态
```

## 安全开发流程

1. 分类任务，只读取路由后的最小上下文。
2. 保持活动规范与历史证据的边界。
3. 做聚焦修改。
4. 运行对应契约测试。
5. 检查完整 Diff 与生成文件漂移。
6. 通过评审分支和 PR 提交。

## 验证命令

```powershell
pwsh -NoProfile -File .\tests\repo-health\Test-RepoHealthHarnessContract.ps1
pwsh -NoProfile -File .\tests\repo-health\Test-WriterLeaseV1Settlement.ps1
pwsh -NoProfile -File .\tests\repo-health\Test-ProtectedA5GovernanceFinalizer.ps1
pwsh -NoProfile -File .\tests\repo-health\Test-AgentContextContract.ps1
pwsh -NoProfile -File .\scripts\repo-health\Build-RepoHealthHarnessReference.ps1 -Check
pwsh -NoProfile -File .\scripts\repo-health\Build-AgentContextAdapters.ps1 -Check
pwsh -NoProfile -File .\tests\windows-dev\Test-WindowsDevBootstrap.ps1
```

## 安全边界

合并本仓库不会授权或执行产品部署、Production 变更、凭据获取、
认证策略变更、Runner 恢复、受保护证据访问或 W8/W9 执行。

## 许可证

MIT，见 `LICENSE`。
