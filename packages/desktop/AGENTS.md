# Desktop package

- Renderer code calls `window.api` through `src/preload`; register main-process IPC handlers in `src/main/ipc.ts`.
- For visible copy or i18n changes, follow [localization guidance](../../docs/agent-guides/localization.md), including native menus, picker titles, dialogs, and errors.
- Renderer code resolves copy through the app language API; main-process code consumes typed bundles through `nativeT(...)`.
- Keep locale and grammar logic in the shared layer. Native menus, dialogs, and IPC handlers must not inspect locales, choose plural categories, or assemble translated fragments.
