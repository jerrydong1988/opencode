# LLM package

## Boundaries

- Keep this package independent of session auth, permissions, plugins, telemetry, and runtime selection; those belong to the opencode session service and its adapters.
- Schema classes in `src/schema/` are the canonical data model. Use per-type constructors; keep `LLM` for request-shaped APIs, without a second model or duplicate construction surface.
- Providers compose protocol, endpoint, authentication, framing, and transport. Protocols do not depend on provider facades or model catalog metadata.
- A stream/generate call executes one provider turn. The enclosing application owns history, persistence, authorization, and continuation.
- Provider-executed tools must not be dispatched locally again. Preserve their protocol-required history; distinguish recoverable `ToolFailure` from defects and interruption.
- Keep untrusted documents and tool/web output out of privileged system updates. Unsupported chronological system messages use the explicit lower-authority fallback described in the reference.

## Implementation

- Prefer Effect HTTP, Stream, and Schema codecs at package boundaries; avoid ad hoc web readers and JSON parsing when existing abstractions fit.
- Yield typed errors directly; use `Effect.void` for intentional void results.
- Protocol parsers own usage, finish reasons, and pending tool calls. Emit exactly one terminal finish event for a completed response and use shared helpers for repeated protocol policy.
- Preserve the existing protocol section order and keep provider quirks behind named helpers.

## Tests

- Use `testEffect(...)` for tests requiring Effect layers. Replay recorded fixtures by default.
- Live recording requires explicit `RECORD=true` and the required API keys. Limit recording to the provider/scenario that needs it; do not blanket re-record stable cassettes.

## Task references

For route/provider APIs, request lowering, chronological system updates, tool dispatch, protocol layout, or cassette filters, read the relevant section of [the implementation reference](docs/agent-reference.md).
