# syntax=docker/dockerfile:1.28@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

# Version + checksums are bumped by scripts/update-cursor-agent.sh
# (run daily by .github/workflows/update-cursor-agent.yml).
ARG CURSOR_AGENT_VERSION=2026.10.22-27dcf5f
ARG CURSOR_AGENT_SHA256_X64=85296944e4600a83c4b764f578d1502bf9c416db200d33a593e8f3ecabfdc294
ARG CURSOR_AGENT_SHA256_ARM64=22a36df9720830668ccd4d707e5190204ab9c8a0efb2f068cc914895f804d3ec

# ---------------------------------------------------------------------------
# Base: Debian 13 (trixie) slim, pinned by tag and digest (Dependabot bumps both).
# apt is configured to keep downloaded .debs so BuildKit cache mounts are effective.
# ---------------------------------------------------------------------------
FROM debian:13.7-slim@sha256:62bd423aeee912639ca8ee681c2b762cb3e25137e0a92b20be455898a9f034ad AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# ---------------------------------------------------------------------------
# Stage 1: download and verify the Cursor Agent CLI package.
# Kept separate so the runtime image doesn't carry the tarball or build tools,
# and so this layer is only rebuilt when the pinned version/checksums change.
# ---------------------------------------------------------------------------
FROM base AS fetch

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl

ARG CURSOR_AGENT_VERSION
ARG CURSOR_AGENT_SHA256_X64
ARG CURSOR_AGENT_SHA256_ARM64
ARG TARGETARCH

RUN <<EOF
set -eu
case "${TARGETARCH}" in
  amd64) arch=x64;   sha256="${CURSOR_AGENT_SHA256_X64}" ;;
  arm64) arch=arm64; sha256="${CURSOR_AGENT_SHA256_ARM64}" ;;
  *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;;
esac
curl -fsSL --retry 5 --retry-all-errors \
  -o /tmp/agent.tar.gz \
  "https://downloads.cursor.com/lab/${CURSOR_AGENT_VERSION}/linux/${arch}/agent-cli-package.tar.gz"
echo "${sha256}  /tmp/agent.tar.gz" | sha256sum --check --strict -
mkdir -p "/opt/cursor-agent/${CURSOR_AGENT_VERSION}"
tar --strip-components=1 -xzf /tmp/agent.tar.gz -C "/opt/cursor-agent/${CURSOR_AGENT_VERSION}"
ln -s "${CURSOR_AGENT_VERSION}" /opt/cursor-agent/current
EOF

# ---------------------------------------------------------------------------
# Stage 2: runtime image.
# Ordered from least to most frequently changing for best layer caching:
# OS packages -> user -> agent files -> metadata.
# ---------------------------------------------------------------------------
FROM base AS runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG=C.UTF-8 \
    TERM=xterm-256color

# Debian point releases drop old package versions from the mirrors, so apt
# packages are not version-pinned; reproducibility comes from the base digest.
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        diffutils \
        file \
        findutils \
        gh \
        git \
        jq \
        less \
        openssh-client \
        patch \
        procps \
        pup \
        python3 \
        ripgrep \
        tree \
        unzip \
        xz-utils \
    && useradd --create-home --uid 1000 --shell /bin/bash cursor \
    && install -d -o cursor -g cursor /workspace

COPY --from=fetch --chown=cursor:cursor /opt/cursor-agent /home/cursor/.local/share/cursor-agent/versions

USER 1000:1000
WORKDIR /workspace

# Mirror the layout created by the official installer (agent + cursor-agent symlinks).
# Also pre-create state dirs owned by `cursor` so named volumes mounted there are writable.
RUN mkdir -p ~/.local/bin ~/.cursor/rules ~/.cursor/agents ~/proposals ~/.config/cursor \
    && ln -s ../share/cursor-agent/versions/current/cursor-agent ~/.local/bin/agent \
    && ln -s ../share/cursor-agent/versions/current/cursor-agent ~/.local/bin/cursor-agent

# Describes this image to the agent as a user-level rule (~/.cursor/rules is read for all projects).
# Single source of truth: the same file is what the compose example mounts over this directory.
COPY --chown=1000:1000 rules/container.mdc /home/cursor/.cursor/rules/container.mdc

ENV PATH="/home/cursor/.local/bin:${PATH}"

ARG CURSOR_AGENT_VERSION
LABEL org.opencontainers.image.title="cursor" \
      org.opencontainers.image.description="Cursor Agent CLI in a lightweight Debian container" \
      org.opencontainers.image.source="https://github.com/kalex3/cursor" \
      org.opencontainers.image.licenses="MIT" \
      io.cursor.agent.version="${CURSOR_AGENT_VERSION}"

ENTRYPOINT ["agent"]
