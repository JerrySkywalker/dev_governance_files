# Workstation Manager P0.5 to P1A Interim Lessons

## Classification

```text
classification: retrospective
scope: sanitized interim governance lessons from the completed P0.5 milestone and in-progress P1A work
related_repositories:
  - workstation-manager
  - jerry-workstation-config
  - dev_governance_files
sensitivity_notes: durable outcomes only; no protected evidence, local paths, source payloads, or authentication material
```

## Capture-time state

```text
P0_5_DISTRIBUTION_MVP=COMPLETE
P1A_PRODUCT_IMPLEMENTATION=COMPLETE_LOCALLY
P1A_LOCAL_VALIDATION=PASS
P1A_CONFIG_COMPATIBILITY=PASS_6_OF_6
P1A_AUDIT_PACKET_METHOD=V3_PARITY_PASS
P1A_INDEPENDENT_AUDIT=NOT_STARTED_AT_CAPTURE_TIME
P1A_REMOTE_PR=NOT_CREATED_AT_CAPTURE_TIME
P1A_COMPLETE=false
```

This is an interim capture. It does not claim that P1A has been independently
audited, delivered through a remote pull request, or completed.

## Durable lessons

### 1. Audit tooling failures are not product findings

An Auditor process, packet-materialization method, evidence directory, or
result schema can fail before an independent content review begins. Preserve
that attempt, classify it as an audit-process problem, and avoid describing the
candidate as failing audit without an actual content finding.

### 2. Recovery counters must be domain-separated

Packet construction, independent Auditor processes, output schemas, content
corrections, CI reruns, and runner environment changes have different failure
and progress semantics. Combining them into one retry number obscures both
risk and remaining capacity.

### 3. Canonical Git-object bytes are the evidence source

Source review must bind to the candidate tree and canonical blob bytes.
Working-tree representations are not sufficient evidence when a platform can
apply line-ending, encoding, or filter transformations. The
[Canonical Git Object Audit Packet Playbook](../playbooks/canonical-git-object-audit-packet-playbook.md)
records the reusable method.

### 4. Commit count is a weak risk proxy

Risk is better represented by semantic scope, authority boundaries, candidate
generations, and validation coverage than by the number of commits. A small,
reviewable correction can require more evidence work than several coherent
documentation commits.

### 5. Owner-visible blockers should represent decisions

Owner-visible stops should identify an authority or safety decision, not an
ordinary tooling inconvenience that remains within a declared budget and has a
bounded corrective hypothesis.

### 6. Broad low-risk recovery still needs a tight no-progress stop

A Goal can safely allow several low-risk packet or process methods while
limiting identical failure signatures and no-progress cycles. This maintains
momentum without normalizing an unattended loop.

### 7. Current P1A work remains outside this public repository

The current P1A candidate and its local evidence remain outside this public
governance repository. This retrospective records reusable process lessons,
not source content, packet contents, or delivery status beyond the
capture-time state above.

## Non-goals

This retrospective does not authorize product changes, real execution,
package-manager application, workstation mutation, CI runner changes, or
publication of local evidence.
