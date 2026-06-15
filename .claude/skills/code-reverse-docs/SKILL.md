---
name: code-reverse-docs
description: Reverse-engineer a source code repository into comprehensive technical documentation — architecture overview, per-feature detailed design, and inferred non-functional requirements — output as a structured set of markdown files with diagrams and a traceability matrix. Use this skill whenever the user wants to "document an existing codebase", "reverse engineer", "create architecture docs from code", "produce design documentation", "understand a legacy system", "onboard onto a codebase", or asks for SAD / HLD / LLD / SDD / TDD / "design doc" / "architecture doc" generated from source. Trigger even when the user only mentions one piece (e.g. "extract the architecture", "what are the NFRs of this system", "write a design doc for this module") — those are partial requests for the same workflow.
---

# Code Reverse-Engineering to Documentation

This skill turns a source code repository into a structured documentation set covering architecture, detailed design, and non-functional requirements (NFRs). The output is a directory of markdown files with Mermaid diagrams and a traceability matrix.

## Core principle

Reverse-engineering documentation has a failure mode: producing prose that _describes the code line by line_ instead of _explaining the system_. Good design docs answer "why" and "how the pieces fit", not "what each line says". When in doubt, ask: would a new engineer joining the team find this useful, or is it just a verbose `ls`? If it's the latter, cut it.

The other failure mode is fabrication. If the code doesn't reveal something (e.g. SLAs, intended scale, business reasoning), say so explicitly rather than inventing it. Mark inferences as **Inferred** and clearly separate them from **Observed** facts.

## Workflow

Follow these phases in order. Each phase has a dedicated reference file with the deep methodology — read it when you reach that phase.

### Phase 0 — Setup

1. Confirm with the user: the codebase location, the output location, and the depth (full vs architecture-only vs single-module).
2. Create the output directory structure (see `references/output-structure.md`).
3. If the codebase is large (>500 files or >100k LOC), plan to sample rather than read every file — read `references/sampling-strategy.md`.

### Phase 1 — Inventory & landscape

Goal: know what's in the repo before interpreting anything.

Produce `01-inventory.md` covering: languages and their LOC share, frameworks and major libraries, build/package manifests, entry points (main functions, server bootstraps, CLI commands, lambda handlers, cron jobs), test layout, CI/CD configuration files, infrastructure-as-code, and a top-level directory map with one-line purposes.

Use `scripts/inventory.sh` to bootstrap this — it runs cloc, finds manifest files, locates entry points, and emits a starter markdown. Edit, don't just paste.

Read `references/inventory.md` for what counts as an entry point in different stacks and how to spot framework conventions.

### Phase 2 — Architecture recovery

Goal: the C4-style view of the system. Read `references/architecture.md` before starting.

Produce these files, in this order:

- `02-architecture/01-context.md` — System Context (C4 L1). Who/what does the system interact with? Users, external systems, third-party APIs. One Mermaid diagram + prose.
- `02-architecture/02-containers.md` — Containers (C4 L2). Deployable/runnable units: services, databases, queues, caches, frontends, workers. Tech stack per container. Mermaid diagram showing inter-container communication with protocols (HTTP/gRPC/AMQP/etc.).
- `02-architecture/03-components.md` — Components (C4 L3). Inside each container, the major modules/packages and their responsibilities. One section per container.
- `02-architecture/04-data.md` — Data architecture. Database schemas (recover from migrations or ORM models), key entities and relationships (ER diagram), data flow, persistence boundaries, caching layers.
- `02-architecture/05-deployment.md` — Deployment view. Recover from Dockerfiles, docker-compose, Kubernetes manifests, Terraform, GitHub Actions, etc. If nothing's there, say so.
- `02-architecture/06-cross-cutting.md` — Cross-cutting concerns: authentication/authorization mechanism, configuration management, error handling strategy, logging, request tracing, feature flags.

### Phase 3 — Feature catalog

Goal: list every user-facing capability and trace each one to code. Read `references/features.md`.

Produce `03-features/00-catalog.md` — a table of features (name, brief description, primary entry point, primary modules). Discover features by looking at:

- HTTP routes / GraphQL resolvers / RPC handlers
- CLI commands
- UI navigation (routes, pages, screens)
- Scheduled jobs and event consumers
- Public SDK / library exports

Group related routes/handlers into one feature where it makes sense (e.g. all `/api/orders/*` → "Order management"). Don't enumerate every endpoint as its own feature.

### Phase 4 — Detailed design per feature

Goal: a design doc per feature. For each feature in the catalog, produce `03-features/<NN>-<slug>.md` using the template in `templates/feature-design.md`.

Each feature doc contains: overview, user-facing behavior, entry points (with file:line refs), sequence diagram (Mermaid), data model touched, key algorithms or business rules, error paths, dependencies on other features/services, and known limitations visible in the code (TODO/FIXME comments, commented-out branches, feature flags).

Read `references/detailed-design.md` for how deep to go and how to draw useful sequence diagrams (not "user clicks button, server responds" — actual decision branches).

### Phase 5 — Non-functional requirements

Goal: extract NFRs from what the code actually does, separating **observed** from **inferred**. Read `references/nfrs.md`. Produce `04-nfrs/<NN>-<category>.md` for each of:

