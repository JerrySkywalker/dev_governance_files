# Wave 7V Execution Orchestrator

## Identity

```text
GOAL_ID=COMPLETE-WAVE-7V-DUAL-DASHBOARD-VISUAL-VALIDATION
WAVE=W7V
MILESTONE=M7V_DUAL_DASHBOARD_CHANNELS_READY
```

This orchestrator uses the Wave 6 execution model required by JD-0002.

It is a single top-level Goal with checkpointed resume. It executes internal phases automatically and stops only for an owner-controlled gate, an owner decision, or an unsafe blocker.

## Authoritative inputs

- `docs/jerry-series/plans/wave-7v-dual-dashboard-visual-validation-plan.md`
- `docs/jerry-series/retrospectives/wave-7a-lessons.md`
- `docs/jerry-series/decisions/JD-0002-current-repository-health-train-keeps-wave-6-execution-model.md`
- applicable repository `AGENTS.md` and local instructions
- current exact production and canary topology discovered at runtime

## Checkpoint and report

```text
V:\src\integration-inventory\repo-health\w7v-dual-dashboard-checkpoint.json
V:\src\integration-inventory\repo-health\w7v-dual-dashboard-report.md
```

Optional logs:

```text
V:\src\integration-inventory\repo-health\w7v-dual-dashboard-logs\
```

## Product repository

Primary product write repository:

```text
V:\src\jerry-glance-dashboard
```

Governance is already written before execution. Product code, deployment tooling, local evidence, server mutations, screenshots, and Git operations remain local-Codex work.

## State machine

```text
ADMISSION
  -> W7V-S01 live topology admission
  -> W7V-S02 dual-channel source implementation
  -> W7V-S03 local visual and package validation
  -> W7V-S04 isolated Beijing canary backend deployment
  -> W7V-S05 owner-controlled 1Panel/DNS/certificate/Authelia gate
  -> W7V-S06 cloud Playwright and human visual acceptance
  -> FINAL AUDIT
```

Do not start W7B.

## Resume behavior

When the checkpoint exists:

1. read it;
2. revalidate the governance commit, repository SHAs, local and remote refs, PR state, writer lock, server topology, canary ownership, validation roots, child processes, listeners, screenshots, and evidence dispositions;
3. reject or supersede stale claims;
4. resume from the last independently proven phase.

Do not trust a completion flag without exact-state revalidation.

## ADMISSION

### Governance

Verify the synchronized governance repository contains the W7V plan and orchestrator and marks:

```text
W7A=COMPLETED
M7A=ACHIEVED
W7V=READY_NOT_STARTED
W7B=PLANNED_NOT_STARTED
```

### W7A evidence

Verify the final local W7A checkpoint, report, operator demo, and closeout facts exist.

Verify W7A final exact product SHAs remain canonical.

### Dashboard repository

Inventory:

- repository identity;
- local and remote main;
- default branch;
- upstream;
- worktrees;
- branches;
- PRs;
- stashes;
- Git-operation markers;
- applicable instructions;
- current CI and runner state.

Stop for ambiguous unique history.

### Tooling

Preflight:

- PowerShell;
- Git;
- Node and npm;
- Docker;
- Playwright and Chromium;
- SSH alias `beijing`;
- safe local validation roots;
- local authenticated Playwright storage-state availability without printing it.

Do not capture or refresh authenticated state until needed.

## W7V-S01 — Live topology admission

Perform read-only checks against Beijing.

Inspect only metadata necessary to classify:

- production Dashboard site and upstream;
- production backend port;
- production directory and compose project;
- current Authelia protection;
- current containers and loopback listeners related to Dashboard;
- candidate ports `13080`, `13081`, `13082`, `18091`, `18092`;
- candidate directories under `/opt` related to Dashboard;
- 1Panel site presence for production and preferred canary hostname;
- DNS and certificate state for the preferred canary hostname.

Do not print secrets, environment files, cookies, tokens, private keys, or raw 1Panel credentials.

Classify every candidate as:

```text
PRODUCTION
LEGACY_ROLLBACK
OWNED_CANARY_AVAILABLE
OWNED_CANARY_EXISTING
UNRELATED_OWNED_SERVICE
UNKNOWN_OWNER_DECISION_REQUIRED
FREE
```

Require exact accepted canary scope before writes:

```text
CANARY_HOSTNAME
CANARY_ROOT
CANARY_GLANCE_PORT
CANARY_API_PORT
CANARY_COMPOSE_PROJECT
CANARY_CONTAINER_PREFIX
```

Preferred defaults are permitted only when proven free or already coherently owned:

```text
dashboard-canary.jerryskywalker.space
/opt/jerry-glance-dashboard-canary
127.0.0.1:13082
127.0.0.1:18092
jerry-glance-dashboard-canary
jerry-glance-dashboard-canary-
```

When any preferred object is occupied ambiguously, stop with `W7V_OWNER_DECISION_REQUIRED`.

