#!/usr/bin/env bash
# Bump the pinned Cursor Agent version and per-arch SHA-256 checksums in the Dockerfile
# to whatever https://cursor.com/install currently points at.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

dockerfile=Dockerfile
base_url=https://downloads.cursor.com/lab

version="$(
  curl -fsSL --retry 5 --retry-all-errors https://cursor.com/install \
    | grep -oE 'downloads\.cursor\.com/lab/[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9a-f]+' \
    | head -n1 | sed 's|.*/lab/||'
)"
[[ -n "${version}" ]] || { echo "Could not determine latest version" >&2; exit 1; }

current="$(sed -n 's/^ARG CURSOR_AGENT_VERSION=//p' "${dockerfile}")"
echo "current=${current} latest=${version}"

if [[ "${current}" == "${version}" ]]; then
  echo "Already up to date."
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

sha256_for() {
  local arch=$1 published actual
  local url="${base_url}/${version}/linux/${arch}/agent-cli-package.tar.gz"
  curl -fsSL --retry 5 --retry-all-errors "${url}.sha256" -o "${tmp}/${arch}.sha256"
  curl -fsSL --retry 5 --retry-all-errors "${url}" -o "${tmp}/${arch}.tar.gz"
  published="$(awk 'NR==1 { print $1 }' "${tmp}/${arch}.sha256")"
  [[ "${published}" =~ ^[0-9a-f]{64}$ ]] || {
    echo "published checksum for ${arch} is not 64 hex chars" >&2
    exit 1
  }
  actual="$(sha256sum "${tmp}/${arch}.tar.gz" | awk '{ print $1 }')"
  [[ "${published}" == "${actual}" ]] || {
    echo "checksum mismatch for ${arch}" >&2
    exit 1
  }
  printf '%s\n' "${published}"
}

x64="$(sha256_for x64)"
arm64="$(sha256_for arm64)"

sed -i \
  -e "s|^ARG CURSOR_AGENT_VERSION=.*|ARG CURSOR_AGENT_VERSION=${version}|" \
  -e "s|^ARG CURSOR_AGENT_SHA256_X64=.*|ARG CURSOR_AGENT_SHA256_X64=${x64}|" \
  -e "s|^ARG CURSOR_AGENT_SHA256_ARM64=.*|ARG CURSOR_AGENT_SHA256_ARM64=${arm64}|" \
  "${dockerfile}"

echo "Updated ${dockerfile} to ${version}"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "version=${version}" >> "${GITHUB_OUTPUT}"
fi
