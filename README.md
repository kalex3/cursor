# cursor

[![CI](https://github.com/kalex3/cursor/actions/workflows/ci.yml/badge.svg)](https://github.com/kalex3/cursor/actions/workflows/ci.yml)

Run the [Cursor Agent CLI](https://cursor.com/cli) in a lightweight, non-root Debian container.

> Unofficial. This repo only packages the Cursor Agent CLI; its use is subject to [Cursor's terms](https://cursor.com/terms-of-service).

## Usage

```sh
docker run --rm -it \
  -e CURSOR_API_KEY \
  -v "$PWD":/workspace \
  ghcr.io/kalex3/cursor:latest
```

Arguments are passed to `agent`, e.g. `... ghcr.io/kalex3/cursor:latest -p "explain this repo"`.

The container runs as UID 1000 (`cursor`). To persist login/config between runs, mount a volume at `/home/cursor/.cursor`
(and `/home/cursor/.config/cursor`). Files created in a bind mount are owned by UID 1000.

### Tags

| Tag | Meaning |
| --- | --- |
| `latest` | Latest build of `main` |
| `<agent-version>` (e.g. `2026.10.22-27dcf5f`) | Build of `main` with that Cursor Agent version; refreshed if only the base image changes |
| `sha-<commit>` | Immutable build of a specific commit |

For fully reproducible setups pin by digest (`ghcr.io/kalex3/cursor@sha256:...`).

### Docker Compose and rules

`compose.yaml` is a ready-to-use example: it pulls the prebuilt image from GHCR, mounts `./workspace` at `/workspace`,
mounts [`./rules`](rules) at `~/.cursor/rules` and [`./agents`](agents) at `~/.cursor/agents` (user-level rules and subagents,
so they apply to every project and don't touch the workspace), and persists login/state in named volumes.

Rules and agents are mounted **read-only**: they apply to every future session, so letting the agent edit them directly would let text injected
into one session (from a file or web page) persist. Instead, the agent can *propose* changes by writing complete files to
`~/proposals/{rules,agents}/` (mounted from [`./proposals`](proposals)), which you review and merge by hand:

```sh
diff -ru rules proposals/rules; diff -ru agents proposals/agents   # review
cp proposals/rules/some-rule.mdc rules/                            # accept (then commit)
rm -r proposals/rules/some-rule.mdc                                 # discard
```

The image itself ships `container.mdc` (what's installed in the container) as a user-level rule, so it also applies with a plain `docker run`.

```sh
cp .env.example .env   # set CURSOR_API_KEY (Dashboard -> API Keys), or leave it and run `agent login` in the container
docker compose run --rm cursor
```

Edit or add `.mdc` files in `rules/` and `.md` files in `agents/` to taste. Rules are kept small on purpose:
only the behaviour rules (`anti-sycophancy`, `anti-overengineering`) and `container` always apply; the rest attach by file glob
(Python/pandas, pytest, energy modelling, time-series validation, security, shell, Go, Rust, TypeScript/React, Docker).
Some are adapted from [awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) (CC0-1.0).
Subagents: `verifier`, `code-reviewer`, `security-auditor`, `model-auditor`, `test-writer`, `shell-reviewer`.

### Routing the agent through WireGuard

The compose example also starts [`ghcr.io/kalex3/wg`](https://github.com/kalex3/wg) and runs the agent with
`network_mode: service:wg`, so all of the agent's traffic (and DNS) leaves through the tunnel. Setup:

```sh
curl -fsSLO https://raw.githubusercontent.com/kalex3/wg/main/wg0.conf.example
cp wg0.conf.example wg0.conf && chmod 600 wg0.conf   # fill in keys/peers (git-ignored)
docker compose run --rm cursor                        # starts wg, waits until healthy, then the agent
docker compose down                                   # also stops the wg sidecar
```

Use `AllowedIPs = 0.0.0.0/0` in the config to force *everything* through the tunnel (only destinations covered by
`AllowedIPs` are tunnelled otherwise); the wg repo's example also has an optional kill switch.
The host needs the `wireguard` kernel module. To run without a VPN, remove `network_mode`, `depends_on` and the `wg` service.

### Build locally

```sh
docker build -t cursor .
docker run --rm cursor --version
```

## What's installed

The Cursor Agent CLI (with its bundled `rg`), plus `git`, `curl`, `gh` (GitHub CLI), `ripgrep`, `jq`, `pup`, `openssh-client`, `python3` (standard library only),
and basic utilities: `less`, `file`, `tree`, `diffutils`, `patch`, `findutils`, `unzip`, `zip`, `bzip2`, `xz-utils`, `procps`, `make`,
and network diagnostics (`iproute2`, `iputils-ping`, `bind9-dnsutils`). `ping` needs the `NET_RAW` capability (see `compose.yaml`).
`gh` comes from Debian's package (currently 2.46, older than upstream) and only works if you set `GH_TOKEN` (see `.env.example`;
use a fine-grained, repo-scoped token, since anything the agent runs can read it). Need more (Node, Go, compilers, ...)? Build a downstream image with `FROM ghcr.io/kalex3/cursor:latest`.

## What's pinned

| Component | How |
| --- | --- |
| Base image | `debian:13.7-slim` + digest (Dependabot) |
| Dockerfile frontend | `docker/dockerfile` tag + digest |
| Cursor Agent CLI | Exact version + per-arch SHA-256, verified at build time; also published as an image tag |
| GitHub Actions | Full commit SHAs (Dependabot) |
| apt packages | Not pinned (Debian drops old versions); reproducibility comes from the base digest |

## Automation

- **CI** (`ci.yml`): hadolint, multi-arch (amd64/arm64) build with GHA layer cache, SBOM and provenance attestations. Pushes to GHCR on `main` (`latest`, `<agent-version>`, `sha-<commit>`); pull requests only build and smoke-test.
- **Dependabot**: weekly updates for the Docker base image and GitHub Actions.
- **Update Cursor Agent** (`update-cursor-agent.yml`): daily check of the latest release; opens a PR bumping the version and checksums via `scripts/update-cursor-agent.sh`. Merging it publishes a new `<agent-version>` tag.

## Layer caching

The Cursor Agent download lives in its own stage, so the runtime stage's apt layer is not invalidated by agent bumps, and apt downloads use BuildKit cache mounts.

## License

[MIT](LICENSE)
