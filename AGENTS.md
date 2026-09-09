# Repository conventions

## Workflow

- The upstream default branch is `dev`; `main` may not exist. Use the task's intended base for diffs and preserve the current fork/topic branch when continuing work.
- New branch names use at most three hyphen-separated words, without slashes or type prefixes.
- Commits and PR titles use `type(scope): summary`; types are `feat`, `fix`, `docs`, `chore`, `refactor`, and `test`. Scope is optional.
- Regenerate the legacy JavaScript SDK with `./packages/sdk/js/script/build.ts` when its source changes.
- After changing public Protocol or Server `HttpApi`, run `bun run generate` from `packages/client`. Do not edit `src/generated` or `src/generated-effect` directly.

## Architecture

- Keep runtime dependencies directed from Schema to Core and Protocol, then from Core and Protocol to Server. Client may depend on Schema and Protocol, never Core or Server; `sdk-next` composes Client, Core, and Server.
- Changes to V2 session admission, execution, delivery, interruption, or system context must preserve the invariants in [session-core.md](docs/agent-guides/session-core.md).

## Code style

- Follow surrounding patterns. Keep simple logic inline; extract helpers when reused or when they give complex validation or boundaries a clear name. Keep helpers close to their caller.
- Avoid `any` and unnecessary `try/catch`; prefer type inference, Bun APIs, and functional array methods where they improve clarity.
- Prefer `const`, early returns, and meaningful dot notation. Inline single-use values only when their names add no useful context.
- Do not alias imports or use star imports. Import a module's exported namespace by name when needed.
- Keep heavy, conditional modules lazily imported within the branch that needs them; bind the result clearly instead of chaining import expressions.
- In `src/config`, preserve the existing self-export at the top of the file, such as `export * as ConfigAgent from "./agent"`.
- Bind Effect services to named variables before invoking methods; avoid nested service yields.
- Keep synchronous parsing, validation, and option helpers synchronous. Prefer Effect Schema JSON helpers when appropriate instead of manual parsing wrapped in `Effect.try`.
- Use snake_case Drizzle field names. Comment on non-obvious constraints, not ordinary control flow.

## Validation

- Test changed behavior rather than duplicating implementation logic. Prefer real implementations; use scoped fixtures or service stubs when isolation requires them, avoiding `globalThis` mutation.
- Select checks for the affected package and behavior. Once they pass, expand or repeat only for new changes, failures, or unresolved risk.
- Tests cannot run from the repository root (`do-not-run-tests-from-root`); run from the owning package.
- When type checking is needed, use `bun typecheck` in the affected package, not `tsc` directly.
