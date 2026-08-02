# Condition-Matched Independent Audit Launch Playbook

## Classification

```text
classification: playbook
scope: goal-authorized independent read-only audit launches
related_repositories:
  - dev_governance_files
sensitivity_notes: retain sanitized receipts only; never persist credentials, raw private evidence, or complete environment data
```

## Purpose

Launch an independent Auditor only after the packet, response schema, CLI contract,
and session lifecycle have passed the same condition-matched admission checks that
the real launch will use. This Playbook does not create launch authority or supply
numeric limits; the active Goal and selected Harness Profile remain authoritative.

Use it after a self-contained packet has been prepared and sealed. For canonical
Git-object materialization, first apply
`canonical-git-object-audit-packet-playbook.md`.

## Pre-launch admission

Before starting an independent process:

1. Bind the packet to the exact candidate or exact-main commit and tree. Recheck
   every sealed file hash, the allowed read root, and the empty results directory.
2. Record one launch contract containing the executable, role profile, sandbox,
   approval policy, working directory, feature isolation, output schema, result
   path, and exact start message.
3. Render the model-visible prompt with the same global CLI arguments and exact
   start message by using a no-model diagnostic command. Do not persist raw prompt
   input; retain only a sanitized summary and hashes.
4. Verify every launch-specific CLI option against the installed CLI. A diagnostic
   subcommand may support fewer options than the execution subcommand, so keep the
   common global arguments identical and validate execution-only options separately.
5. Validate the output schema against the installed Codex structured-output subset.
   Every schema node must carry an explicit `type`; every object must be closed and
   require all declared properties. Prefer the smallest supported keyword set.
6. Run a positive output fixture and at least one negative fixture. When resuming
   from a schema rejection, reproduce that exact sanitized failure signature before
   accepting the corrected schema.
7. Require a recordable, resumable session when the Goal needs recovery. Omit
   ephemeral mode; an ephemeral session that fails before model execution cannot be
   assumed resumable.
8. Recheck that the candidate, remote binding, packet manifest, and results directory
   remain unchanged immediately before launch.

Admission diagnostics are not independent audits. They must not read product content
through an Auditor model or consume an `audit_launch` unit.

## Launch accounting

An `audit_launch` unit is consumed when the independent process starts, even if the
API rejects its response schema before the model reads the packet. A parser failure
that prevents process creation is not a launch. Never decrement lifetime history.

Use Goal-declared names for every allowed launch. A contingency launch is eligible
only when all of these are true:

- the primary failed before reading candidate or remote content;
- the failure is a new deterministic packet, parser, or schema admission defect;
- a bounded packet correction produced `P2` and invalidated the affected seal;
- the candidate and remote state were untouched; and
- the same sanitized failure signature has not appeared twice.

The second occurrence of the same signature is not progress and must stop automatic
launching. Do not turn an unused launch name or renewal into permission for another
independent review.

## Result handling

Validate the final result against the same sealed schema and recheck every non-result
packet hash. Preserve the process exit, session identifier, result digest, and the
technical/formal disposition separately.

If every product and integrity Gate passes but an unavoidable, already documented
Codex skill or control-plane instruction prevents formal isolation, record technical
PASS, formal clean audit false, and the documented exception class. Do not convert
that class into a product finding, and do not launch another Auditor merely to seek a
cleaner label.

A later successful launch never erases the initial rejection, process start, consumed
budget, or failure signature. Retain both events in the Train history.

## Non-goals

This Playbook does not authorize product writes, new repositories, network access,
credentials, runner repair, protected runtime access, numeric budget changes, or a
replacement Auditor outside the current Goal.
