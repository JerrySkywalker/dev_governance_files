# Jerry Repository-Health Harness

[English](README.md)

这是当前 Harness 工作的唯一入口。

## 当前标识

```text
MODEL_ID=JERRY_HARNESS_MODEL_V1
BASELINE_ID=JERRY_AUTONOMY_CI_PARAMS_V1
CONTEXT_MANIFEST_ID=JERRY_AGENT_CONTEXT_V1
STATUS=PROVISIONAL
```

## 阅读路径

| 任务 | 必读上下文 |
| --- | --- |
| 解释 Harness | 本 README + Specification 对应章节 |
| 创建或恢复 Goal | 本 README + Goal/Receipt Contract + 当前 Profile 切片 |
| 审计执行 | Specification + 参数 JSON + Goal + Receipt + 条件 Playbook |
| 调整参数 | Specification + Baseline 依据 + 消费 Receipt + 显式历史证据 |
| Self-hosted CI | 当前 Profile + `../playbooks/self-hosted-ci-playbook.md` |
| 历史分析 | 仅显式指定的 Retrospective 章节 |

## Harness 模型

```text
Harness 实例
  = 版本选择
  + 控制向量 <A,B,P>
  + 操作层 L
  + 证明向量 <V,E,F,G>
  + 分域预算账本
  + Goal 范围
  + 当前 Receipt 状态
```

### 控制向量

- `A`：权限，回答“允许触碰什么”。
- `B`：弹性，回答“已准入工作可以怎样继续”。
- `P`：进展，回答“是否产生可审计的新状态”。

### 证明向量

- `V`：证明深度，回答“证明了什么”。
- `E`：执行环境，回答“在哪里证明”。
- `F`：频率，回答“何时、多久证明一次”。
- `G`：阻断级别，回答“失败会阻断什么”。

### 操作层

| 层级 | 目的 | 典型向量 |
| --- | --- | --- |
| `L0` | 编辑反馈 | `V0/V1,E0,F0,G0` |
| `L1` | 候选接受 | `V1` 加聚焦 `V3/V4`，`F1,G1` |
| `L2` | Exact-head 仓库接受 | `V2` 加适用 `V3/V4`，`F2,G2` |
| `L3` | 已部署候选和 Owner 接受 | `V5,E4,F4,G3/G4` |
| `L4` | 受保护预检和事务 | `V6,E5/E6,F4,G3/G4` |
| `L5` | Finalize 与 Closeout | `V7,E5/E6,F4,G4` |

## Profile

| Profile | 初始控制状态 | 层范围 |
| --- | --- | --- |
| `DOCS_CAPTURE_V2` | `A1,B2,P_INIT` | `L0-L2` |
| `INTERACTIVE_REPOSITORY_V1` | `A2,B2,P_INIT` | `L0-L2` |
| `HIGH_ASSURANCE_WAVE_V1` | `A2/A3,B3,P_INIT` | `L0-L3` |
| `COMPRESSED_TRAIN_V1` | `A3,B3,P_INIT` | `L1-L3` |
| `PROTECTED_PREFLIGHT_V2` | `A4,B3,P_INIT` | 只读 `L4` |
| `PROTECTED_TRANSACTION_V2` | `A5,B4,P_INIT` | `L4-L5` |

Profile 只装载默认值，不创造权限。

## 十六类参数族

1. 权限等级；
2. 弹性等级；
3. 进展状态；
4. Profile；
5. 证明深度；
6. 执行环境；
7. 执行频率；
8. 阻断级别；
9. 操作层；
10. 分域预算账本；
11. 微操作重试；
12. 时间与观察；
13. 并发与 Gate 拓扑；
14. 状态转移与补充；
15. 安全和冻结参数；
16. 校准与调参。

## 硬约束

```text
AUTHORITY_NEVER_EXPANDS_AUTOMATICALLY=true
BUDGET_DOMAINS_NEVER_BORROW=true
SAME_HEAD_SAME_SIGNATURE_RERUN_LIFETIME=1
DUPLICATE_CANONICAL_FULL_GATE_COUNT=0
FAILED_OR_UNVERIFIED_ROLLBACK_HARD_STOP=true
```

## 唯一事实来源

- 语义：[`harness-specification-v1.md`](harness-specification-v1.md)
- 数值：[`../../../config/repo-health-harness-v1.json`](../../../config/repo-health-harness-v1.json)
- 依据：[`harness-baseline-v1.md`](harness-baseline-v1.md)
- Goal/Receipt 接口：[`harness-goal-receipt-contract-v1.md`](harness-goal-receipt-contract-v1.md)

## 当前兼容机制

- [`WRITER_LEASE_V1_INTERIM_SETTLEMENT`](writer-lease-v1-interim-settlement.md)
  是已过期普通开发 Writer Lease v1 的临时、fail-closed 兼容路径。它排除
  production，且不替代 Writer Lease v2（[issue #30](https://github.com/JerrySkywalker/dev_governance_files/issues/30)）。
- [`PROTECTED_A5_GOVERNANCE_FINALIZER_V1`](protected-a5-governance-finalizer-v1.md)
  是独立的、需 Owner 明确授权的 L5 保护态 A5 Writer Lease v1 治理结算路径。
  v1 只支持 `FAILED_BEFORE_CONFIG` / `OWNER_ABORTED_PREPARED`，且不会修改 production 事务。

Retrospective 只解释经验来源，不提供活动默认值。