Record production anchors that must remain unchanged.

## W7V-S02 — Source implementation

Use one product writer.

Create a normal feature branch.

Implement the smallest coherent source delta required by the W7V plan.

Required source outcomes:

- explicit channel manifest;
- canary banner and metadata;
- generic `jerry.dashboard.validation.v1` packet schema;
- strict validator and redaction;
- W7A packet generator from accepted local safe outputs;
- canary validation API or safe extension of the existing API surface;
- canary Glance config generation;
- isolated canary compose definition bound to accepted loopback ports;
- preflight, package, deploy, check, stop, and production-isolation scripts;
- 1Panel manual setup runbook;
- anonymous and authenticated canary smoke scripts;
- cloud Playwright screenshot test for desktop, laptop, and mobile;
- screenshot secret scan and network-origin audit;
- production parity guard.

Do not change production content unless a shared generator change is necessary and the generated production output remains byte-equivalent or the exact intentional difference is separately reviewed.

Run focused tests, repository checks, secret scans, and parser checks.

Open a normal PR.

Require exact-head CI and read-only review.

Merge normally and validate exact main.

Retire merged feature refs safely.

## W7V-S03 — Local visual validation

Create a fresh owned validation root.

Build a local canary package using exact main.

Run local canary services only on loopback dynamic or accepted development ports.

Feed the accepted W7A safe visual packet.

Run Playwright at:

- desktop wide;
- laptop;
- mobile portrait.

Require local screenshots and assertions:

```text
CANARY_BANNER_VISIBLE=true
PRODUCTION_BANNER_VISIBLE=false
W7A_MILESTONE_VISIBLE=true
W7A_FOUR_WINDOWS_VISIBLE=true
W7A_GATEWAY_MESSAGE_VISIBLE=true
W7A_ACK_VISIBLE=true
W7A_POST_ACK_EMPTY_VISIBLE=true
SECRET_MARKER_COUNT=0
BROWSER_HUB_TOKEN_VISIBLE=false
BROWSER_VALIDATION_API_PUBLIC_URL_USED=false
```

Use one native direct read-only visual Auditor to inspect screenshots for clipping, overlap, unreadable mobile layout, incorrect channel labeling, missing status markers, and accidental secret exposure.

Package the exact accepted server artifact and write a manifest with file hashes, repository SHA, accepted topology, and deployment scope.

Do not deploy until local acceptance is complete.

## W7V-S04 — Isolated Beijing canary backend deployment

Revalidate production anchors and canary ownership immediately before mutation.

Allowed server write scope is limited to the accepted canary root and canary compose project.

Use a two-phase deployment:

### Prepare

- upload package to a new staging directory under the canary root or canary backup root;
- verify manifest and hashes;
- verify compose config;
- verify loopback port bindings;
- verify no production path or container appears in the mutation plan;
- return a prepare receipt.

### Apply

- require the exact prepare receipt;
- backup only existing owned canary content;
- atomically install the accepted package;
- start or recreate only accepted canary containers;
- verify loopback Glance and private API health;
- verify production backend and public route remain healthy;
- verify no 1Panel, DNS, certificate, or Authelia mutation occurred.

Do not expose the validation API publicly.

Do not switch production.

After backend success, record:

```text
CANARY_BACKEND_DEPLOYED=true
CANARY_PUBLIC_ROUTE_READY=false
OWNER_ONEPANEL_GATE_REQUIRED=true
```

## W7V-S05 — Owner-controlled public route gate

Stop with `W7V_OWNER_ACTION_REQUIRED`.

The block must contain only safe values:

- canary hostname;
- 1Panel site type;
- reverse-proxy upstream;
- HTTPS requirement;
- Authelia protection requirement;
- validation API non-public requirement;
- expected anonymous result;
- expected authenticated result;
- resume instruction.

Do not include credentials, cookies, tokens, or private keys.

The owner performs through 1Panel and the relevant DNS/certificate/Authelia administrative surfaces:

- create or confirm canary DNS;
- create or confirm canary 1Panel site;
- bind certificate;
- set reverse proxy to accepted loopback Glance backend;
- apply the production-equivalent Authelia protection;
- leave the private API without a public site.

After owner confirmation, resume and perform read-only verification.

Require:

```text
CANARY_DNS_OK=true
CANARY_HTTPS_OK=true
CANARY_ANONYMOUS_BLOCKED=true
CANARY_AUTHENTICATED_LOAD_READY=true
PRODUCTION_ROUTE_UNCHANGED=true
CANARY_API_PUBLICLY_EXPOSED=false
```

## W7V-S06 — Cloud Playwright visual acceptance

Use local Playwright against the public canary HTTPS route.

The local authenticated storage state is secret. Never print, commit, upload, or include it in an artifact.

Run anonymous validation first.

Then run authenticated screenshots for:

