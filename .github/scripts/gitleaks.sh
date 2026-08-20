#!/bin/sh

set -eu

version="8.30.1"
os="$(uname -s)"
arch="$(uname -m)"

case "${os}-${arch}" in
  Darwin-arm64)
    platform="darwin_arm64"
    checksum="b40ab0ae55c505963e365f271a8d3846efbc170aa17f2607f13df610a9aeb6a5"
    ;;
  Darwin-x86_64)
    platform="darwin_x64"
    checksum="dfe101a4db2255fc85120ac7f3d25e4342c3c20cf749f2c20a18081af1952709"
    ;;
  Linux-aarch64 | Linux-arm64)
    platform="linux_arm64"
    checksum="e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080"
    ;;
  Linux-x86_64)
    platform="linux_x64"
    checksum="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"
    ;;
  *)
    echo "Unsupported Gitleaks platform: ${os}-${arch}" >&2
    exit 1
    ;;
esac

cache_dir="_build/tools/gitleaks/v${version}/${platform}"
binary="${cache_dir}/gitleaks"
archive="${cache_dir}/gitleaks.tar.gz"
url="https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_${platform}.tar.gz"
download=""
install_dir=""

cleanup() {
  if [ -n "${download}" ]; then
    rm -f "${download}"
  fi

  if [ -n "${install_dir}" ]; then
    rm -f "${install_dir}/gitleaks"
    rmdir "${install_dir}" 2>/dev/null || true
  fi
}

verify_checksum() {
  file="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    actual_checksum="$(sha256sum "${file}" | cut -d ' ' -f 1)"
  else
    actual_checksum="$(shasum -a 256 "${file}" | cut -d ' ' -f 1)"
  fi

  if [ "${actual_checksum}" != "${checksum}" ]; then
    echo "Gitleaks archive checksum mismatch for ${platform}" >&2
    exit 1
  fi
}

trap cleanup EXIT HUP INT TERM

mkdir -p "${cache_dir}"

if [ ! -f "${archive}" ]; then
  download="$(mktemp "${cache_dir}/download.XXXXXX")"

  echo "Downloading Gitleaks v${version} for ${platform}..."
  curl \
    --connect-timeout 10 \
    --fail \
    --location \
    --max-time 120 \
    --retry 3 \
    --show-error \
    --silent \
    --output "${download}" \
    "${url}"

  verify_checksum "${download}"
  mv "${download}" "${archive}"
  download=""
fi

verify_checksum "${archive}"

# Refresh executable atomically from verified archive on every invocation. A
# cached executable is never trusted on its executable bit alone.
install_dir="$(mktemp -d "${cache_dir}/install.XXXXXX")"
tar -xzf "${archive}" -C "${install_dir}" gitleaks
chmod +x "${install_dir}/gitleaks"
mv "${install_dir}/gitleaks" "${binary}"
rmdir "${install_dir}"
install_dir=""

if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  echo "Gitleaks requires full Git history. Run: git fetch --unshallow" >&2
  exit 1
fi

exec "${binary}" git --redact --no-banner --no-color .
