# Test fixtures and synchronization

- Use the project's fixtures and scoped cleanup instead of creating a custom runtime or temporary-directory lifecycle in each test.
- Use `tmpdir` with `await using` for ordinary tests. For Effect workflows, use `testEffect(...)` from `test/lib/effect.ts`.
- Use `it.effect` for TestClock/TestConsole behavior, `it.live` for real OS/time/process behavior, and `it.instance` for a live test needing one temporary instance.
- Prefer scoped service stubs such as `Layer.mock` when only selected methods need overriding. Keep global state isolated and restore it on cleanup.
- Synchronize concurrent work using a published readiness signal, observable state, or the existing timeout/poll helpers. Fixed sleeps must not stand in for readiness.
- Real time may be needed when time itself is under test: debounce/throttle, filesystem timestamp granularity, or deliberate latency in race regressions.
- For fixture options, multiple instances, or concurrency helpers, consult [fixture and synchronization examples](agent-fixtures.md). Paths in that reference are relative to this package unless an import demonstrates a test-relative path.