- Security (authN/authZ, crypto usage, secret management, input validation, CSRF/CORS, dependency scanning)
- Performance (caching, async/queueing, database indexes, N+1 patterns, rate limiting)
- Scalability (statelessness, horizontal scaling readiness, data partitioning, queue-based decoupling)
- Reliability & availability (retries, timeouts, circuit breakers, health checks, graceful shutdown, idempotency)
- Observability (logs, metrics, traces, error reporting, alerting hooks)
- Maintainability (test coverage signals, lint config, documentation density, code duplication, module coupling)
- Compatibility & portability (runtime versions, OS assumptions, browser support if frontend)
- Compliance & privacy (PII handling, GDPR signals, audit logging, retention)

For every NFR claim, cite the evidence (file:line or config snippet). If a category has no evidence in the code, write "**No evidence found.** Confirm with team whether this is unimplemented or handled outside the repo."

### Phase 6 — Traceability matrix

Produce `05-traceability.md`: a table mapping Feature ↔ Code modules ↔ NFRs touched. This is the document that makes the whole set useful for impact analysis. See `templates/traceability.md` for the format.

### Phase 7 — Executive summary & index

Produce `00-README.md` as the entry point: 1-page summary, system purpose (inferred if not stated), high-level architecture diagram, link tree to all other docs, and a "How to read this documentation" section (suggested order for different audiences: new engineer, architect reviewer, security auditor, ops).

## Evidence and honesty rules

- **Cite the source.** Every non-trivial claim links to a file path, ideally with a line range: `\`src/auth/jwt.ts:42-58\``. The reader must be able to verify.
- **Label inference.** Use `[Observed]` for what's directly in the code, `[Inferred]` for what's deduced, `[Unknown]` for gaps. Never silently guess.
- **Don't invent business context.** If the code is a payments service but never says what business it serves, don't make up "FinTech startup focused on B2B payments". Just say it's a payments service.
- **Flag risks, don't paper over them.** Hardcoded secrets, missing auth on endpoints, SQL string concatenation, missing input validation, panic-on-error patterns — these go in the NFR docs with severity tags. The documentation's job is to be useful, including uncomfortably useful.
- **Quote sparingly.** Code snippets are fine and encouraged for illustration; full-file dumps are not. Show the 5 lines that matter.

## Diagrams

Use Mermaid for all diagrams (it renders inline in markdown on GitHub, GitLab, VS Code, and most viewers). Required diagram types:

- **C4 context + container**: `flowchart TD` or `graph LR` with subgraphs
- **Sequence diagrams** (per feature): `sequenceDiagram`
- **ER diagrams** (data model): `erDiagram`
- **State diagrams** (if the feature has a clear state machine): `stateDiagram-v2`
- **Deployment**: `flowchart` with subgraphs for environments/clusters

Keep diagrams under ~15 nodes each. If you need more, split into multiple diagrams.

## Output structure (final shape)

```
<output-dir>/
├── 00-README.md
├── 01-inventory.md
├── 02-architecture/
│   ├── 01-context.md
│   ├── 02-containers.md
│   ├── 03-components.md
│   ├── 04-data.md
│   ├── 05-deployment.md
│   └── 06-cross-cutting.md
├── 03-features/
│   ├── 00-catalog.md
│   ├── 01-<feature-slug>.md
│   ├── 02-<feature-slug>.md
│   └── ...
├── 04-nfrs/
│   ├── 01-security.md
│   ├── 02-performance.md
│   ├── 03-scalability.md
│   ├── 04-reliability.md
│   ├── 05-observability.md
│   ├── 06-maintainability.md
│   ├── 07-compatibility.md
│   └── 08-compliance.md
└── 05-traceability.md
```

## When to deviate

- **Architecture-only request**: skip phases 3, 4, 6. Keep 1, 2, 5, 7.
- **Single feature/module request**: skip phase 2 (or compress to one file). Focus phases 3, 4 on the named scope.
- **Library/SDK (no user-facing features)**: replace phase 3 "user-facing features" with "public API surface" — each exported function/class is a feature.
- **Monorepo with multiple services**: produce one output tree per service, plus a top-level `00-monorepo-overview.md`.

## Reference files

Reach for these as each phase comes up — don't pre-load them all:

- `references/inventory.md` — Phase 1 detail
- `references/architecture.md` — Phase 2 detail (C4 specifics, framework-to-component mapping)
- `references/features.md` — Phase 3 detail (how to discover features per stack)
- `references/detailed-design.md` — Phase 4 detail (sequence diagrams, depth calibration)
- `references/nfrs.md` — Phase 5 detail (what evidence to look for per NFR category)
- `references/sampling-strategy.md` — for large codebases
- `references/output-structure.md` — full file layout spec

Templates (copy and fill, don't reinvent):

- `templates/feature-design.md`
- `templates/nfr-section.md`
- `templates/traceability.md`
- `templates/readme.md`

Scripts:

- `scripts/inventory.sh` — bootstrap Phase 1
- `scripts/find-entry-points.sh` — find route definitions, CLI handlers, main functions across common stacks
