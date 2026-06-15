# Worked Example

This file demonstrates what the skill's output looks like in practice. The example is a small Node/Express orders API. The same shape applies at much larger scale — just more features and more depth per section.

The example below is **what a feature doc and an NFR doc look like when filled in**. Use these as the bar for quality on real work.

---

## Example feature doc: `03-features/02-order-placement.md`

> # Feature: Order placement
>
> [← Back to README](../00-README.md) | [← Back to Catalog](./00-catalog.md)
>
> ## Overview
>
> Authenticated customers create an order against in-stock inventory and a saved payment method. Stock is reserved at the moment of placement; payment authorization is requested synchronously; final capture happens on a separate webhook callback. Used by the customer-facing web app and mobile app via the same REST endpoint.
>
> ## Entry points
>
> | Trigger | Location | Notes |
> |---|---|---|
> | `POST /api/orders` | `src/api/orders.ts:34` | Requires JWT (auth middleware), no rate-limit configured `[Observed]` |
>
> ## Sequence
>
> ```mermaid
> sequenceDiagram
>     participant C as Client
>     participant API as OrderController
>     participant UC as PlaceOrderUseCase
>     participant Inv as InventoryService
>     participant Pay as Stripe
>     participant DB as Postgres
>
>     C->>API: POST /api/orders {items, paymentMethodId}
>     API->>UC: place(userId, items, paymentMethodId)
>     UC->>DB: BEGIN TX
>     UC->>Inv: reserve(items)
>     alt insufficient stock
>         Inv-->>UC: OutOfStockError
>         UC->>DB: ROLLBACK
>         UC-->>API: 409 {code: OUT_OF_STOCK}
>     else stock reserved
>         UC->>Pay: createPaymentIntent(amount, paymentMethodId)
>         Pay-->>UC: paymentIntent{id, status, clientSecret}
>         UC->>DB: INSERT orders (status=PENDING_PAYMENT)
>         UC->>DB: INSERT order_items
>         UC->>DB: UPDATE inventory SET reserved = reserved + n
>         UC->>DB: COMMIT
>         UC-->>API: order
>         API-->>C: 201 {order, clientSecret}
>     end
> ```
>
> **Step notes:**
>
> 1. JWT verification happens in `src/middleware/auth.ts:18`. On failure: 401, request never reaches the controller.
> 2. The transaction wraps reservation + payment intent + writes. **However, the call to Stripe occurs inside the transaction (`src/usecases/orders/place.ts:42`)** — this is a design risk: a slow Stripe response holds the DB transaction open, increasing lock contention. Flagged in reliability NFRs.
> 3. No idempotency key is accepted on this endpoint. A retried `POST /api/orders` from a flaky client will create duplicate orders. Flagged in reliability NFRs.
>
> ## Data
>
> **Read:**
> - `users` — for ownership (`user_id`) on the new order
> - `inventory` — current `available` and `reserved` per SKU; uses index `idx_inventory_sku` (`migrations/20240312_inventory_sku_index.sql`)
> - `payment_methods` — for Stripe `payment_method_id` lookup
>
> **Written:**
> - `orders` — INSERT with `status='PENDING_PAYMENT'`, `created_at=now()`
> - `order_items` — INSERT one row per line item
> - `inventory` — UPDATE `reserved += quantity` per SKU
> - All three writes under one transaction (`src/usecases/orders/place.ts:35-78`)
>
> **Cached:** None.
>
> ## Business rules
>
> > **R1.** An order must contain ≥1 line item. — `src/api/orders.ts:38` (Zod schema, `min(1)`)
> >
> > **R2.** Each line item's quantity must be a positive integer ≤ 100. — `src/api/orders.ts:39` (`int().positive().max(100)`)
> >
> > **R3.** Stock must be available (`available - reserved >= requested`) for every SKU; otherwise the entire order is rejected (no partial fulfillment). — `src/domain/inventory.ts:21-29`
> >
> > **R4.** Payment method must belong to the authenticated user. — `src/usecases/orders/place.ts:28`
> >
> > **R5.** Order total = sum of (item.price × item.quantity); price is taken from `products.current_price` at the moment of placement (not from client-submitted price). — `src/usecases/orders/place.ts:18-22`
>
> ## Error handling
>
> | Error | Trigger | Response | Where |
> |---|---|---|---|
> | `ZodError` | Schema validation fails | 400 + `{errors: [...]}` | global handler `src/middleware/errors.ts:14` |
> | `UnauthorizedError` | JWT missing/expired | 401 | `src/middleware/auth.ts:32` |
> | `OutOfStockError` | Insufficient stock for any SKU | 409 + `{code: 'OUT_OF_STOCK', sku: ...}` | `src/domain/inventory.ts:31` |
> | `PaymentMethodNotOwned` | Payment method belongs to another user | 403 | `src/usecases/orders/place.ts:30` |
> | `StripeError` (network / API) | Stripe call fails | 502 + generic message | `src/usecases/orders/place.ts:71` |
> | Unhandled exception | Anything else | 500 + opaque message; full stack to logs | `src/middleware/errors.ts:42` |
>
> ## Dependencies
>
> - **Other features:** Authentication (must precede); Stripe webhook handler (completes the order lifecycle on payment success).
> - **External services:** Stripe API. Timeout: default (no explicit timeout configured) `[Observed risk]`. Retries: none configured.
> - **Cross-cutting:** Auth middleware, central error handler, request-scoped logger. See [`../02-architecture/06-cross-cutting.md`](../02-architecture/06-cross-cutting.md).
>
> ## Limitations & known issues
>
> - `src/usecases/orders/place.ts:55` — comment: `// TODO: emit OrderPlaced event for inventory team`
> - Stripe call happens inside the DB transaction (see Step note 2). 🟠 High.
> - No idempotency on POST. 🟠 High.
> - No rate limiting on the endpoint. A logged-in user can spam orders. 🟡 Medium.
> - Reserved stock is decremented only on cancellation/timeout — the timeout logic lives in `workers/order-timeout.ts` and runs every 5 min. There's a window where reserved stock is "stuck" if the worker is down.
>
> ## How to extend
>
> To add **multi-currency support**:
> - Add `currency` column to `orders` (new migration).
> - Read currency from `products.currency` per item; reject mixed-currency orders or convert at quote time.
> - Pass `currency` to `stripe.paymentIntents.create`.
> - Files: `src/usecases/orders/place.ts`, `src/api/orders.ts` (schema), `src/domain/order/total.ts`.
> - Tests: `tests/usecases/orders/place.test.ts`.

