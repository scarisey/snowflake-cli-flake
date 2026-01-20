#!/usr/bin/env bash
set -euo pipefail

# Update script for snowflake-cli package
# Fetches the latest release from GitHub and updates package.nix

REPO_OWNER="snowflakedb"
REPO_NAME="snowflake-cli"
PACKAGE_FILE="package.nix"

echo "Fetching latest release from GitHub..."

# Fetch latest release information
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest")

# Extract version (remove 'v' prefix if present)
LATEST_VERSION=$(echo "$LATEST_RELEASE" | jq -r '.tag_name' | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    echo "Error: Could not fetch latest version"
    exit 1
fi

echo "Latest version: $LATEST_VERSION"

# Get current version from package.nix
CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' "$PACKAGE_FILE" || echo "unknown")
echo "Current version: $CURRENT_VERSION"

if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
    echo "Already at latest version!"
    exit 0
fi

echo "Updating from $CURRENT_VERSION to $LATEST_VERSION..."

# Fetch new hash
echo "Calculating hash for version $LATEST_VERSION..."
NEW_HASH=$(nix-prefetch-url --unpack "https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/tags/v${LATEST_VERSION}.tar.gz" 2>/dev/null)
NEW_HASH_SRI=$(nix-hash --type sha256 --to-sri "$NEW_HASH")

echo "New hash: $NEW_HASH_SRI"

# Update package.nix
echo "Updating $PACKAGE_FILE..."

# Update version
sed -i "s/version = \".*\";/version = \"$LATEST_VERSION\";/" "$PACKAGE_FILE"

# Update hash
sed -i "s|hash = \"sha256-.*\";|hash = \"$NEW_HASH_SRI\";|" "$PACKAGE_FILE"

echo "✅ Successfully updated to version $LATEST_VERSION"
echo ""
echo "Please verify the changes with: git diff $PACKAGE_FILE"
echo "Then test the build with: nix build"
