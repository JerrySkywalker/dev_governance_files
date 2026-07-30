# Playbook Agent Instructions

```text
CONTEXT_CLASS=CONDITIONAL_OPERATIONAL
```

Read only the Playbook matching the current task, environment, and Harness layer.
Playbooks do not create authority. Execute a command only when the current Goal
scope, authority, budget, and proof vector allow it. Numeric limits come from
`config/repo-health-harness-v1.json`, not from copied prose.
