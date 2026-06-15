# Reference: Feature Catalog (Phase 3)

A feature is a *user-observable capability*, not a *code module*. "Order placement" is a feature; "OrderService.java" is not. The mapping between them is what makes documentation useful.

## How to discover features per stack

### Web APIs

The HTTP route table is the feature list, roughly. Recover it:

| Framework | Where routes live |
|---|---|
| Express/Fastify | `app.get/post/...`, `router.*` calls — grep for them |
| NestJS | `@Controller` + `@Get/@Post/...` decorators |
| Spring | `@RequestMapping`, `@GetMapping`, etc. |
| Django | `urls.py` files |
| Flask/FastAPI | `@app.route` / `@app.get` / `@router.get` |
| Rails | `config/routes.rb` |
| Next.js (App Router) | `app/**/route.ts` files |
| Go (chi/gin/echo) | `r.Get(...)`, `e.POST(...)`, etc. |
| ASP.NET | `[HttpGet]`, attribute routing, minimal API `app.MapGet` |

**Group routes into features.** A feature is a coherent capability, not one URL:

| Routes | Feature |
|---|---|
| `POST /orders`, `GET /orders/:id`, `PATCH /orders/:id`, `DELETE /orders/:id`, `GET /orders` | Order management |
| `POST /auth/login`, `POST /auth/logout`, `POST /auth/refresh`, `POST /auth/register` | Authentication |
| `POST /webhooks/stripe`, `POST /webhooks/sendgrid` | Inbound webhooks |

Rule of thumb: 5–25 features for a typical service. If you have 100 features, you're really listing endpoints — re-group.

### GraphQL APIs

Each top-level query, mutation, and subscription is roughly a feature. Group related ones (e.g. `createPost`, `updatePost`, `deletePost`, `posts`, `post` → "Post management").

### CLI tools

Each top-level subcommand is a feature. `git commit`, `git push`, `git rebase` are three features.

### UIs (SPA / mobile)

Routes/screens. In a React/Next/Vue app, look at the router config or file-based routing. Each significant page (not nav links, not partial components) is a feature.

### Background work

Each queue consumer, scheduled job, and event handler is a feature. Often these are the *most undocumented* features in a codebase — make sure to include them.

### Libraries / SDKs

The public API surface. In TS: anything `export`ed from the package entry. In Python: anything in `__all__` or not prefixed with `_`. Group by module if there are many.

## Catalog table format

`03-features/00-catalog.md`:

```markdown
# Feature Catalog

| # | Feature | Description | Entry point | Primary modules |
|---|---|---|---|---|
| 01 | Authentication | Email/password login with JWT refresh tokens | `src/api/auth.ts` | `src/api/auth.ts`, `src/usecases/auth/`, `src/infra/jwt.ts` |
| 02 | Order management | Customers create, view, modify orders | `src/api/orders.ts` | `src/api/orders.ts`, `src/usecases/orders/`, `src/domain/order/` |
| 03 | Stripe webhook handler | Receives payment events and updates order status | `src/api/webhooks/stripe.ts` | `src/api/webhooks/stripe.ts`, `src/usecases/payments/` |
| 04 | Nightly inventory sync | Pulls inventory from supplier API, updates DB | `workers/inventory-sync.ts` | `workers/inventory-sync.ts`, `src/infra/clients/supplier.ts` |
```

After the table, sort the features into groups (e.g. "Customer-facing", "Admin", "Integrations", "Operations") with a one-line intro per group. This makes the catalog scannable.

## What NOT to call a feature

- A utility module (`src/utils/date.ts`). That's infrastructure, not a feature.
- A middleware that runs on every request. Document it once in cross-cutting.
- A type/interface definition file.
- A test helper.

## Cross-references

For each feature row, the "Primary modules" column will be the bedrock of the traceability matrix in Phase 6 — keep these accurate.
