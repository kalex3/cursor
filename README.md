# cursor-docker

[![CI](https://github.com/kalex3/cursor-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/kalex3/cursor-docker/actions/workflows/ci.yml)

Run the [Cursor Agent CLI](https://cursor.com/cli) in a lightweight, non-root Debian container.

> Unofficial. This repo only packages the Cursor Agent CLI; its use is subject to [Cursor's terms](https://cursor.com/terms-of-service).

## Usage

```sh
docker run --rm -it \
  -e CURSOR_API_KEY \
  -v "$PWD":/workspace -w /workspace \
  ghcr.io/kalex3/cursor-docker:edge
```

Arguments are passed to `agent`, e.g. `... ghcr.io/kalex3/cursor-docker:edge -p "explain this repo"`.

The container runs as UID 1000 (`cursor`). To persist login/config between runs, mount a volume at `/home/cursor/.cursor`
(and `/home/cursor/.config/cursor` if needed). Files created in a bind mount are owned by UID 1000.

### Build locally

```sh
docker build -t cursor-docker .
docker run --rm cursor-docker --version
```

## What's pinned

| Component | How |
| --- | --- |
| Base image | `debian:13.7-slim` + digest (Dependabot) |
| Dockerfile frontend | `docker/dockerfile` tag + digest |
| Cursor Agent CLI | Exact version + per-arch SHA-256, verified at build time |
| GitHub Actions | Full commit SHAs (Dependabot) |
| apt packages | Not pinned (Debian drops old versions); reproducibility comes from the base digest |

## Automation

- **CI** (`ci.yml`): hadolint, multi-arch (amd64/arm64) build with GHA layer cache, SBOM and provenance attestations; pushes to GHCR on `main` and `v*` tags.
- **Dependabot**: weekly updates for the Docker base image and GitHub Actions.
- **Update Cursor Agent** (`update-cursor-agent.yml`): daily check of the latest release; opens a PR bumping the version and checksums via `scripts/update-cursor-agent.sh`.

## Layer caching

The Cursor Agent download lives in its own stage, so the runtime stage's apt layer is not invalidated by agent bumps, and apt downloads use BuildKit cache mounts.

## License

[MIT](LICENSE)
