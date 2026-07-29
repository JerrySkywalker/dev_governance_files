# Canonical Git Object Audit Packet Playbook

## Classification

```text
classification: playbook
scope: self-contained source-review packets for frozen Git candidates
related_repositories:
  - dev_governance_files
sensitivity_notes: use sanitized receipts only; exclude sensitive material and protected evidence
```

## Purpose

Create a self-contained review packet whose source files are bound to canonical
Git blob bytes instead of a potentially transformed working tree. The packet
lets an independent Auditor inspect a frozen candidate without Git, network,
worktree, or credential access.

## Canonical-byte method

Use this sequence for each base and candidate tree:

```text
git ls-tree -r --full-tree
  +
one persistent git cat-file --batch process
  +
exact raw blob-length reads
  +
tree/blob parity receipts
  +
bounded audit navigation
  +
sealed packet manifest
```

1. Enumerate the complete tree with `git ls-tree -r --full-tree`.
2. Send the required object requests to one persistent `git cat-file --batch`
   process.
3. For every response, require object type `blob`, read exactly the declared
   byte length, and validate the separator before the next response.
4. Materialize each path from those exact raw bytes and verify it with
   `git hash-object --no-filters`.
5. Record per-path object identity, byte count, materialized digest, and parity
   result in a tree/blob receipt.
6. Include a complete candidate patch and a bounded navigation index that names
   changed files and only the necessary unchanged context.
7. Hash every packet file into an immutable manifest before the Auditor starts.

## Why canonical blobs are required

On Windows, working-tree, archive, or checkout materialization can differ from
Git object bytes because line-ending conversion, text encoding, smudge or clean
filters, export attributes, and checkout behavior may transform files. A
packet assembled from transformed bytes cannot prove that an Auditor reviewed
the candidate tree that will be committed.

Treat the tree and blob map as authoritative. A textual diff may have a
different presentation digest when formatting or line-ending rendering differs;
it is equivalent only when its base tree, candidate tree, changed paths, and
per-path blob identities are proven identical.

## Required parity gates

Before an Auditor process starts, require:

```text
blob mismatch count=0
missing path count=0
unexpected path count=0
short/long read count=0
non-blob object count=0
sensitive marker scan=PASS
```

Also reject duplicate paths, path traversal, absolute paths, and materialized
paths that escape the packet root. Preserve incomplete packet attempts as
historical evidence; create a new numbered packet only after a concrete method
or process correction.

## Packet contents

At minimum, include:

- the owner authorization, audit scope, and strict result schema;
- base and candidate tree identifiers plus changed-path and blob maps;
- complete materialized base and candidate sources for the review scope;
- the complete patch and its digest;
- architecture, safety, and validation receipts needed to interpret the patch;
- a bounded navigation index; and
- a sealed packet manifest containing each relative path, byte count, digest,
  and classification.

The Auditor may write only its named output inside the packet. It must not need
to traverse the source repository, inspect a product worktree, or contact a
network service.

## Safety boundary

Do not include authentication material, private source payloads, protected
evidence, complete environment exports, or personal data. Use repository-
relative paths and sanitized classifications. An access or packet failure is an
evidence-process result, not a finding against candidate content.

## Result handling

Only a structured content review may produce `PASS` or findings. A malformed
schema, unavailable packet, or process interruption consumes only its own
domain budget. It must be classified, corrected within the declared envelope,
and followed by a freshly sealed packet and independent process.

## Non-goals

This playbook does not authorize source changes, evidence publication, or
replacement of the repository's exact-head and exact-main acceptance gates.
