#!/bin/bash
# build.sh — Check for upstream changes and compile noctalia-git if needed.
# This script runs as the unprivileged 'builder' user inside an Arch container.
set -euo pipefail

ARTIFACT_DIR="/tmp/artifact"
mkdir -p "$ARTIFACT_DIR"

# ---------------------------------------------------------------------------
# 1. Determine latest upstream commit (full 40-char SHA)
# ---------------------------------------------------------------------------
LATEST_COMMIT=$(timeout 60 git ls-remote https://github.com/noctalia-dev/noctalia HEAD | awk '{print $1}')
echo "Upstream HEAD: $LATEST_COMMIT"

# ---------------------------------------------------------------------------
# 2. Check currently deployed commit from GitHub Pages
# ---------------------------------------------------------------------------
REPO_URL="https://${GITHUB_REPOSITORY_OWNER}.github.io/${GITHUB_REPOSITORY#*/}"

DEPLOYED_COMMIT=$(curl --retry 3 --retry-delay 5 -sfS "$REPO_URL/COMMIT" 2>/dev/null || true)
if [ -z "$DEPLOYED_COMMIT" ]; then
    echo "WARNING: Could not fetch deployed commit from $REPO_URL/COMMIT — assuming first run."
    DEPLOYED_COMMIT="none"
fi
echo "Deployed commit: $DEPLOYED_COMMIT"

# ---------------------------------------------------------------------------
# 3. Compare full SHAs — skip build if unchanged
# ---------------------------------------------------------------------------
if [[ "$LATEST_COMMIT" == "$DEPLOYED_COMMIT" ]]; then
    echo "No changes detected. Re-using existing package from GitHub Pages."
    cd "$ARTIFACT_DIR"

    for file in noctalia.db noctalia.db.tar.gz noctalia.files noctalia.files.tar.gz; do
        echo "Downloading $file ..."
        curl --retry 3 --retry-delay 5 -sfSO "$REPO_URL/$file" || { echo "ERROR: Failed to download $file"; exit 1; }
    done

    # Extract package filename from the repo database
    tmpdir=$(mktemp -d)
    tar -xf noctalia.db -C "$tmpdir"
    # Guard against zero or multiple matches — either would silently produce wrong results
    shopt -s nullglob
    desc_files=("$tmpdir"/noctalia-git-*/desc)
    shopt -u nullglob
    desc_count=${#desc_files[@]}
    if [ "$desc_count" -ne 1 ]; then
        echo "ERROR: Expected exactly 1 noctalia-git entry in database, found $desc_count"
        exit 1
    fi
    PKG_NAME=$(awk '/%FILENAME%/{g=1;next} g{print;g=0}' "$tmpdir"/noctalia-git-*/desc | head -n 1)
    rm -rf "$tmpdir"
    echo "Downloading $PKG_NAME ..."
    curl --retry 3 --retry-delay 5 -sfSO "$REPO_URL/$PKG_NAME" || { echo "ERROR: Failed to download $PKG_NAME"; exit 1; }
    curl --retry 3 --retry-delay 5 -sfSO "$REPO_URL/index.html" || { echo "ERROR: Failed to download index.html"; exit 1; }
    curl --retry 3 --retry-delay 5 -sfSO "$REPO_URL/COMMIT" || { echo "ERROR: Failed to download COMMIT"; exit 1; }

    # Download GPG signatures and public key if present on GitHub Pages
    for sigfile in "$PKG_NAME.sig" noctalia.db.sig noctalia.db.tar.gz.sig noctalia.files.sig noctalia.files.tar.gz.sig noctalia-signing-key.gpg; do
        curl --retry 3 --retry-delay 5 -sfSO "$REPO_URL/$sigfile" 2>/dev/null || true
    done

    # Verify checksums
    if curl --retry 3 --retry-delay 5 -sfS "$REPO_URL/SHA256SUMS" -o SHA256SUMS 2>/dev/null; then
        echo "Verifying checksums..."
        sha256sum -c SHA256SUMS || { echo "ERROR: Checksum verification failed!"; exit 1; }
    else
        echo "WARNING: No SHA256SUMS found on remote — skipping verification."
    fi

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

# Pin to a known-good AUR PKGBUILD commit to prevent silent supply-chain tampering.
# Update this SHA when intentionally pulling in new PKGBUILD changes.
AUR_PKGBUILD_COMMIT="a9cf022647ee12270fb1c8e1b3ca7b2bd677eb5c"
timeout 120 git clone https://aur.archlinux.org/noctalia-git.git
cd noctalia-git
git checkout "$AUR_PKGBUILD_COMMIT"
makepkg -s --noconfirm

# Copy the built package to the artifact directory
cp ./*.pkg.tar.zst "$ARTIFACT_DIR/"

# Store the full upstream commit so the repo-creation step can use it
echo "$LATEST_COMMIT" > "$ARTIFACT_DIR/LATEST_COMMIT"
