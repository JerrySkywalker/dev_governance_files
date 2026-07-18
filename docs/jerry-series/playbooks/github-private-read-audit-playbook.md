# Private GitHub Read Audit Playbook

## Purpose

Define how to perform fresh remote verification for private GitHub repositories without exposing credentials or mutating state.

## Core distinction

```text
authenticated private read != GitHub mutation
```

Private repositories normally return `404` to anonymous requests. A fresh remote audit of PRs, branches, commits, and tags therefore requires authenticated read access.

## Allowed when explicitly authorized

- existing GitHub CLI authentication;
- existing Git HTTPS credential helper;
- read-only GitHub GET queries;
- pull request metadata reads;
- open PR listing;
- remote heads listing;
- remote tags listing;
- default branch commit reads.

## Not allowed

- interactive login;
- refreshing credentials;
- printing tokens;
- reading credential storage;
- printing Authorization headers;
- GitHub mutations;
- workflow reruns;
- creating, deleting, or updating refs;
- local ref updates solely for audit;
- production or runtime credential use.

## Evidence to record

Record only facts needed for audit:

```text
authenticated_read_available=true
repository_full_name
visibility=private
default_branch
pr_number
pr_state
pr_head_sha
merge_commit_sha
open_pr_count
remote_head_set
remote_tag_target_matrix
credential_content_read=false
credential_printed=false
github_mutations=0
local_git_ref_mutations=0
```

Do not record account email, token scopes, token values, credential locations, headers, or secrets.

## Recovery pattern

If anonymous private reads fail with 404:

1. Classify as `ANONYMOUS_PRIVATE_GITHUB_404`, not as missing repository evidence.
2. Persist the blocked report.
3. Obtain explicit owner authorization for authenticated private reads.
4. Use existing auth only.
5. Produce a superseding PASS report without overwriting the blocked report.
6. Preserve both reports in final receipts.

## Completion standard

A private-repository audit passes only when:

- authenticated reads are explicitly authorized;
- credential content is not read or printed;
- GitHub mutation count is zero;
- local Git ref mutation count is zero;
- remote branch and tag facts are freshly verified;
- product state before and after the audit is equal.
