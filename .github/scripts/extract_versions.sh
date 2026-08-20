#!/bin/bash

# Extract versions from mix.exs for GitHub Actions
# This script parses mix.exs without requiring Elixir to be installed

set -e

# Function to extract Elixir version from mix.exs
extract_elixir_version() {
    if [[ ! -f "mix.exs" ]]; then
        echo "1.20"  # fallback
        return
    fi

    # Extract the elixir version line from mix.exs
    local elixir_line=$(grep -E '^\s*elixir:' mix.exs | head -1)

    if [[ -z "$elixir_line" ]]; then
        echo "1.20"  # fallback
        return
    fi

    # Parse different version formats - handle spaces and quotes flexibly
    # Handle RC versions first
    if [[ $elixir_line =~ \"~\>[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+)[[:space:]]*\" ]]; then
        # "~> 1.19.0-rc.4" format
        echo "${BASH_REMATCH[1]}"
    elif [[ $elixir_line =~ \"~\>[[:space:]]*([0-9]+\.[0-9]+)[[:space:]]*\" ]]; then
        # "~> 1.15" format
        echo "${BASH_REMATCH[1]}.0"
    elif [[ $elixir_line =~ \"~\>[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)[[:space:]]*\" ]]; then
        # "~> 1.15.0" format
        echo "${BASH_REMATCH[1]}"
    elif [[ $elixir_line =~ \"\>\=[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)[[:space:]]*\" ]]; then
        # ">= 1.15.0" format
        echo "${BASH_REMATCH[1]}"
    elif [[ $elixir_line =~ \"\>\=[[:space:]]*([0-9]+\.[0-9]+)[[:space:]]*\" ]]; then
        # ">= 1.15" format
        echo "${BASH_REMATCH[1]}.0"
    elif [[ $elixir_line =~ \"([0-9]+\.[0-9]+\.[0-9]+)\" ]]; then
        # Direct version "1.15.0" format
        echo "${BASH_REMATCH[1]}"
    elif [[ $elixir_line =~ \"([0-9]+\.[0-9]+)\" ]]; then
        # Direct version "1.15" format
        echo "${BASH_REMATCH[1]}.0"
    else
        echo "1.20"  # fallback
    fi
}

# Function to get OTP version from JSON mapping
get_otp_version() {
    local elixir_version=$1
    # Extract major.minor version (handle RC versions like 1.19.0-rc.4)
    local elixir_major_minor
    if [[ $elixir_version =~ ^([0-9]+\.[0-9]+) ]]; then
        elixir_major_minor="${BASH_REMATCH[1]}"
    else
        elixir_major_minor="${elixir_version%.*}"  # fallback to removing patch version
    fi

    if [[ ! -f ".github/workflows/elixir_version_to_otp_version.json" ]]; then
        echo "28.3"  # fallback
        return
    fi

    # Use jq if available, otherwise parse manually
    if command -v jq >/dev/null 2>&1; then
        local otp_version=$(jq -r ".[\"$elixir_major_minor\"] // empty" .github/workflows/elixir_version_to_otp_version.json)
        if [[ -n "$otp_version" && "$otp_version" != "null" ]]; then
            echo "$otp_version"
        else
            echo "28.3"  # fallback
        fi
    else
        # Manual parsing without jq
        local mapping_line=$(grep "\"$elixir_major_minor\":" .github/workflows/elixir_version_to_otp_version.json)
        if [[ $mapping_line =~ \"([0-9]+\.[0-9]+)\" ]]; then
            echo "${BASH_REMATCH[1]}"
        else
            echo "28.3"  # fallback
        fi
    fi
}

# Function to extract Node.js version from various sources
extract_node_version() {
    # Try .tool-versions first
    if [[ -f ".tool-versions" ]]; then
        local node_version=$(grep -E "^(nodejs|node)\s+" .tool-versions | awk '{print $2}' | head -1)
        if [[ -n "$node_version" ]]; then
            echo "$node_version" | cut -d'.' -f1  # Return major version
            return
        fi
    fi

    # Try assets/package.json
    if [[ -f "assets/package.json" ]]; then
        local node_version=$(grep -E '"node":\s*"[^"]+' assets/package.json | sed -E 's/.*"node":\s*"([^"]+)".*/\1/' | sed -E 's/[^0-9.].*//' | cut -d'.' -f1)
        if [[ -n "$node_version" ]]; then
            echo "$node_version"
            return
        fi
    fi

    # Try .nvmrc
    if [[ -f ".nvmrc" ]]; then
        local node_version=$(cat .nvmrc | tr -d 'v' | cut -d'.' -f1)
        if [[ -n "$node_version" ]]; then
            echo "$node_version"
            return
        fi
    fi

    echo "20"  # LTS default
}

# Extract versions
ELIXIR_VERSION=$(extract_elixir_version)
OTP_VERSION=$(get_otp_version "$ELIXIR_VERSION")
NODE_VERSION=$(extract_node_version)

# Output for debugging
echo "Extracted versions:"
echo "  Elixir: $ELIXIR_VERSION"
echo "  OTP: $OTP_VERSION"
echo "  Node.js: $NODE_VERSION"

# Output for GitHub Actions
if [[ -n "$GITHUB_OUTPUT" ]]; then
    echo "elixir=$ELIXIR_VERSION" >> "$GITHUB_OUTPUT"
    echo "otp=$OTP_VERSION" >> "$GITHUB_OUTPUT"
    echo "node=$NODE_VERSION" >> "$GITHUB_OUTPUT"
else
    echo "elixir=$ELIXIR_VERSION"
    echo "otp=$OTP_VERSION"
    echo "node=$NODE_VERSION"
fi
