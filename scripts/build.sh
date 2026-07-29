#!/bin/bash
# build.sh — Check for upstream changes and compile noctalia-git if needed.
# This script runs as the unprivileged 'builder' user inside an Arch container.
set -euo pipefail

ARTIFACT_DIR="/tmp/artifact"
mkdir -p "$ARTIFACT_DIR"

# ---------------------------------------------------------------------------
# 1. Determine latest upstream commit (full 40-char SHA)
# ---------------------------------------------------------------------------
LATEST_COMMIT=$(git ls-remote https://github.com/noctalia-dev/noctalia HEAD | awk '{print $1}')
echo "Upstream HEAD: $LATEST_COMMIT"

# ---------------------------------------------------------------------------
# 2. Check currently deployed commit from GitHub Pages
# ---------------------------------------------------------------------------
REPO_URL="https://${GITHUB_REPOSITORY_OWNER}.github.io/${GITHUB_REPOSITORY#*/}"

DEPLOYED_COMMIT=$(curl -sfS "$REPO_URL/COMMIT" 2>/dev/null || echo "none")
echo "Deployed commit: $DEPLOYED_COMMIT"

# ---------------------------------------------------------------------------
# 3. Compare full SHAs — skip build if unchanged
# ---------------------------------------------------------------------------
if [[ "$LATEST_COMMIT" == "$DEPLOYED_COMMIT" ]]; then
    echo "No changes detected. Re-using existing package from GitHub Pages."
    cd "$ARTIFACT_DIR"

    for file in noctalia.db noctalia.db.tar.gz noctalia.files noctalia.files.tar.gz; do
        echo "Downloading $file ..."
        curl -sfSO "$REPO_URL/$file" || { echo "ERROR: Failed to download $file"; exit 1; }
    done

    # Extract package filename from the repo database
    tar -xf noctalia.db
    PKG_NAME=$(cat noctalia-git-*/desc | grep -A 1 '%FILENAME%' | tail -n 1)
    echo "Downloading $PKG_NAME ..."
    curl -sfSO "$REPO_URL/$PKG_NAME" || { echo "ERROR: Failed to download $PKG_NAME"; exit 1; }
    curl -sfSO "$REPO_URL/index.html" || { echo "ERROR: Failed to download index.html"; exit 1; }
    curl -sfSO "$REPO_URL/COMMIT" || { echo "ERROR: Failed to download COMMIT"; exit 1; }

    # Verify checksums
    if curl -sfS "$REPO_URL/SHA256SUMS" -o SHA256SUMS 2>/dev/null; then
        echo "Verifying checksums..."
        sha256sum -c SHA256SUMS || { echo "ERROR: Checksum verification failed!"; exit 1; }
    else
        echo "WARNING: No SHA256SUMS found on remote — skipping verification."
    fi

    rm -rf noctalia-git-*/

    # Signal that we skipped the build
    echo "SKIPPED_BUILD=true" > "$ARTIFACT_DIR/build_status"
    exit 0
fi

# ---------------------------------------------------------------------------
# 4. Build from source
# ---------------------------------------------------------------------------
echo "Changes detected (or no previous build). Compiling from scratch..."
BUILD_DIR="/home/builder/build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

git clone https://aur.archlinux.org/noctalia-git.git
cd noctalia-git
makepkg -s --noconfirm

# Copy the built package to the artifact directory
cp ./*.pkg.tar.zst "$ARTIFACT_DIR/"

# Store the full upstream commit so the repo-creation step can use it
echo "$LATEST_COMMIT" > "$ARTIFACT_DIR/LATEST_COMMIT"