---

## Example NFR doc: `04-nfrs/04-reliability.md`

> # Reliability & availability
>
> [← Back to README](../00-README.md)
>
> ## Summary
>
> The service handles single-request failures reasonably (DB transactions roll back, errors map to HTTP codes), but lacks several systemic reliability mechanisms expected for a production payment-touching service: no idempotency keys on mutating endpoints, no explicit timeouts on external calls, no circuit breaker, and external API calls held inside DB transactions in at least one critical path. Background workers exist but lack DLQs.
>
> ## Observed mechanisms
>
> ### Transactions
> - Order placement writes are wrapped in a Postgres transaction (`src/usecases/orders/place.ts:35-78`). On any error, all writes roll back.
> - The Prisma client is initialized with `transactionOptions: { maxWait: 5000, timeout: 10000 }` (`src/infra/db/client.ts:8`) — applies a 10s ceiling on transaction duration.
>
> ### Health checks
> - `GET /health` returns `{ok: true}` always (`src/api/health.ts:4`) `[Observed]`
> - `GET /ready` checks DB connectivity (`src/api/health.ts:11`) `[Observed]`
> - Kubernetes deployment uses `/ready` for `readinessProbe` (`k8s/api-deployment.yaml:34`) `[Observed]`
>
> ### Graceful shutdown
> - `SIGTERM` handler in `src/server.ts:42` calls `server.close()` then closes the DB pool. Worker shutdown waits for in-flight jobs (`workers/order-timeout.ts:18`).
>
> ### Error containment
> - Global error handler at `src/middleware/errors.ts:14` ensures uncaught exceptions in route handlers fail just that request, not the process.
>
> ## Gaps and risks
>
> | Severity | Finding | Evidence | Recommendation |
> |---|---|---|---|
> | 🟠 High | No idempotency keys on `POST /api/orders` or other mutating endpoints. Retried client requests create duplicates. | `src/api/orders.ts`, no `Idempotency-Key` header read anywhere | Accept and persist idempotency keys with a uniqueness constraint; return the original response on repeat. |
> | 🟠 High | Stripe API call inside DB transaction. Slow Stripe responses hold DB locks; Stripe degradation amplifies into DB contention. | `src/usecases/orders/place.ts:35-78` | Restructure: reserve stock + commit; create payment intent; update order with intent ID. Or use the saga pattern. |
> | 🟠 High | No explicit timeout on Stripe SDK calls. Stripe default is generous (~80s). | `src/infra/clients/stripe.ts:6` — `new Stripe(key)` with no `timeout` option | Set `timeout: 5000` on the Stripe client. |
> | 🟡 Medium | No retry policy for transient Stripe failures (network errors, 5xx). | No `axios-retry`, no manual retry wrapper around Stripe calls. | Add exponential backoff with jitter for safe (idempotent-keyed) operations. |
> | 🟡 Medium | No circuit breaker for any external dependency. | No `opossum`, `cockatiel`, or similar in `package.json`. | Add a circuit breaker around Stripe and supplier API. |
> | 🟡 Medium | The `order-timeout` worker has no DLQ. A persistently-failing job will loop or get lost. | `workers/order-timeout.ts:22` — `catch { logger.error(...) }` then continues | Add a max-retries counter on the job; route exhausted jobs to a DLQ table. |
> | 🟡 Medium | Reserved-stock release depends solely on the timeout worker. If the worker is down, stock stays reserved indefinitely. | `workers/order-timeout.ts` is the only releaser. | Add a `released_at` materialized view + alert if reservations older than N minutes are non-zero. |
> | 🔵 Low | `/health` doesn't verify any dependency — only the process is alive. Misnamed if used as a liveness signal. | `src/api/health.ts:4` | Either rename it to `/live` or have it check at least DB ping; align names with k8s probe roles. |
>
> ## Open questions
>
> - Is Stripe's idempotency-key feature being used on the *Stripe-side* call? The SDK supports it but the code doesn't appear to set it. Confirm.
> - Are there alerts on the `order-timeout` worker lag? Not visible in the repo — confirm with ops.

---

## Notes

The example above is a good calibration target. Things to copy:

- **Citations everywhere.** Every claim has a `file:line`.
- **Severity tags on every NFR finding.**
- **Diagrams show decisions, not just sequence.**
- **Business rules pulled out of code and stated in English.**
- **"How to extend" section** turns the doc from reference into onboarding material.
- **Honest about gaps** — the NFR doc surfaces 8 distinct findings on a tiny example service. Real codebases have more.

Things to avoid:
- File-by-file narration. (None in the example.)
- Vague claims without citations. (None.)
- Inventing business context. (Notice the example never says what business this is.)
- Hedging without specifics. ("Could be better" → instead, "🟡 Medium: <specific gap>".)
