#!/usr/bin/env bash
# Rewrite the pinned Claude Code version + checksums in package.nix.
# Usage: ./update.sh [latest|stable|X.Y.Z]   (or: nix run .#update -- ...)

set -euo pipefail

BASE_URL="https://downloads.claude.ai/claude-code-releases"
CHANNEL="${1:-latest}"
PKG="package.nix"

if [[ ! -f "$PKG" ]]; then
  echo "error: $PKG not found — run from the repository root." >&2
  exit 1
fi

if [[ "$CHANNEL" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.]+)?$ ]]; then
  version="$CHANNEL"
elif [[ "$CHANNEL" == "latest" || "$CHANNEL" == "stable" ]]; then
  version="$(curl -fsSL "$BASE_URL/$CHANNEL")"
else
  echo "error: channel must be 'latest', 'stable', or a version like 2.1.195 (got: $CHANNEL)" >&2
  exit 1
fi

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
  echo "error: resolved an invalid version: '$version'" >&2
  exit 1
fi

current="$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$PKG" | head -n1)"
if [[ "$version" == "$current" ]]; then
  echo "Already pinned to $version (channel: $CHANNEL) — nothing to do."
  exit 0
fi

echo "Updating Claude Code pin: ${current:-none} -> $version (channel: $CHANNEL)"

manifest="$(curl -fsSL "$BASE_URL/$version/manifest.json")"

checksum_for() {
  local platform="$1" sum
  sum="$(printf '%s' "$manifest" | jq -r ".platforms[\"$platform\"].checksum // empty")"
  if [[ ! "$sum" =~ ^[a-f0-9]{64}$ ]]; then
    echo "error: no valid checksum for $platform in manifest $version" >&2
    exit 1
  fi
  printf '%s' "$sum"
}

arm64_sum="$(checksum_for darwin-arm64)"
x64_sum="$(checksum_for darwin-x64)"

tmp="$(mktemp "${PKG}.new.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
sed \
  -e "s|version = \"[^\"]*\"|version = \"$version\"|" \
  -e "s|darwin-arm64 = \"[^\"]*\"|darwin-arm64 = \"$arm64_sum\"|" \
  -e "s|darwin-x64 = \"[^\"]*\"|darwin-x64 = \"$x64_sum\"|" \
  "$PKG" >"$tmp"
cat "$tmp" >"$PKG"

echo "  version       $version"
echo "  darwin-arm64  $arm64_sum"
echo "  darwin-x64    $x64_sum"
echo "Done. Review with: git diff $PKG"
