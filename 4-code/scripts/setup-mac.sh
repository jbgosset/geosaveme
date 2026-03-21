#!/bin/bash
# ─────────────────────────────────────────────────────────────
# GeoSaveMe — Mac setup script
# Run ONCE on your Mac to initialize the local repo and push to GitHub.
#
# Usage:
#   chmod +x 4-code/scripts/setup-mac.sh
#   ./4-code/scripts/setup-mac.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME
#
# Example:
#   ./4-code/scripts/setup-mac.sh jbgosset geosaveme
# ─────────────────────────────────────────────────────────────

set -e

GITHUB_USER="${1:-YOUR_GITHUB_USERNAME}"
REPO_NAME="${2:-geosaveme}"
REMOTE="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo ""
echo "════════════════════════════════════════"
echo "  GeoSaveMe — Mac Repository Setup"
echo "════════════════════════════════════════"
echo ""

# ── 1. Check prerequisites ──────────────────────────────────
echo "► Checking prerequisites..."
command -v git  >/dev/null || { echo "ERROR: git not found. Run: xcode-select --install"; exit 1; }
command -v node >/dev/null || echo "WARN: node not found. Install from https://nodejs.org"
echo "  git  : $(git --version)"
echo "  node : $(node --version 2>/dev/null || echo 'not installed')"

# ── 2. Configure git globals if not set ────────────────────
if [ -z "$(git config --global user.email)" ]; then
  read -rp "  Git email: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi
if [ -z "$(git config --global user.name)" ]; then
  read -rp "  Git name: " GIT_NAME
  git config --global user.name "$GIT_NAME"
fi
git config --global init.defaultBranch main

# ── 3. Rename master → main locally ────────────────────────
CURRENT=$(git branch --show-current 2>/dev/null || echo "")
if [ "$CURRENT" = "master" ]; then
  git branch -m master main
  echo "► Renamed branch: master → main"
fi

# ── 4. Add remote and push ─────────────────────────────────
echo ""
echo "► Setting remote: $REMOTE"
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"

echo "► Pushing to GitHub..."
echo "  (Make sure you created the repo on GitHub first — empty, no README)"
git push -u origin main

echo ""
echo "════════════════════════════════════════"
echo "  Done!"
echo "  Remote : $REMOTE"
echo "  Branch : main"
echo ""
echo "  Next:"
echo "  1. Read 3-implementation/agent-instructions/AGENT.md"
echo "  2. Start a feature: ./4-code/scripts/ai-commit.sh"
echo "════════════════════════════════════════"
