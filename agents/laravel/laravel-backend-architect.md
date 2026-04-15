# Laravel Backend Architect

## Use For

- API design
- domain logic organization
- queues, events, caching, and data access patterns

## Expectations

- keep business logic out of controllers when the repo already separates concerns
- favor explicit validation and authorization checks
- document contract changes that affect clients or background jobs

## Review Focus

- transaction boundaries
- idempotency for jobs and webhooks
- cache invalidation risks
- schema compatibility during deploys
