# OpenCode Desktop — Custom Frozen Fix Build

> **Purpose:** Temporary fork of [anomalyco/opencode](https://github.com/anomalyco/opencode) with two unmerged renderer-freeze fixes, until they land in an official release.
>
> **Branch:** `custom-frozen-fix-v7` (based on `upstream/dev`, 376 commits ahead of `v1.17.9`)
>
> **Maintainer:** [jerrydong1988](https://github.com/jerrydong1988)

---

## Why This Fork Exists

OpenCode Desktop freezes on Windows when working with large file diffs (e.g., C++ projects like `llama.cpp`). The root cause is `execEditLength` running synchronously on the UI render thread during diff computation.

Two PRs fix this but have **not yet been merged** upstream:

| PR | Author | Fix | Status |
|:---|:-------|:----|:------:|
| [#31309](https://github.com/anomalyco/opencode/pull/31309) | Hona | Move diff parsing to Web Worker off the UI thread (233ms → 66ms frame gap) | **OPEN** |
| [#30441](https://github.com/anomalyco/opencode/pull/30441) | stanlymt | Fix O(n²) dedup in `constructMessageRows` (Set-based, 25k diffs in <1s) | **OPEN** |

This branch cherry-picks both commits onto the latest release tag `v1.17.7`.

---

## Included Fixes

### 1. PR #31309 — `fix(ui): prepare diffs off the render thread`
- **Commit:** `4dd2daa7e`
- **Changes:** 17 files in `packages/ui/src/diff/`, `packages/app/src/components/`, etc.
- Adds a Web Worker for diff preparation, so the UI thread never blocks on large diffs.
- Performance: max frame gap **233ms → 66ms** (71% reduction).

### 2. PR #30441 — `fix(app): avoid O(n^2) dedup hang on large diff summaries`
- **Commit:** `982fbf40a`
- **Changes:** 3 files in `packages/app/src/pages/session/`
- Replaces `reduceRight` + `result.some()` with a `Set` for O(n) dedup.
- 25k diffs now complete in <1s instead of hanging the renderer.

---

## How to Build (GitHub Actions)

The fork has a CI workflow that builds the Desktop installer automatically:

1. Push to a branch matching `custom-*` (e.g., `custom-frozen-fix-v2`)
2. The workflow `.github/workflows/build-desktop-custom.yml` triggers
3. Environment: `OPENCODE_CHANNEL=prod` (so appId and database path match the official release)
4. Package: `bun run --cwd packages/desktop package --publish=never`
5. Artifact uploaded: `opencode-desktop-windows-custom`

### Critical Build Settings

```yaml
# Must set OPENCODE_CHANNEL=prod for all steps, otherwise:
# 1. appId becomes "ai.opencode.desktop.dev" → different userData directory
# 2. InstallationChannel becomes "custom-frozen-fix-v2" (git branch name) → wrong DB name
env:
  OPENCODE_CHANNEL: prod

# Must add --publish=never, otherwise electron-builder tries to upload
# to GitHub Releases and fails with "GH_TOKEN not set"
bun run --cwd packages/desktop package --publish=never
```

### Database Alignment

With `OPENCODE_CHANNEL=prod`:
- `appId = "ai.opencode.desktop"` → userData at `%APPDATA%\ai.opencode.desktop`
- `InstallationChannel = "prod"` → database file = `opencode.db` (same as official)
- Sessions are shared with any existing official installation

---

## Resyncing with New Upstream Releases

When upstream releases a new version (e.g., `v1.18.0`):

```bash
# Fetch latest tags
git fetch upstream --tags

# Create new branch from new tag
git checkout -b custom-frozen-fix-v4 v1.18.0

# Cherry-pick the two fix commits (they rarely conflict)
git cherry-pick 4dd2daa7e 982fbf40a

# Copy the workflow file from the existing branch
git show custom-frozen-fix-v2:.github/workflows/build-desktop-custom.yml > .github/workflows/build-desktop-custom.yml
git add .github/workflows/build-desktop-custom.yml
git commit -m "chore: add desktop build workflow"

# Push to trigger CI build
git push origin custom-frozen-fix-v4
```

The two fix commits apply cleanly in most cases: PR #31309 touches `packages/ui/src/diff/` and component files; PR #30441 touches `packages/app/src/pages/session/`. They are independent of core business logic.

---

## Auto-Update to Official

This build uses the official publish config:

```ts
publish: { provider: "github", owner: "anomalyco", repo: "opencode", channel: "latest" }
```

When the upstream eventually merges both fixes and publishes a new release, the auto-updater will:
1. Detect the new version (via `latest.yml` on `anomalyco/opencode` releases)
2. Prompt "Update vX.Y.Z downloaded. Restart now?"
3. On restart, replace this custom build with the official release

**No manual uninstall/reinstall needed.**

---

## Switching Back to Official (Manual)

Once both PRs are merged, simply:

```bash
# Uninstall this custom version
# Download the official release from https://opencode.ai/download
# Install normally — all sessions and config are preserved
```

---

## Troubleshooting

### No sessions visible after install
- Cause: Build used wrong `OPENCODE_CHANNEL` (e.g., "dev" or git branch name)
- Database was created at `~/.local/share/opencode/opencode-<channel>.db` instead of `opencode.db`
- Fix: Rebuild with `OPENCODE_CHANNEL=prod`, or copy the old DB:
  ```bash
  cp opencode.db opencode-<channel>.db
  ```

### electron-builder fails with "GH_TOKEN not set"
- Cause: Missing `--publish=never` flag in the package command
- Fix: Add `--publish=never` to the `bun run --cwd packages/desktop package` step

---

## Files

| File | Purpose |
|:----|:--------|
| `.github/workflows/build-desktop-custom.yml` | CI workflow for custom Desktop build |
| `CUSTOM_BUILD.md` | This file — build documentation |
