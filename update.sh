#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://debrepo.freedownloadmanager.org/pool/main/f/freedownloadmanager/"
DERIVATION="$(dirname "$0")/package.nix"

echo "Fetching directory listing..."
LISTING=$(curl -fsSL "$REPO_URL")

NEW_VERSION=$(echo "$LISTING" \
  | grep -oP 'freedownloadmanager_\K[\d.]+(?=_amd64\.deb)' \
  | sort -V \
  | tail -1)

DEB_URL="${REPO_URL}freedownloadmanager_${NEW_VERSION}_amd64.deb"

OLD_VERSION=$(grep -oP '(?<=version = ")[\d.]+' "$DERIVATION")

if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
  echo "Already at latest ($OLD_VERSION), nothing to do."
  exit 0
fi

echo "Updating $OLD_VERSION → $NEW_VERSION"
echo "Fetching/hashing: $DEB_URL"

HEX=$(curl -fsSL "$DEB_URL" | sha256sum | cut -d' ' -f1)
NEW_HASH="sha256-$(echo "$HEX" | xxd -r -p | base64 -w0)"

echo "New hash: $NEW_HASH"

sed -i "s|version = \"${OLD_VERSION}\"|version = \"${NEW_VERSION}\"|" "$DERIVATION"
sed -i "s|hash = \"sha256-.*\"|hash = \"${NEW_HASH}\"|" "$DERIVATION"

echo "Done. Diff:"
if [ -t 1 ]; then
  git diff "$DERIVATION"
fi
