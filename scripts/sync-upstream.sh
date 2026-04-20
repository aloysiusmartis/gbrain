#!/usr/bin/env bash
# sync-upstream.sh — rebase aloysiusmartis/gbrain onto garrytan/gbrain master
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

echo "Fetching upstream (garrytan/gbrain)..."
git fetch upstream

UPSTREAM_HEAD=$(git rev-parse upstream/master)
LOCAL_HEAD=$(git rev-parse master)

echo "upstream/master : $UPSTREAM_HEAD"
echo "local master    : $LOCAL_HEAD"

if [[ "$UPSTREAM_HEAD" == "$LOCAL_HEAD" ]]; then
  echo "Already at upstream tip — checking for fork commits on top..."
fi

FORK_COMMITS=$(git log --oneline upstream/master..master)
if [[ -n "$FORK_COMMITS" ]]; then
  echo ""
  echo "Fork commits that will be rebased on top:"
  echo "$FORK_COMMITS"
fi

if $DRY_RUN; then
  echo ""
  echo "[dry-run] Would run: git rebase upstream/master && git push origin master --force-with-lease"
  exit 0
fi

echo ""
echo "Rebasing master onto upstream/master..."
git rebase upstream/master

echo ""
echo "Verifying @COORDINATION.md is line 2 of CLAUDE.md..."
LINE2=$(sed -n '2p' CLAUDE.md)
if [[ "$LINE2" != "@COORDINATION.md" ]]; then
  echo "WARNING: @COORDINATION.md missing from CLAUDE.md line 2 — re-adding..."
  sed -i '' '1a\\
@COORDINATION.md' CLAUDE.md
  git add CLAUDE.md
  git commit -m "chore: restore @COORDINATION.md in CLAUDE.md post-rebase"
else
  echo "OK — @COORDINATION.md present."
fi

echo ""
echo "Pushing to origin..."
git push origin master --force-with-lease

echo ""
echo "Done. master is now synced to upstream/master."
