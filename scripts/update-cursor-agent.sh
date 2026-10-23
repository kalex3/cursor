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
  curl -fsSL --retry 5 --retry-all-errors \
    "${base_url}/${version}/linux/$1/agent-cli-package.tar.gz" -o "${tmp}/$1.tar.gz"
  sha256sum "${tmp}/$1.tar.gz" | cut -d' ' -f1
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
