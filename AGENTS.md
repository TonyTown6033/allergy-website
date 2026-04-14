# AGENTS.md — Codex Execution Guide for `new-api` + `Allergy`

## Read First

Before making changes in this workspace, read:

1. `./AGENTS.md`
2. `./claude.md`
3. `./new-api-allergy-integration-design.md`
4. `./new-api-allergy-data-model-draft.md`
5. `./new-api-allergy-api-draft.md`

If you modify `new-api/`, also follow:

- `./new-api/CLAUDE.md`

## Mission

This workspace is not two unrelated projects. It is one integration task:

- `Allergy/` remains the user-facing frontend
- `new-api/` becomes the backend foundation

The business is an allergy testing service, not a token/quota product.

Target business flow:

1. User browses site
2. User purchases a single allergy testing service
3. User pays online
4. Staff manually ships the sample kit
5. User mails sample back
6. Lab produces a PDF report
7. Staff uploads the PDF report
8. Staff can manually resend the PDF to the user by email
9. User can view a progress timeline
10. User can preview and download the PDF report

## Locked Decisions

These are already decided. Do not redesign them unless the user explicitly changes them.

### Identity and login

- Members live directly on `new-api`'s `user` table
- Public login uses email verification code
- The site uses its own session token
- Do not reuse `new-api` `access_token` semantics
- Public member login and admin login must stay separated

### Product and fulfillment

- Version 1 is a single purchase testing service
- It is not a subscription product
- It is not a topup/quota product
- Fulfillment after payment is manual

### Payments

- Version 1 uses online payment
- Launch payment methods must include `epay`
- You may reuse `new-api` payment integration and webhook verification logic
- Do not reuse `TopUp`, `Recharge`, or quota-increase semantics
- Payment success must mean the order is paid, nothing more
- Payment success must update:
  - `allergy_order.payment_status = paid`
  - `allergy_order.order_status = paid`
  - timeline event `payment_completed`
- Never add quota on successful payment

### Reports

- Version 1 only supports PDF reports
- Users can preview and download PDFs
- Staff can manually resend a PDF by email
- Users must see a progress timeline

### Content

- Phase 1 public content stays in `Option JSON`
- Do not build a full CMS in phase 1
- Phase 1 images can remain fixed URLs or static assets

### AI

- `Allergy.AI` is not current scope
- Do not prioritize AI work before the order/report flow is complete

## Development Method

### TDD is required

Default to TDD unless the user explicitly asks otherwise.

Prefer this loop:

1. Write the test
2. Confirm the test fails
3. Implement the minimum change
4. Confirm tests pass
5. Refactor if needed

Do not write large chunks of business logic first and “add tests later”.

### Highest-priority tests

- Email-code login flow
- Order creation and payment state transitions
- Payment webhook handling
- Report authorization
- PDF preview/download authorization
- Report resend restrictions and audit trail
- Timeline event creation

## Tooling

Before implementation, verify required tools exist.

At minimum check:

- Go test toolchain
- Frontend package/build toolchain
- Browser/page validation tooling when needed
- Relevant MCP skills when needed

If the task depends on tooling and the tool is missing, install or enable it first instead of pretending validation happened.

Explicitly check for and use when helpful:

- `everything-claude-code`
- relevant MCP skills

Recommended skills/tools for this workspace:

- `frontend-skill` for user-facing UI work
- `playwright` for payment/order/report flow verification
- `screenshot` when keeping UI evidence helps

Prefer tool-based verification over assumptions for:

- payment redirects
- webhook completion
- PDF preview/download
- resend-email behavior
- timeline visibility

## Guardrails

### Do not model this as a recharge business

Do not turn the allergy-testing flow into:

- `TopUp`
- `Recharge`
- quota increments
- token sales

### Do not leak platform semantics into public APIs

Do not expose raw platform concepts to user-facing pages:

- topup
- quota
- relay
- channel
- token
- model pricing

Use Allergy-specific business APIs.

### Reports are sensitive

- Store PDFs on persistent storage
- `lab_report` stores file references only, not PDF binaries
- Resend-by-email should default to:
  - verified account email
  - or order notification email
- Do not allow unrestricted arbitrary recipient emails by default
- Every resend must be logged

### Shared `user` table, separated roles

- Member and admin accounts share `user`
- But login entry points and permission boundaries must be separate
- Do not let admin accounts flow through public member login behavior

## Target Data Model

Work toward these tables or equivalent structures:

- `user` reuse
- `member_profile`
- `email_login_code_store`
- `member_session`
- `allergy_order`
- `sample_kit`
- `lab_submission`
- `lab_report`
- `report_delivery_log`
- `order_timeline_event`

Key rules:

- One order is a real testing-service order
- One order normally maps to one sample kit
- An order may later have multiple report versions, but only one current effective report at a time
- Timeline must be event-backed, not inferred only from status fields

## Target APIs

### Compatibility APIs

- `GET /api/hero`
- `GET /api/testimonials`
- `GET /api/articles`
- `GET /api/products`
- `POST /api/auth/send-code`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `POST /api/auth/logout`

### User APIs

- `POST /api/orders`
- `GET /api/orders`
- `GET /api/orders/:id`
- `POST /api/orders/:id/pay`
- `GET /api/orders/:id/pay-status`
- `GET /api/orders/:id/timeline`
- `GET /api/orders/:id/report`
- `GET /api/reports/:id/preview`
- `GET /api/reports/:id/download`

### Admin APIs

- `GET /api/admin/orders`
- `GET /api/admin/orders/:id`
- `PATCH /api/admin/orders/:id/status`
- `POST /api/admin/orders/:id/kit`
- `POST /api/admin/orders/:id/sample-received`
- `POST /api/admin/orders/:id/report`
- `POST /api/admin/reports/:id/publish`
- `POST /api/admin/reports/:id/send-email`
- `GET /api/admin/reports/:id/delivery-logs`

## Recommended Execution Order

### Step 1

Build the minimum schema/model layer:

- `member_profile`
- `email_login_code_store`
- `member_session`
- `allergy_order`
- `sample_kit`
- `lab_report`
- `order_timeline_event`

Add if feasible in the same round:

- `lab_submission`
- `report_delivery_log`

### Step 2

Implement public compatibility APIs:

- content
- email-code login
- session validation

### Step 3

Implement order/payment flow:

- create order
- launch `epay`
- handle payment webhook
- update paid order state
- write timeline event `payment_completed`

### Step 4

Implement user read-side:

- order list
- order detail
- timeline
- report metadata
- PDF preview/download

### Step 5

Implement admin fulfillment:

- order status management
- kit registration
- sample received
- PDF upload
- report publish
- manual resend email

### Step 6

Only after the main flow is stable, consider:

- content backendization
- more payment channels
- structured report summaries
- `Allergy.AI`

## Frontend Guidance

- Minimize changes to `Allergy/`
- Only make necessary changes for email login, order pages, payment, and report pages
- Do not expose `new-api` platform vocabulary in public UI

## Done Means

The initial delivery is complete only when:

1. users can log in with email code
2. users can create testing orders
3. users can pay with `epay`
4. paid orders update correctly after webhook processing
5. staff can manage kit/fulfillment state
6. staff can upload and publish PDF reports
7. users can view a progress timeline
8. users can preview and download PDF reports
9. staff can manually resend PDFs by email
