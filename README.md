# dev_governance_files

Windows 开发机目录治理规则仓库，用于规范 `C:\Dev`（治理层）与 `V:\`（工作层 / Dev Drive）的职责边界、目录结构和迁移策略。

## 为什么有这个仓库

这个仓库的目标是把分散的个人经验固化为可复用、可审阅、可版本化的规则文档与脚本，避免以下常见问题：

- 工具链、工程源码、缓存和数据混放
- 长期稳定内容与高 IO 内容放在同一层
- 全局配置污染导致工具误触发（例如重型 MCP）
- 新机器迁移时目录约定不一致

## 仓库内容

- `README_directory_rules_full.md`：完整总规则（推荐先读）
- `README_c_drive_rules.md`：`C:\Dev` 的定位与目录规范
- `README_v_drive_rules.md`：`V:\` 的定位与目录规范
- `create_c_dev_structure.ps1`：创建 `C:\Dev` 推荐目录结构
- `create_v_devdrive_structure.ps1`：创建 `V:\` 推荐目录结构

## 快速开始（人类）

1. 阅读总规则：`README_directory_rules_full.md`
2. 以管理员或有权限身份打开 PowerShell
3. 在仓库根目录执行脚本（按需）：

```powershell
pwsh -File .\create_c_dev_structure.ps1
pwsh -File .\create_v_devdrive_structure.ps1
```

4. 根据实际环境微调路径（例如 MATLAB 根路径、项目路径）

## 关键原则

- `C:\Dev` 只放稳定、兼容、长期维护内容
- `V:\` 优先放活跃工程、构建输出、缓存和数据
- MCP 服务端本体与项目级启用配置分离
- 项目级配置跟随项目仓库管理，便于复现与回滚

## 适用范围

适用于希望在 Windows 上长期维护可扩展开发环境的个人或小团队，尤其是包含以下场景时：

- 多语言工程（C++ / Python / Flutter / MATLAB）
- 需要 Dev Drive 的高 IO 工作流
- 需要将工具链治理与工程治理分层

## Agent Notes

This section is intended for coding agents and automation tools.

### Repo Intent

- This repository is documentation-first.
- Changes should preserve clarity, consistency, and practical operability.
- Prefer incremental updates to existing rules over large rewrites.

### Update Rules

- Keep terminology stable: `C:\Dev` is governance/stable layer; `V:\` is working/high-IO layer.
- Do not introduce contradictory placement rules across markdown files.
- If one rule file changes semantics, update related files in the same commit.
- Keep examples realistic and aligned with current path conventions.

### Script Change Rules

- Scripts should be idempotent where possible.
- Avoid destructive behavior by default.
- Document assumptions in comments when logic is non-trivial.

### PR/Commit Guidance

- Use clear commit messages: `docs: ...`, `scripts: ...`, `governance: ...`.
- For rule changes, include rationale and migration impact in commit body or PR text.
- Prefer small, reviewable commits.

## 许可证

本仓库使用 MIT 许可证，详见 `LICENSE`。