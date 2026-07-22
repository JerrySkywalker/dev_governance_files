# Wave 7V Plan — Dual Dashboard Visual Validation Infrastructure

## 1. Purpose

Wave 7V is inserted between completed Wave 7A and planned Wave 7B.

Its purpose is to make human-visible browser validation a durable requirement for future cross-repository integration Waves.

The required sequence becomes:

```text
W7A complete
  -> W7V dual-channel visual-validation infrastructure
  -> W7B readiness-chain work
```

Wave 7V is not a product-feature Wave for Agent, Hub, Gateway, Android, or the production Dashboard. It is a controlled development and validation infrastructure Wave centered on `jerry-glance-dashboard` and the Beijing canary deployment surface.

## 2. Milestone

```text
M7V_DUAL_DASHBOARD_CHANNELS_READY
```

The milestone is reached only when:

- production Dashboard remains unchanged and healthy;
- an isolated canary Dashboard is deployed on Beijing;
- both public Dashboard routes are protected by Authelia;
- the canary route renders a generic Wave visual-validation section;
- the accepted W7A visual packet is visible on canary;
- local Codex performs authenticated Playwright screenshot validation against the cloud canary route;
- screenshots cover desktop and mobile-browser viewports;
- screenshots contain no secret or credential material;
- the owner performs a final human browser review;
- W7B remains not started.

## 3. Current known production topology

The repository target topology currently records:

```text
https://dashboard.jerryskywalker.space/
  -> 1Panel/OpenResty
  -> Authelia
  -> 127.0.0.1:18090
  -> jerry-glance-dashboard-glance-1
```

Known production properties:

- host alias: `beijing`;
- server directory: `/opt/jerry-glance-dashboard`;
- deployment mode: Glance config-only;
- server directory is not a Git worktree;
- no `git pull`, npm install, or application build is performed in production;
- the browser must never receive the Hub read token.

Historical or candidate ports requiring live classification include:

- `13080`;
- `13081`;
- `13082`;
- `18091`;
- `18092`.

No W7V mutation is allowed until a read-only live topology audit confirms their current ownership and use.

## 4. Target dual-channel topology

### 4.1 Production channel

Production remains:

```text
https://dashboard.jerryskywalker.space/
  -> Authelia-protected 1Panel/OpenResty site
  -> 127.0.0.1:18090
  -> current production Glance stack
```

W7V must not change:

- production DNS;
- production certificate;
- production site configuration;
- production Authelia policy;
- production upstream;
- production compose project;
- production configuration files;
- production Hub read token;
- production container lifecycle.

### 4.2 Canary channel

Preferred public route:

```text
https://dashboard-canary.jerryskywalker.space/
```

Preferred private backend topology, subject to live admission:

```text
dashboard-canary.jerryskywalker.space
  -> 1Panel/OpenResty
  -> Authelia
  -> 127.0.0.1:13082
  -> jerry-glance-dashboard-canary-glance

jerry-glance-dashboard-canary-glance
  -> private canary validation API
  -> 127.0.0.1:18092
```

Preferred server root:

```text
/opt/jerry-glance-dashboard-canary
```

Preferred compose project and container prefix:

```text
jerry-glance-dashboard-canary
jerry-glance-dashboard-canary-*
```

Canary ports must bind only to loopback. The validation API must never receive an independent public reverse proxy.

If `13082`, `18092`, or the preferred root is already owned by a coherent existing service, Wave 7V must stop for owner decision rather than replace or reuse it automatically.

## 5. 1Panel and Authelia boundary

The owner prefers 1Panel as the configuration surface for public reverse proxy management.

Therefore:

- Codex prepares exact 1Panel values and validation steps;
- Codex does not edit the production site;
- Codex does not silently write 1Panel site configuration files;
- the owner creates or confirms the canary site through 1Panel;
- the owner binds the canary certificate and reverse proxy;
- the owner applies the same Authelia protection class as production;
- Codex performs read-only verification afterward.

An owner-controlled manual gate is expected between canary backend deployment and public authenticated validation.

## 6. Visual-validation architecture

### 6.1 Production display

Production continues to show stable accepted telemetry and operations cards.

No experimental Wave packet is required on production.

### 6.2 Canary display

Canary must include a persistent visual section titled conceptually:

```text
Visual Validation / Integration Lab
```

The canary page must clearly display:

```text
CANARY
NOT PRODUCTION
```

It must also show:

