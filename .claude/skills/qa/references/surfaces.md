# Surface-specific QA

## Browser

Launch using the project's documented recipe and exercise actual navigation and forms. Cover desktop and a relevant narrow viewport, keyboard/focus behavior, loading/empty/error states, validation and repeated submissions. Inspect console and network errors and capture before/after screenshots for visual defects. Browser automation being unavailable means visual/runtime coverage is blocked, not that source inspection proved the UI works.

## API

Check request and response shape, status and error contracts, authentication, authorization and tenant isolation. Exercise invalid and boundary input, pagination, duplicates and idempotency where relevant. Confirm persistence and transactional behavior after requests; an accepted request may still fail asynchronously.

## CLI

Invoke the real entry point as a user would. Check help, valid and invalid arguments, stdin, stdout versus stderr, exit codes, paths with spaces and config precedence. Where relevant, check piping, non-TTY execution, cancellation, repeated execution and file side effects. Keep test homes/configuration separate from the user's real environment.

## Jobs, workers and webhooks

Trigger the actual handler or producer/worker path. Observe queue state and final durable results. Check duplicate delivery, retry limits, idempotency, ordering, partial failure, cancellation and failed-job handling where applicable. For webhooks, test signature validation and replay handling. Clean up only resources the run owns, and record cleanup failures.

## Choosing tests

Use the cheapest test that detects the real regression, plus cross-boundary tests where the defect lives. A mocked transport cannot prove delivery; a source grep cannot prove runtime behavior. Reuse fixtures and assertions that already model the contract. Record which behavior remains untested when infrastructure is unavailable.
