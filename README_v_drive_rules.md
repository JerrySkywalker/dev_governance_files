# V 盘治理规则说明（V:\ / Dev Drive）

## 1. 定位

`V:\` 是本机的工作层、高 IO 层、Dev Drive 层。它负责承载：

- 活跃源码工程
- 项目级 Codex / MCP 配置
- 构建输出
- 默认可清理缓存
- 大型实验数据
- 临时工作内容

它不负责承载长期稳定的工具链本体、MCP 服务端本体，也不负责长期归档共享资产。

若某台机器采用 C-only Python / Conda 模式，则 pip cache 与 conda 包缓存不放入 `V:\cache`，而放入 `C:\Dev\cache`。

---

## 2. 一级目录含义

### `V:\src`

活跃源码目录。

适合放：

- Flutter 项目
- C++ 项目
- Python 项目
- 自动化脚本项目
- 论文相关仿真工程
- 项目自己的 `.codex\config.toml` 和 `AGENTS.md`

项目级 MCP 配置示例：

```text
V:\src\thesis-code\
  .codex\
    config.toml
  AGENTS.md
  startup.m
  src\
  scripts\
  tests\
```

### `V:\build`

构建输出目录。

适合放：

- cmake 构建目录
- Qt shadow build
- Flutter build 输出
- 自动生成报告
- 中间链接目录

### `V:\cache`

默认可清理缓存目录。

适合放：

- pub cache
- Gradle cache
- vcpkg downloads
- vcpkg binary cache
- temp

可选放：

- pip cache
- conda 包缓存

说明：pip cache 和 conda 包缓存只有在启用 Dev Drive 高 IO 缓存策略时才放入 `V:\cache`。若机器采用 C-only Python / Conda 模式，则它们应放入：

```text
C:\Dev\cache\pip
C:\Dev\cache\conda-pkgs
```

### `V:\datasets`

大型项目数据与实验数据目录。

适合放：

- 蒙特卡洛仿真结果
- STK 导出结果
- 原始观测数据
- 大型 CSV / MAT / HDF5
- 实验输入批次

### `V:\scratch`

一次性临时工作区。

适合放：

- 临时导入导出目录
- 快速测试数据
- 短期试验文件
- 后续大概率删除的中间文件

---

## 3. 不应放在 V:\ 的内容

下列内容不应作为常规做法放在 `V:\`：

- Flutter SDK 本体
- vcpkg 本体
- Qt 本体
- Miniconda 本体
- conda envs 的长期稳定实例
- C-only 模式下的 pip cache 与 conda 包缓存
- MATLAB MCP Core Server 本体
- MATLAB Agentic Toolkit 本体
- 其他长期稳定的工具链本体
- Dev Drive 的 `.vhdx` 文件本身
- 共享资源主库
- 依赖 NTFS 行为的古早工程

这些内容应优先放在 `C:\Dev`。

MCP 相关内容的分工为：

```text
MCP 服务端本体：C:\Dev\mcp\servers
MATLAB Agentic Toolkit：C:\Dev\mcp\toolkits
Codex 配置模板：C:\Dev\mcp\configs\codex\templates
具体项目启用配置：V:\src\<project>\.codex\config.toml
```

---

## 4. 典型目录示例

```text
V:\
  src\
    thesis-code\
      .codex\
        config.toml
      AGENTS.md
    other-project\
  build\
  cache\
    pub\
    gradle\
    vcpkg-downloads\
    vcpkg-bincache\
    temp\
    # pip\             # optional, only when Dev Drive Python cache is enabled
    # conda-pkgs\      # optional, only when Dev Drive Python cache is enabled
  datasets\
    hgv\
    stk-exports\
    monte-carlo\
  scratch\
```

---

## 5. 推荐使用方式

### Flutter

- 项目源码：`V:\src\<project>`
- 构建输出：`V:\build\<project>`
- 缓存：`V:\cache\pub`、`V:\cache\gradle`

### vcpkg

- downloads：`V:\cache\vcpkg-downloads`
- binary cache：`V:\cache\vcpkg-bincache`
- 项目源码：`V:\src\<project>`

### Python / Conda

默认 C-only 模式：

```text
C:\Dev\toolchains\miniconda3
C:\Dev\envs\conda
C:\Dev\cache\pip
C:\Dev\cache\conda-pkgs
```

仅当明确启用 Dev Drive Python cache 时，才使用：

```text
V:\cache\pip
V:\cache\conda-pkgs
```

### STK

- 导出结果：`V:\datasets\stk-exports`
- 项目专用场景副本：`V:\src\<project>\assets\stk`

### MATLAB MCP / Codex

- MCP 服务端本体：`C:\Dev\mcp\servers\matlab-mcp-core-server\bin`
- Toolkit 本体：`C:\Dev\mcp\toolkits\matlab-agentic-toolkit`
- 项目启用配置：`V:\src\<project>\.codex\config.toml`
- 项目行为规则：`V:\src\<project>\AGENTS.md`

博士论文项目推荐配置位置：

```text
V:\src\thesis-code\.codex\config.toml
```

---

## 6. 规则总结

- `V:\` 管高吞吐工作集，不管工具链主安装。
- 活跃工程、构建输出、默认缓存和数据优先放到 `V:\`。
- `V:\` 的内容默认应具备“可重建、可迁移、可清理”的特征。
- pip cache 和 conda 包缓存是可选 Dev Drive 缓存，不是 C-only 模式的默认位置。
- 不把 `V:\` 当作长期兼容工具链、MCP 服务端或共享资源主库使用。
- 项目级 `.codex\config.toml` 可以放在 `V:\src\<project>` 内，因为它属于项目复现配置，而不是 MCP 服务端本体。