- desktop wide;
- laptop;
- mobile portrait.

Required assertions:

- canary banner visible;
- production badge absent;
- W7A card visible;
- four-window section visible;
- Gateway safe message visible;
- acknowledgement state visible;
- post-ack pending count zero;
- exact deployed SHA visible;
- production affected false visible;
- no secret markers in DOM;
- no browser-visible Hub token;
- no request to the private API host port from the browser;
- only accepted public origins and static assets used;
- no mixed-content error;
- screenshots non-empty.

Save:

```text
artifacts/playwright/w7v-canary/desktop-wide.png
artifacts/playwright/w7v-canary/laptop.png
artifacts/playwright/w7v-canary/mobile-portrait.png
artifacts/playwright/w7v-canary/visual-report.md
artifacts/playwright/w7v-canary/network-report.json
```

Compute screenshot hashes.

Use one native direct read-only visual Auditor to inspect the screenshots.

Then stop with `W7V_HUMAN_VISUAL_REVIEW_REQUIRED` and provide the public canary URL plus a concise checklist.

The owner must respond with:

```text
W7V_HUMAN_VISUAL_ACCEPTED
```

or:

```text
W7V_HUMAN_VISUAL_REJECTED
<reason>
```

A rejection returns to the owning product phase within the corrective budget.

## FINAL AUDIT

After human acceptance, use:

- one read-only data/security Auditor;
- one read-only deployment/evidence Auditor;
- one fresh Supervisor.

Auditor A verifies:

- packet allowlist;
- W7A visual accuracy;
- live-versus-synthetic labels;
- browser token boundary;
- Playwright assertions;
- screenshot safety.

Auditor B verifies:

- exact repository and deployed SHAs;
- PR and CI state;
- server mutation scope;
- production invariance;
- canary ownership;
- 1Panel public route result;
- private API isolation;
- evidence dispositions;
- process, listener, and artifact cleanup.

Supervisor independently recomputes the W7V milestone.

## Automatic recovery

Keep routine recovery inside the same Goal.

Authorized recovery:

- process-scoped Node/npm/Playwright repair;
- Playwright Chromium installation;
- local Docker cleanup;
- screenshot timing stabilization;
- package regeneration;
- safe fetch/prune;
- runner recovery;
- CI waiting;
- canary-only upload retry;
- canary-only compose restart;
- authenticated storage-state expiry classification and owner recapture request;
- deterministic screenshot retry.

Maximum product budget:

```text
planned implementation commits: coherent minimum
corrective product commits: 2
additional test/deployment-harness corrective commits: 1
```

## Absolute prohibitions

Never:

- modify or restart production Dashboard;
- modify production 1Panel site;
- switch production upstream;
- alter production DNS or certificate;
- expose the private validation API publicly;
- print or commit Hub tokens;
- print or commit Playwright auth state;
- embed credentials in screenshots;
- mutate unrelated Beijing services;
- use force push or history rewrite;
- start W7B.

## Blocker contracts

### Owner action

Use `W7V_OWNER_ACTION_REQUIRED` for the planned 1Panel/DNS/certificate/Authelia step.

### Owner decision

Use `W7V_OWNER_DECISION_REQUIRED` for ambiguous ownership, port conflicts, hostname decisions, corrective-budget extension, or product-direction ambiguity.

### Unsafe blocker

Use `W7V_UNSAFE_BLOCKER` for secret exposure, production mutation, unknown server mutation, public API exposure, screenshot/source-state mismatch, force/history rewrite requirement, or inability to prove production invariance.

Every blocker must include:

```text
BLOCKED_STEP
BLOCKED_PHASE
BLOCKER_TEXT
EXACT_AFFECTED_SCOPE
CURRENT_SAFE_STATE
OPTIONS
RECOMMENDED_OPTION
MUTATIONS_ALREADY_COMPLETED
MUTATIONS_NOT_PERFORMED
CHECKPOINT_PATH
RESUME_INSTRUCTION
```

## Success output

On final success output only:

```text
W7V_COMPLETE
M7V_DUAL_DASHBOARD_CHANNELS_READY=true
PRODUCTION_DASHBOARD_UNCHANGED=true
PRODUCTION_DASHBOARD_HEALTHY=true
CANARY_DASHBOARD_DEPLOYED=true
CANARY_AUTH_PROTECTED=true
CANARY_VALIDATION_API_PRIVATE=true
W7A_VISUAL_PACKET_VISIBLE=true
PLAYWRIGHT_DESKTOP_SCREENSHOT_PASS=true
PLAYWRIGHT_LAPTOP_SCREENSHOT_PASS=true
PLAYWRIGHT_MOBILE_SCREENSHOT_PASS=true
PLAYWRIGHT_SECRET_SCAN_PASS=true
HUMAN_VISUAL_ACCEPTED=true
W7B_NOT_STARTED=true
READY_FOR_W7B_ANALYSIS
```
