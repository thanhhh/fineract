# Traceability Matrix

[← Back to README](./00-README.md)

This matrix maps each feature to the code modules implementing it and the NFR categories it materially affects. Use it for impact analysis: when changing a module, find every feature that touches it; when assessing a feature, find every NFR it implicates.

## Feature × Module

| Feature | Primary modules | Secondary modules |
|---|---|---|
| [Authentication](./03-features/01-authentication.md) | `src/api/auth.ts`, `src/usecases/auth/`, `src/infra/jwt.ts` | `src/middleware/auth.ts` |
| [Order management](./03-features/02-order-management.md) | `src/api/orders.ts`, `src/usecases/orders/`, `src/domain/order/` | `src/infra/db/orders.ts`, `src/infra/clients/stripe.ts` |
| ... | ... | ... |

## Feature × NFR

| Feature | Security | Performance | Scalability | Reliability | Observability | Compliance |
|---|---|---|---|---|---|---|
| Authentication | ✅ Core | 🟡 Rate limiting | ✅ | ✅ Retries | ✅ Audit log | ✅ PII |
| Order management | ✅ Authz | 🔴 N+1 risk | ✅ | 🟡 No idempotency | ✅ | ✅ PII |
| ... | ... | ... | ... | ... | ... | ... |

Legend:
- ✅ — feature engages this NFR positively (good evidence in code)
- 🟡 — feature engages this NFR with concerns
- 🔴 — feature has known issues in this NFR area
- (blank) — feature does not materially affect this NFR

## Module × NFR (rollup)

| Module | NFRs it touches | Notes |
|---|---|---|
| `src/middleware/auth.ts` | Security, Observability | Token verification + audit logging |
| `src/infra/db/` | Security, Performance, Reliability | Parameterized queries, indexes, transaction handling |
| ... | ... | ... |
