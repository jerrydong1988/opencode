# App package

## Priorities and validation

- Prioritise stability, simplicity, then performance.
- For session or timeline changes that may affect rendering, scheduling, data flow, or resource use, compare a production benchmark before and after the change. Copy, comments, and changes with no plausible performance impact need only relevant checks.
- Do not restart a user-managed app or server without authorization. You may start, restart, and stop isolated development/test processes created for the current task; identify process ownership first.

## Local development

- `opencode dev web` proxies `https://app.opencode.ai`, so local UI/CSS changes will not show there.
- For local UI changes, start separate backend and app dev servers: from `packages/opencode`, `bun run ./src/index.ts serve --port 4096`; from `packages/app`, `bun dev -- --port 4444`.
- Verify at `http://localhost:4444`, targeting the backend at `http://localhost:4096`. Avoid taking over an occupied port belonging to another process.
- For manual UI verification, use browser tools supported by the current environment. Automated E2E tests use the package's Playwright setup.

## SolidJS and localization

- Prefer `createStore` over multiple `createSignal` calls for related state.
- For visible copy or i18n changes, follow [localization guidance](../../docs/agent-guides/localization.md).
- Use `language.t(...)` for ordinary copy and `language.plural(baseKey, count, params)` for count-sensitive copy. Keep locale inspection, `Intl.PluralRules`, and plural-category key selection out of feature code.