- deployed repository SHA;
- deployment timestamp;
- channel identity;
- production affected: false;
- current visual packet Wave and milestone;
- packet source classification;
- human acceptance state.

### 6.3 Generic safe visual packet

Define a reusable contract:

```text
jerry.dashboard.validation.v1
```

Minimum fields:

```json
{
  "schema_version": "1",
  "channel": "canary",
  "wave_id": "W7A",
  "milestone": "M7A_CODEX_USAGE_CHAIN_GREEN",
  "status": "passed",
  "packet_kind": "accepted_synthetic_replay",
  "exact_shas": {},
  "stages": [],
  "visuals": {},
  "safety": {},
  "generated_at": "...",
  "human_visual_acceptance": "pending"
}
```

The packet must be allowlisted and must not contain:

- tokens;
- cookies;
- passwords;
- Authorization headers;
- raw telemetry payloads;
- subject identifiers;
- message IDs;
- account IDs;
- user IDs;
- email addresses;
- file-system secrets;
- raw logs;
- screenshots containing authenticated browser chrome or credential prompts.

### 6.4 W7A packet

The first canary packet is the accepted W7A replay.

It should render:

- four Hub usage windows;
- Agent-to-Hub pass;
- Hub-to-Gateway pass;
- Gateway-to-Android pass;
- semantic dedup pass;
- safe Gateway message title and preview;
- acknowledgement result;
- zero pending messages after acknowledgement;
- safety booleans;
- exact final product SHAs.

It must be labeled:

```text
Accepted synthetic replay
Not production telemetry
```

The live production Codex Usage card may remain present separately and must be labeled as live Hub read-model data.

## 7. Playwright cloud visual validation

Local Codex must use Playwright to validate the deployed authenticated canary route.

Required viewports:

- desktop wide;
- laptop;
- mobile portrait.

Required screenshots:

```text
artifacts/playwright/w7v-canary/desktop-wide.png
artifacts/playwright/w7v-canary/laptop.png
artifacts/playwright/w7v-canary/mobile-portrait.png
```

Required Playwright assertions:

- anonymous request is redirected or blocked by Authelia;
- authenticated page loads;
- canary banner is visible;
- production banner is absent;
- W7A milestone status is visible;
- four-window visual content is visible;
- Gateway safe message is visible;
- acknowledgement result is visible;
- post-ack pending count is zero;
- exact SHA marker is visible;
- production-affected false marker is visible;
- no secret markers appear in rendered DOM;
- no static Hub read token appears in browser network requests, HTML, JavaScript, or screenshots;
- no mixed-content request occurs;
- no request targets `18092` from the browser;
- screenshot files are non-empty and hash recorded.

The authenticated storage state remains a local secret and must not be committed, printed, uploaded, or embedded in screenshots.

Playwright screenshot evidence is required but does not replace owner human review.

## 8. Wave steps

### W7V-S01 — W7A closeout and live topology admission

Read-only admission must confirm:

- W7A final local checkpoint and report exist;
- W7A final product SHAs remain canonical;
- W7B has not started;
- production Dashboard route and backend are healthy;
- production OpenResty site still points to the expected backend;
- production Authelia protection remains active;
- candidate canary ports and roots are classified;
- existing containers using historical names are classified;
- DNS and certificate state for the preferred canary hostname is known;
- no mutation has occurred.

Admission outputs:

```text
PRODUCTION_DASHBOARD_TOPOLOGY_CONFIRMED
CANARY_BACKEND_PORT_CONFIRMED
CANARY_API_PORT_CONFIRMED
CANARY_ROOT_CONFIRMED
ONEPANEL_OWNER_GATE_REQUIRED
```

### W7V-S02 — Dashboard dual-channel source implementation

Primary write repository:

```text
V:\src\jerry-glance-dashboard
```

Implement the smallest coherent source delta for:

- explicit production/canary channel manifest;
- canary banner and metadata;
- generic validation packet schema and validator;
- canary validation API or existing safe API extension;
- W7A packet transformation from accepted local safe outputs;
- canary Glance configuration generation;
- isolated canary compose definition;
- deploy, stop, status, and preflight scripts;
- production-isolation guards;
- 1Panel manual configuration runbook;
- Playwright canary screenshot test;
- secret and browser-visible token checks.

One product writer only.

Use a normal feature branch, PR, exact-head CI, normal merge, and exact-main validation.

### W7V-S03 — Local visual and deployment-package validation

Required local checks:

