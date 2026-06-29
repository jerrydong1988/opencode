# OpenCode Desktop - Custom Frozen Fix Build

> **Purpose:** Temporary fork of [anomalyco/opencode](https://github.com/anomalyco/opencode) with two unmerged renderer-freeze fixes, until they land in an official release.
>
> **Branch:** `custom-frozen-fix-v9` (based on `upstream/dev`)
>
> **Maintainer:** jerrydong1988

---

## Why This Fork Exists

OpenCode Desktop freezes on Windows when working with large file diffs (e.g., C++ projects like `llama.cpp`). The root cause is `execEditLength` running synchronously on the UI render thread during diff computation.

Two PRs fix this but have **not yet been merged** upstream:

| PR | Author | Fix | Status |
|:---|:-------|:----|:------:|
| [#31309](https://github.com/anomalyco/opencode/pull/31309) | Hona | Move diff parsing to Web Worker off the UI thread (233ms ? 66ms frame gap) | **OPEN** |
| [#30441](https://github.com/anomalyco/opencode/pull/30441) | stanlymt | Fix O(n?) dedup in `constructMessageRows` (Set-based, 25k diffs in <1s) | **OPEN** |

---

## Included Fixes

### 1. PR #31309 - `fix(ui): prepare diffs off the render thread`
- Adds a Web Worker for diff preparation, so the UI thread never blocks on large diffs.
- New files: `packages/ui/src/diff/*` (7 files: worker, protocol, client, resource, etc.)
- Modified files: `packages/session-ui/src/components/*` (5 components), `packages/ui/package.json`

### 2. PR #30441 - `fix(app): avoid O(n^2) dedup hang on large diff summaries`
- Replaces `reduceRight` + `result.some()` with a `Set` for O(n) dedup.
- Modified files: `packages/app/src/pages/session/timeline/rows.ts`
- New files: `packages/app/src/pages/session/message-timeline.diffs.ts` + test

---

## Maintenance Approach (Patch Overlay Strategy)

**Problem:** Cherry-picking the two PR commits directly onto each new upstream version creates merge conflicts, because the files they modify are actively changing upstream (V2 UI migration).

**Solution:** Use a **patch overlay** strategy:

1. **New files** (`packages/ui/src/diff/*`, etc.) are self-maintaining - they never conflict because they don't exist upstream. They are copied directly from the old branch.
2. **Modified files** have targeted patches stored in `patches/custom/`. These are applied via `git apply` after creating the new branch.
3. **Git rerere** is enabled to auto-resolve recurring conflicts.
4. A **rebase script** (`scripts/custom-rebase.sh`) automates the entire process.

### Files

| File | Purpose |
|:----|:--------|
| `.github/workflows/build-desktop-custom.yml` | CI workflow for custom Desktop build |
| `CUSTOM_BUILD.md` | This file - build documentation |
| `patches/custom/*.patch` | Targeted patches for modified consumer files |
| `scripts/custom-rebase.sh` | Automated rebase script for new upstream versions |
| `packages/ui/src/diff/*` | Web Worker diff implementation (new files, never conflict) |

### How to Rebase onto a New Upstream Release (Plan E - Improved)

```bash
# One-time setup (if not already done):
git config --global rerere.enabled true            # enable auto-conflict-resolution
git remote add upstream https://github.com/anomalyco/opencode.git

# Rebase:
bash scripts/custom-rebase.sh v1.18.0              # replace with new tag
```

**What the script does:**
1. Enables `git rerere` (one-time)
2. Fetches latest upstream tags
3. Creates a new branch from the requested tag
4. Copies new files from the old branch
5. Applies all patches via `git apply`
6. Verifies the result
7. Updates the `patches/custom/` directory for future rebases

**If patches conflict** (rare after first run, because rerere records resolutions):
- `.rej` files are left for manual resolution.
- Resolve, then `git add -A && git commit`.

---

## How to Build (GitHub Actions)

The fork has a CI workflow that builds the Desktop installer automatically:

1. Push to a branch matching `custom-*` (e.g., `custom-frozen-fix-v9`)
2. The workflow `.github/workflows/build-desktop-custom.yml` triggers
3. Environment: `OPENCODE_CHANNEL=prod` (so appId and database path match the official release)
4. Package: `bun run --cwd packages/desktop package --publish=never`
5. Artifact uploaded: `opencode-desktop-windows-custom`

### Critical Build Settings

```yaml
# Must set OPENCODE_CHANNEL=prod for all steps, otherwise:
# 1. appId becomes "ai.opencode.desktop.dev" ? different userData directory
# 2. InstallationChannel becomes branch name ? wrong DB name
env:
  OPENCODE_CHANNEL: prod

# Must add --publish=never, otherwise electron-builder tries to upload
# to GitHub Releases and fails with "GH_TOKEN not set"
bun run --cwd packages/desktop package --publish=never
```

### Database Alignment

With `OPENCODE_CHANNEL=prod`:
- `appId = "ai.opencode.desktop"` ? userData at `%APPDATA%\ai.opencode.desktop`
- `InstallationChannel = "prod"` ? database file = `opencode.db` (same as official)
- Sessions are shared with any existing official installation

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

Once both PRs are merged, simply uninstall this custom version and download the official release from https://opencode.ai/download. All sessions and config are preserved.

---

## Troubleshooting

### No sessions visible after install
- Cause: Build used wrong `OPENCODE_CHANNEL` (e.g., "dev" or git branch name)
- Database was created at a different path instead of `opencode.db`
- Fix: Rebuild with `OPENCODE_CHANNEL=prod`, or copy the old DB

### electron-builder fails with "GH_TOKEN not set"
- Cause: Missing `--publish=never` flag in the package command
- Fix: Add `--publish=never` to the `bun run --cwd packages/desktop package` step

### Rebase script fails with "not found" errors
- Ensure you are on the correct branch (`custom-frozen-fix-*`)
- Ensure the tag exists: `git fetch upstream --tags`


