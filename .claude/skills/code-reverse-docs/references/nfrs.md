# Reference: Non-Functional Requirements (Phase 5)

NFRs are the easiest section to bullshit and the easiest section to make truly valuable. The difference is **evidence**. Every claim about an NFR has a citation, or it's marked `[Inferred]` or `[Unknown]`.

## Format for every NFR doc

Each `04-nfrs/<NN>-<category>.md` follows this shape:

```markdown
# <Category>

## Summary
1-paragraph summary of how the system handles this NFR category overall.

## Observed mechanisms
Concrete things the code does, with citations.

## Gaps and risks
What's missing, weak, or inconsistent.

## Open questions
Things that need confirmation from the team.
```

Use `templates/nfr-section.md` to keep the shape consistent.

## What to look for in each category

### Security

**AuthN — authentication**

- How are users identified? Sessions, JWTs, OAuth, API keys, mTLS?
- Where is the credential checked? (middleware location)
- Password storage: bcrypt/argon2/scrypt? Salting? Iteration count?
- JWT specifics: algorithm (RS256 vs HS256), expiry, refresh strategy, secret source
- MFA/2FA presence
- Rate limiting on auth endpoints

**AuthZ — authorization**

- Role/permission model: hardcoded checks? RBAC table? ABAC?
- Where are authz checks enforced? (Look for guards, decorators, manual `if (user.role !== 'admin')` checks — the *inconsistency* of these is itself a finding.)
- Multi-tenancy: how is tenant isolation enforced? (This is the #1 silent vulnerability.)

**Crypto**

- TLS termination location (in the app? at the proxy/LB?)
- Symmetric encryption: algorithm + key source
- Hashing for non-password data (HMACs for signed URLs, etc.)
- Random number generation: cryptographic (`crypto.randomBytes`, `secrets`) vs not (`Math.random`)?

**Secrets**

- Env vars? Secret manager (Vault, AWS SM, Doppler)? In `.env.example`?
- Any hardcoded secrets, API keys, or default passwords? **This is a finding to flag prominently.**
- `.gitignore` covers `.env`?

**Input validation**

- Schema validation library: Zod, Joi, Pydantic, class-validator, json-schema?
- Where applied: on every endpoint, or sporadic?
- SQL: parameterized queries? ORM? Or string concatenation? **String concatenation = SQLi risk. Flag.**
- Command execution: `child_process.exec` with user input? Flag.

**Web concerns (if applicable)**

- CSRF protection
- CORS config (overly permissive `*`?)
- Content Security Policy
- HTTP security headers (helmet middleware, etc.)
- Cookie flags (Secure, HttpOnly, SameSite)

**Dependency scanning**

- `.snyk`, Dependabot config, `npm audit` in CI? `safety` for Python?

### Performance

- **Caching**: in-process (Caffeine, lru-cache), distributed (Redis, Memcached). Where? With what TTLs?
- **DB indexes**: scan migrations for `CREATE INDEX`. Compare to query patterns — any obvious missing indexes?
- **N+1 patterns**: ORM access inside loops. Search for `forEach`/`map`/`for` enclosing repository calls.
- **Async / queueing**: which operations are pushed off the request path?
- **Pagination**: does list endpoints paginate, or return everything?
- **Rate limiting**: per-route, per-user, global?
- **Connection pooling**: DB pool size config, HTTP keep-alive
- **Compression**: gzip/brotli middleware
- **Bundle size / cold start** (if frontend/serverless): code-splitting, lazy imports

### Scalability

- **Statelessness**: any in-process state that wouldn't survive multi-instance? Sessions in memory? Caches as the source of truth?
- **Horizontal scaling readiness**: 12-factor adherence (logs to stdout, config via env, etc.)
- **Sticky sessions** required? (Usually a smell.)
- **Database scaling story**: read replicas configured? Sharding visible?
- **Queue-based decoupling**: which paths use queues to handle load spikes?
- **Long-running operations**: are they in-request (blocking) or async (job + poll/webhook)?

### Reliability & availability

- **Retries**: HTTP client retry config? Backoff strategy (constant, exp, jitter)?
- **Timeouts**: explicit timeouts on every external call, or relying on defaults?
- **Circuit breakers**: any (resilience4j, opossum, hystrix)?
- **Idempotency**: idempotency keys on `POST`s? Especially payments and webhooks.
- **Health checks**: `/health`, `/ready`, `/live` endpoints? K8s probes?
- **Graceful shutdown**: SIGTERM handlers? Drain logic on queue consumers?
- **Database transactions**: where are they used? Where are they conspicuously missing (multi-step writes)?
- **Error boundaries**: does an exception in one request crash the process or just fail that request?
- **Dead-letter handling**: for queues — DLQ config?

### Observability

- **Logging**: library, format (JSON?), levels in use, correlation IDs.
- **Metrics**: Prometheus client? StatsD? OpenTelemetry? Which metric types are emitted?
- **Tracing**: OpenTelemetry, Datadog APM, Sentry tracing?
- **Error reporting**: Sentry, Rollbar, Bugsnag? PII scrubbing config?
- **Audit logging**: does sensitive activity get a durable log? Where?
- **Alerts**: any alert config in the repo? (Often lives elsewhere.)

### Maintainability

This is the section where you can be useful without speculating. Measure:

- **Test layout**: unit / integration / e2e? Run instructions?
- **Test coverage signal**: presence of CI coverage step, any thresholds.
- **Lint / format**: ESLint/Prettier/Ruff/golangci-lint/etc. configs present?
- **Type checking**: TypeScript strict mode? `mypy` strict? `mvn verify` includes type checks?
- **Module coupling**: are layers respected? Or does the controller call the database directly?
- **Code duplication**: any obvious patterns (e.g. same auth check copied across 10 controllers)?
- **TODO/FIXME density**: a count + the top 5 most concerning ones.
- **Dead code**: commented-out blocks, unreachable branches, unused exports if your tools detect them.
- **Documentation density**: JSDoc / docstring presence on public APIs.

### Compatibility & portability

- **Runtime versions**: Node 18 vs 20? Python 3.9 vs 3.12? Pinned or floating?
- **OS assumptions**: shell scripts using bashisms? Path separators? Case-sensitivity?
- **Browser support** (frontend): from `browserslist` or build config.
- **DB version**: pinned in docker-compose / migrations using specific features?

### Compliance & privacy

- **PII handling**: which entities contain PII? Are they redacted in logs?
- **GDPR signals**: user deletion endpoints? Data export endpoints? Consent tracking?
- **Audit log**: covered in observability, but flag again if compliance-relevant.
- **Data retention**: any code that purges old records? Retention policies in config?
- **Encryption at rest**: usually infra, but app-level field encryption (e.g. for SSNs) sometimes appears in code.

## Severity tags for findings

Use these tags on any *gap or risk* you flag, so the reader can prioritize:

- 🔴 **Critical** — exploitable security issue, data loss risk, or production outage waiting to happen (hardcoded prod credentials, SQL injection, no auth on admin endpoints).
- 🟠 **High** — meaningful weakness that will hurt under load or attack (no rate limiting on login, missing input validation on a public endpoint, no DB transactions on multi-write paths).
- 🟡 **Medium** — should be fixed eventually (inconsistent error handling, missing observability on a critical path).
- 🔵 **Low** — nice to have (no test for X, missing docstrings).

Always include severity. A list of findings without severity is a wishlist; with severity it's a roadmap.

## "No evidence" template

If a whole category genuinely has no evidence:

> ## Summary
>
> No code-level evidence of <category> measures was found in this repository.
>
> ## Possible explanations
>
> - Handled at the infrastructure layer (e.g. WAF, API gateway) — confirm with ops.
> - Genuinely missing — likely a gap.
> - Lives in a separate repo (auth service, shared library) — find and link it.
>
> ## Recommendation
>
> Confirm with the team before drawing conclusions.

Better than fabricating; better than silence.