- repository standard checks;
- generated production config parity;
- canary config rendering;
- local Docker canary render;
- W7A packet schema validation;
- desktop/laptop/mobile screenshots against local canary;
- screenshot inspection by a read-only visual Auditor;
- no secret markers;
- no product credential in browser-visible content;
- production config not changed unintentionally;
- package manifest and exact SHA binding;
- canary ports are loopback-only in compose.

The local validation must produce a deployment package without modifying Beijing.

### W7V-S04 — Isolated Beijing canary backend deployment

Only after admission and local acceptance, deploy to the exact accepted canary root, ports, compose project, and container prefix.

Allowed mutations are limited to the accepted canary scope.

Forbidden:

- production Dashboard directory;
- production upstream;
- production container restart;
- production Hub token change;
- 1Panel production site;
- Authelia global policy mutation outside the accepted canary entry;
- DNS changes by Codex;
- unrelated services;
- removal of historical candidates.

After deployment, verify loopback backend health and confirm production remains healthy.

### W7V-S05 — Owner-controlled 1Panel, DNS, certificate, and Authelia gate

Codex must stop with a concise owner action block containing the exact accepted values.

The owner performs through controlled administrative surfaces:

- DNS creation or confirmation for the canary hostname;
- 1Panel canary website creation;
- certificate binding;
- reverse proxy to the accepted canary backend;
- Authelia protection matching production.

Codex must not request raw credentials in chat or logs.

After owner completion, Codex resumes and verifies:

- DNS resolution;
- HTTPS certificate;
- anonymous Authelia protection;
- authenticated route;
- production route unchanged;
- validation API remains private.

### W7V-S06 — Cloud Playwright screenshots and human acceptance

Local Codex runs authenticated Playwright against the public canary route.

Required evidence:

- anonymous-block result;
- authenticated-load result;
- desktop screenshot;
- laptop screenshot;
- mobile screenshot;
- DOM assertion report;
- network-origin allowlist report;
- secret-marker report;
- screenshot SHA-256 values;
- production route regression check.

Codex then stops for final owner human visual review.

The owner reviews the canary page in a normal desktop or mobile browser and returns one of:

```text
W7V_HUMAN_VISUAL_ACCEPTED
W7V_HUMAN_VISUAL_REJECTED
```

Only acceptance permits W7V closeout.

## 9. Completion conditions

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

## 10. Evidence paths

Local checkpoint:

```text
V:\src\integration-inventory\repo-health\w7v-dual-dashboard-checkpoint.json
```

Compact report:

```text
V:\src\integration-inventory\repo-health\w7v-dual-dashboard-report.md
```

Optional logs:

```text
V:\src\integration-inventory\repo-health\w7v-dual-dashboard-logs\
```

Playwright screenshots remain in the Dashboard repository artifact path and are classified according to repository policy. Auth storage state remains excluded and secret.

## 11. Automatic recovery budget

Authorized routine recovery includes:

- local Node/npm/Playwright binding;
- Chromium installation inside normal repository tooling;
- local Docker canary cleanup;
- owned validation-root cleanup;
- safe package regeneration;
- repository-scoped runner recovery;
- safe fetch/prune;
- exact-ref reconciliation;
- CI waiting;
- canary-only compose restart;
- canary-only file transfer retry;
- screenshot retry for deterministic rendering or font timing.

Maximum product corrective budget:

- two corrective product commits;
- one additional test/deployment-harness-only corrective commit.

No recovery may cross into production, 1Panel owner actions, DNS, certificate private keys, Authelia credentials, or unknown legacy service mutation.

## 12. Stop conditions

Owner decision is required for:

- occupied preferred canary port or directory;
- ambiguous existing canary ownership;
- hostname selection;
- 1Panel administrative action;
- DNS action;
- certificate or Authelia policy action;
- corrective-budget extension;
- broader Dashboard product direction;
- final human visual acceptance.

Unsafe blocker is required for:

- secret exposure;
- production mutation;
- unknown server mutation;
- public exposure of the validation API;
- browser receipt of a Hub read token;
- force push or history rewrite requirement;
- inability to bind screenshots to exact deployed SHA;
- inability to prove production remained unaffected.

## 13. Non-goals

Wave 7V does not:

- start W7B;
- redesign the entire Dashboard;
- promote canary to production;
- change production Hub authentication;
- install Android applications;
- perform physical-phone validation;
- add a public API for validation packets;
- replace 1Panel as the reverse-proxy management surface;
- make Playwright screenshots the sole acceptance authority.
