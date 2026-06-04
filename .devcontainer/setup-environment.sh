#!/bin/bash
set -e

# Get the directory containing this script
SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Detect architecture and set DOCKER_DEFAULT_PLATFORM
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    DOCKER_DEFAULT_PLATFORM="linux/amd64"
elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    DOCKER_DEFAULT_PLATFORM="linux/arm64"
else
    printf "========================================\r\n" >&2
    printf "DEVCONTAINER SETUP FAILED\r\n" >&2
    printf "========================================\r\n" >&2
    printf "\r\n" >&2
    printf "ERROR: Unsupported architecture\r\n" >&2
    printf "\r\n" >&2
    printf "Supported architectures: x86_64, arm64, aarch64\r\n" >&2
    printf "\r\n" >&2
    printf "========================================\r\n" >&2
    exit 1
fi

# Check for mkcert installation
if ! command -v mkcert &> /dev/null; then
    printf "========================================\r\n" >&2
    printf "DEVCONTAINER SETUP FAILED\r\n" >&2
    printf "========================================\r\n" >&2
    printf "\r\n" >&2
    printf "ERROR: mkcert is not installed\r\n" >&2
    printf "\r\n" >&2
    printf "This devcontainer requires mkcert for SSL certificates.\r\n" >&2
    printf "\r\n" >&2
    printf "Install mkcert:\r\n" >&2
    printf "  macOS:   brew install mkcert\r\n" >&2
    printf "  Linux:   See https://github.com/FiloSottile/mkcert#installation\r\n" >&2
    printf "  Windows: choco install mkcert\r\n" >&2
    printf "\r\n" >&2
    printf "After installing mkcert, rebuild the devcontainer.\r\n" >&2
    printf "\r\n" >&2
    printf "========================================\r\n" >&2
    exit 1
fi

# Get git config from host
GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

# Read environment variables from root .env file
CURSOR_API_KEY=""
if [ -f "$ROOT_DIR/.env" ]; then
    CURSOR_API_KEY=$(grep '^CURSOR_API_KEY=' "$ROOT_DIR/.env" | cut -d '=' -f 2- | tr -d '"' || echo "")
fi

echo "✓ mkcert is installed"
echo "✓ Detected architecture: $ARCH"

# Append KEY=VALUE to $ENV_FILE only if KEY is not already defined there.
# Returns 0 if appended, 1 if skipped (already present).
ENV_FILE="$SCRIPT_DIR/.env"
set_env_var_if_missing() {
    local key="$1"
    local value="$2"
    if [ -f "$ENV_FILE" ] && grep -q "^${key}=" "$ENV_FILE"; then
        return 1
    fi
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
    return 0
}

env_var_exists() {
    [ -f "$ENV_FILE" ] && grep -q "^${1}=" "$ENV_FILE"
}

# Target environment variables to write to $ENV_FILE.
#
# Each entry is a tuple of parallel arrays:
#   ENV_KEYS:         the variable name as written to $ENV_FILE
#   ENV_VALUES:       the value to write when the key is not already present
#   ENV_MISSING_MSGS: warning to print when the value is empty AND the key is
#                     not yet present in $ENV_FILE; leave empty for variables
#                     that are always expected to have a value.
ENV_KEYS=(
    "DOCKER_DEFAULT_PLATFORM"
    "HOST_UID"
    "HOST_GID"
    "GIT_USER_NAME"
    "GIT_USER_EMAIL"
    "CLAUDE_CODE_OAUTH_TOKEN"
    "CURSOR_API_KEY"
    "GITHUB_TOKEN"
)
ENV_VALUES=(
    "$DOCKER_DEFAULT_PLATFORM"
    "$(id -u)"
    "$(id -g)"
    "$GIT_USER_NAME"
    "$GIT_USER_EMAIL"
    "$CLAUDE_CODE_OAUTH_TOKEN"
    "$CURSOR_API_KEY"
    "$GITHUB_TOKEN"
)
ENV_MISSING_MSGS=(
    ""
    ""
    ""
    "No git user.name configured on host"
    "No git user.email configured on host"
    "CLAUDE_CODE_OAUTH_TOKEN not found in local environment"
    "CURSOR_API_KEY not found in $ROOT_DIR/.env (wrote empty value)"
    "GITHUB_TOKEN not found in local environment"
)

for i in "${!ENV_KEYS[@]}"; do
    key="${ENV_KEYS[$i]}"
    value="${ENV_VALUES[$i]}"
    missing_msg="${ENV_MISSING_MSGS[$i]}"

    if env_var_exists "$key"; then
        echo "✓ ${key} already set in $ENV_FILE, leaving unchanged"
        continue
    fi

    set_env_var_if_missing "$key" "$value" >/dev/null

    if [ -n "$value" ]; then
        echo "✓ Set ${key}=${value}"
    elif [ -n "$missing_msg" ]; then
        echo "⚠ ${missing_msg}"
    else
        echo "✓ Set ${key}="
    fi
done
