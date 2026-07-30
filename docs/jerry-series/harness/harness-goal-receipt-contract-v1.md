# Harness Goal and Receipt Contract V1

## Goal admission envelope

Every Harness-controlled Goal declares:

```text
HARNESS_MODEL_ID=JERRY_HARNESS_MODEL_V1
HARNESS_BASELINE_ID=JERRY_AUTONOMY_CI_PARAMS_V1
HARNESS_PROFILE=<profile>

AUTHORITY_CLASS=<A0-A5 or OWNER>
ELASTICITY_GRADE=<B0-B4>
INITIAL_PROGRESS_STATE=P_INIT

CURRENT_LAYER=<L0-L5>
MAX_ADMITTED_LAYER=<L0-L5>
NEXT_PROOF_VECTOR=<V,E,F,G>

ALLOWED_REPOSITORIES=<exact set>
ALLOWED_PATHS=<exact set>
ALLOWED_SERVICES=<exact set or NONE>
PROTECTED_BOUNDARIES=<exact set>
OWNER_ONLY_BOUNDARIES=<exact set>

BUDGET_OVERRIDES=<explicit domain overrides or NONE>
BUDGET_STATE_REF=<durable pointer>
LAST_ACCEPTED_CHECKPOINT=<durable pointer>
CONTEXT_MODULES=<minimal routed context>
STOP_CONDITIONS=<hard stops>
```

The Profile loads defaults; the Goal supplies actual authority.

## Resume block

```text
LAST_ACCEPTED_CHECKPOINT=<pointer>
CURRENT_DELTA=<one new fact>
CURRENT_CONTROL_VECTOR=<A,B,P>
CURRENT_LAYER=<L>
BUDGET_STATE_REF=<pointer>
ALLOWED_MUTATION=<smallest surface or NONE>
UNCHANGED_BOUNDARIES=<non-goals>
NEXT_PROOF_VECTOR=<V,E,F,G>
HARD_STOP=<first new decision>
```

Do not copy the full chronology.

## Cycle Receipt

```text
CONTROL_VECTOR_BEFORE=<A,B,P>
LAYER_BEFORE=<L>
HYPOTHESIS=<sanitized>
OPERATION=<classified operation>
BUDGET_DOMAIN=<domain>
BUDGET_CONSUMED=<window/lifetime delta>
PROGRESS_EVENT=<P0-P3>
CONTROL_VECTOR_AFTER=<A,B,P>
LAYER_AFTER=<L>
STATE_CHANGED=<true|false>
```

## Gate Receipt

```text
proof_depth
execution_environment
cadence
criticality
exact_source_binding
changed_surface
command_graph_hash
runner_or_runtime_identity_class
claim_proved
claim_not_proved
path_filter_disposition
evidence_reused
evidence_reuse_basis
failure_class
failure_signature
```

Protected Receipts also bind prior state, target state, transaction state,
rollback status, and plan domain.

## Stop Receipt

```text
last_accepted_checkpoint
current_authority_class
current_elasticity_grade
current_progress_state
current_layer
budget_domain
window_consumed
window_cap
renewals_consumed
maximum_renewals
lifetime_consumed
lifetime_cap
failure_signature
state_changed
next_required_decision
top_level_disposition
```

## Completion and calibration Receipt

```text
baseline_id
profile
wave_or_goal_id
validation_vectors_used
budget_consumption_by_domain
p0_count
p1_count
p2_count
p3_count
first_pass_focused_gate
first_pass_canonical_gate
same_head_reruns
runner_corrections
duplicate_full_gate_count
owner_interruptions_due_to_budget
owner_interruptions_due_to_authority
protected_apply_count
rollback_count
rollback_verified
finalize_count
wall_clock_minutes
completion_state
```

Never record secrets, raw logs, private endpoints, credentials, cookies,
storage state, or protected evidence.
