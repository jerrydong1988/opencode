# ============================================================================
# custom-rebase.ps1 - Rebase custom-frozen-fix branch onto latest upstream
# ============================================================================
# PowerShell version for Windows maintainers
# Usage:
#   1. Ensure remote "upstream" points to anomalyco/opencode
#      git remote add upstream https://github.com/anomalyco/opencode.git
#   2. Run with the new upstream tag:
#      .\scripts\custom-rebase.ps1 v1.18.0
# ============================================================================

param(
  [Parameter(Mandatory=$true)]
  [string]$NewTag
)

$ErrorActionPreference = "Stop"

$OldBranch = git branch --show-current
$NewBranch = "custom-frozen-fix-$(Get-Date -Format 'yyyyMMdd')"
$PatchDir = "patches/custom"

Write-Host "Starting rebase from $OldBranch to tag $NewTag"
Write-Host "New branch: $NewBranch"

# 1. Enable git rerere (one-time setup)
$rerere = git config --global rerere.enabled
if ($rerere -ne "true") {
  Write-Host "Enabling git rerere (one-time)..."
  git config --global rerere.enabled true
}

# 2. Fetch upstream tags
Write-Host "Fetching upstream tags..."
git fetch upstream --tags --prune

# 3. Verify the new tag exists
$null = git rev-parse --verify "refs/tags/$NewTag" 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Host "Tag $NewTag not found."
  git tag -l "v*" | Select-Object -Last 20
  exit 1
}

# 4. Create new branch
Write-Host "Creating branch $NewBranch from $NewTag..."
git checkout -b $NewBranch $NewTag
if ($LASTEXITCODE -ne 0) { throw "Failed to create branch" }

# 5. Copy new (add-only) files - these NEVER conflict
Write-Host "Adding new diff-worker files..."
git checkout $OldBranch -- `
  packages/ui/src/diff/client-core.ts `
  packages/ui/src/diff/client.test.ts `
  packages/ui/src/diff/client.ts `
  packages/ui/src/diff/protocol.ts `
  packages/ui/src/diff/render-purity.test.ts `
  packages/ui/src/diff/resource.ts `
  packages/ui/src/diff/worker.ts `
  packages/app/src/pages/session/message-timeline.diffs.ts `
  packages/app/src/pages/session/message-timeline.diffs.test.ts `
  packages/app/e2e/smoke/session-review-performance.spec.ts

git checkout $OldBranch -- `
  .github/workflows/build-desktop-custom.yml `
  CUSTOM_BUILD.md

git add -A
git commit -m "chore: add diff worker and dedup fix files"

# 6. Copy patches from old branch
git checkout $OldBranch -- $PatchDir
git reset HEAD $PatchDir  # unstage patches (we need them on disk but not committed yet)
Write-Host "Patches copied from $OldBranch"

# 7. Apply patches for modified consumer files
Write-Host "Applying patches..."
$Patches = @(
  "$PatchDir/packages_ui_package.json.patch"
  "$PatchDir/packages_session-ui_src_components_session-diff.ts.patch"
  "$PatchDir/packages_session-ui_src_components_session-review.tsx.patch"
  "$PatchDir/packages_session-ui_src_components_session-turn.tsx.patch"
  "$PatchDir/packages_session-ui_src_components_message-part.tsx.patch"
  "$PatchDir/packages_session-ui_src_components_apply-patch-file.ts.patch"
  "$PatchDir/packages_session-ui_src_components_apply-patch-file.test.ts.patch"
  "$PatchDir/packages_app_src_pages_session_timeline_message-timeline.tsx.patch"
  "$PatchDir/packages_app_src_pages_session_timeline_rows.ts.patch"
  "$PatchDir/packages_app_e2e_utils_mock-server.ts.patch"
)

$AllOk = $true
foreach ($Patch in $Patches) {
  if (-not (Test-Path $Patch)) { continue }
  Write-Host "  + $(Split-Path $Patch -Leaf)" -NoNewline
  $result = git apply --3way $Patch 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Host " OK"
  } else {
    Write-Host " CONFLICT"
    Write-Host "    $result"
    $AllOk = $false
  }
}


# 9. Commit applied changes
if ($AllOk) {
  git commit -m "fix: prepare diffs off the render thread (#31309, #30441)"
} else {
  Write-Host ""
  Write-Host "=== Some patches had conflicts ==="
  Write-Host "1. Resolve conflict markers (merge conflicts, not .rej files)"
  Write-Host "2. git add -A"
  Write-Host "3. git commit -m `"fix: prepare diffs off the render thread (#31309, #30441)`""
  exit 1
}

# 10. Verify
Write-Host ""
Write-Host "Verifying..."
if (Test-Path ".github/workflows/build-desktop-custom.yml") { Write-Host "  [ok] workflow file" }
if (Test-Path "packages/ui/src/diff/worker.ts") { Write-Host "  [ok] diff worker" }
$check = Select-String -Path packages/session-ui/src/components/session-review.tsx -Pattern "createPreparedDiff" -Quiet 2>$null
if ($check) { Write-Host "  [ok] patches applied" }
Write-Host ""

Write-Host ""
Write-Host "Regenerating complete-fix.patch for future rebases..."
git diff "upstream/dev" -- `
  packages/session-ui/src/components/ `
  packages/app/src/pages/session/ `
  packages/ui/package.json `
  packages/app/e2e/utils/mock-server.ts 
  > patches/custom/complete-fix.patch
git add -A
git commit -m "chore(custom): update patch files and regenerate complete-fix.patch"

Write-Host "Verifying..."
if (Test-Path ".github/workflows/build-desktop-custom.yml") { Write-Host "  [ok] workflow file" }
if (Test-Path "packages/ui/src/diff/worker.ts") { Write-Host "  [ok] diff worker" }
$check = Select-String -Path packages/session-ui/src/components/session-review.tsx -Pattern "createPreparedDiff" -Quiet 2>$null
if ($check) { Write-Host "  [ok] patches applied" }

Write-Host "Done. New branch: $NewBranch (tag $NewTag)"
Write-Host ""
Write-Host "=== Next Steps ==="
Write-Host "  git push origin $NewBranch"
Write-Host ""
Write-Host "When upstream releases a newer tag, run:"
Write-Host "  .\scripts\custom-rebase.ps1 NEW_TAG"
Write-Host ""
Write-Host "Key improvements over Plan D:"
Write-Host "  - Uses git apply --3way (3-way merge) for smarter conflict resolution"
Write-Host "  - Enables rerere auto-resolution of recurring conflicts"
Write-Host "  - Regenerates complete-fix.patch for future rebases"
Write-Host "  - Conflict markers (not .rej files) work with VS Code Merge Editor"

