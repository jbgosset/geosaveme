#!/bin/bash
# ─────────────────────────────────────────────────────────────
# GeoSaveMe — AI Commit Helper
#
# After an AI session produces changes, run this script to
# create a properly named branch and commit with a standard
# message. The branch stays separate from main until a human
# reviews and merges it.
#
# Usage:
#   ./4-code/scripts/ai-commit.sh "agent" "task" "spec-ref"
#
# Example:
#   ./4-code/scripts/ai-commit.sh \
#     "claude" \
#     "hotspot-api-scaffold" \
#     "3-implementation/technical-guidelines/technical-spec-v1.2.md §2.2.1"
# ─────────────────────────────────────────────────────────────

set -e

AGENT="${1:-claude}"
TASK="${2:-unnamed-task}"
SPEC="${3:-see commit body}"
BRANCH="ai/${AGENT}/${TASK}"
DATE=$(date +%Y-%m-%d)

echo ""
echo "► Creating branch: $BRANCH"
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

echo "► Staging all changes..."
git add -A

echo "► Committing..."
git commit -m "ai(${AGENT}): ${TASK}

Agent    : ${AGENT}
Date     : ${DATE}
Spec ref : ${SPEC}

[ai-generated — pending human review]
[use: git diff main...${BRANCH} to review before merging]"

echo ""
echo "✓ Branch committed: $BRANCH"
echo ""
echo "  Push and open PR:"
echo "  git push -u origin $BRANCH"
echo ""
echo "  Review diff before merge:"
echo "  git diff main...$BRANCH"
echo ""
echo "  Merge after review:"
echo "  git checkout main && git merge --no-ff $BRANCH"
