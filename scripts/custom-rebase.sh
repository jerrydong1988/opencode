#!/usr/bin/env bash
# ============================================================================
# custom-rebase.sh - Rebase custom-frozen-fix branch onto latest upstream
# ============================================================================
# Usage:
#   1. Ensure remote "upstream" points to anomalyco/opencode
#      git remote add upstream https://github.com/anomalyco/opencode.git
#   2. Run with the new upstream tag:
#      bash scripts/custom-rebase.sh v1.18.0
# ============================================================================

set -euo pipefail

NEW_TAG="${1:?Usage: $0 <new-upstream-tag>}"
OLD_BRANCH="$(git branch --show-current)"
NEW_BRANCH="custom-frozen-fix-$(date +%Y%m%d)"
PATCH_DIR="patches/custom"

# One-time setup: enable git rerere
if [ "$(git config --global rerere.enabled)" != "true" ]; then
  echo "Enabling git rerere (one-time)..."
  git config --global rerere.enabled true
fi

# 1. Fetch upstream tags
echo "Fetching upstream tags..."
git fetch upstream --tags --prune

# 2. Verify the new tag exists
if ! git rev-parse --verify "refs/tags/$NEW_TAG" >/dev/null 2>&1; then
  echo "Tag $NEW_TAG not found."
  git tag -l "v*" | tail -20
  exit 1
fi

# 3. Create new branch
echo "Creating branch $NEW_BRANCH from $NEW_TAG..."
git checkout -b "$NEW_BRANCH" "$NEW_TAG"

# 4. Copy new (add-only) files - these NEVER conflict
echo "Adding new diff-worker files..."
git checkout "$OLD_BRANCH" -- \
  packages/ui/src/diff/client-core.ts \
  packages/ui/src/diff/client.test.ts \
  packages/ui/src/diff/client.ts \
  packages/ui/src/diff/protocol.ts \
  packages/ui/src/diff/render-purity.test.ts \
  packages/ui/src/diff/resource.ts \
  packages/ui/src/diff/worker.ts \
  packages/app/src/pages/session/message-timeline.diffs.ts \
  packages/app/src/pages/session/message-timeline.diffs.test.ts \
  packages/app/e2e/smoke/session-review-performance.spec.ts

git checkout "$OLD_BRANCH" -- \
  .github/workflows/build-desktop-custom.yml \
  CUSTOM_BUILD.md

git add -A
git commit -m "chore: add diff worker and dedup fix files"

# 5. Apply patches for modified consumer files
echo "Applying patches..."
PATCHES=(
  "$PATCH_DIR/packages_ui_package.json.patch"
  "$PATCH_DIR/packages_session-ui_src_components_session-diff.ts.patch"
  "$PATCH_DIR/packages_session-ui_src_components_session-review.tsx.patch"
  "$PATCH_DIR/packages_session-ui_src_components_session-turn.tsx.patch"
  "$PATCH_DIR/packages_session-ui_src_components_message-part.tsx.patch"
  "$PATCH_DIR/packages_session-ui_src_components_apply-patch-file.ts.patch"
  "$PATCH_DIR/packages_session-ui_src_components_apply-patch-file.test.ts.patch"
  "$PATCH_DIR/packages_app_src_pages_session_timeline_message-timeline.tsx.patch"
  "$PATCH_DIR/packages_app_src_pages_session_timeline_rows.ts.patch"
  "$PATCH_DIR/packages_app_e2e_utils_mock-server.ts.patch"
)

ALL_OK=true
for PATCH in "${PATCHES[@]}"; do
  if [ ! -f "$PATCH" ]; then continue; fi
  echo "  + $(basename "$PATCH")"
  if ! git apply --3way "$PATCH" 2>/dev/null; then
    echo "  ! Conflicts in $(basename "$PATCH")"
    echo "    Resolve conflict markers, then:"
    echo "      git add -A"
    ALL_OK=false
  fi
done

# 6. Commit
if $ALL_OK; then
  git add -A
  git commit -m "fix: prepare diffs off the render thread (#31309, #30441)"
else
  echo ""
  echo "=== Some patches had conflicts ==="
  echo "1. Resolve .rej files manually"
  echo "2. git add -A"
  echo "3. git commit -m \"fix: prepare diffs off the render thread (#31309)\""
fi

  # 7. Regenerate patches and update for future rebases (uses 3-way merge + rerere)
  echo ""
  echo "=== Regenerating patches for future rebases ==="
  git checkout "$OLD_BRANCH" -- "$PATCH_DIR" 2>/dev/null || true
  git diff "upstream/dev" -- \
    packages/session-ui/src/components/ \
    packages/app/src/pages/session/ \
    packages/ui/package.json \
    packages/app/e2e/utils/mock-server.ts \
    > "$PATCH_DIR/complete-fix.patch"
  git add -A
  git commit -m "chore(custom): update patch files and regenerate complete-fix.patch" || true
echo ""
echo "NOTE: If patches conflict, resolve conflict markers in the affected files,"
echo "then run: git add -A && git commit -m \"fix: prepare diffs off the render thread (#31309, #30441)\""
echo "git rerere will auto-resolve the same conflicts next rebase."
 
 # 8. Verify
echo ""
echo "Verifying..."
[ -f ".github/workflows/build-desktop-custom.yml" ] && echo "  [ok] workflow file"
[ -f "packages/ui/src/diff/worker.ts" ] && echo "  [ok] diff worker"
grep -q "createPreparedDiff" packages/session-ui/src/components/session-review.tsx 2>/dev/null && echo "  [ok] patches applied"
echo ""
echo "Done. New branch: $NEW_BRANCH (tag $NEW_TAG)"
echo ""
echo "=== Next Rebase ==="
echo "  git push origin $NEW_BRANCH"
echo ""
echo "When upstream releases a newer tag, run:"
echo "  bash scripts/custom-rebase.sh NEW_TAG"
echo ""
echo "Key improvements over Plan D:"
echo "  - Uses 'git apply --3way' (3-way merge) for smarter conflict resolution"
echo "  - Enables rerere auto-resolution of recurring conflicts"
echo "  - Regenerates complete-fix.patch for future rebases"

