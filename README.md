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
Passing `worker start` runs a [self-hosted Cloud Agent machine](https://cursor.com/docs/cloud-agent/self-hosted): the entrypoint is `agent`, so this is `agent worker start`, and the container stays up for Cursor to send it tool calls.

```sh
docker run -d --name cursor-worker \
  -e CURSOR_API_KEY \
  -v "$PWD":/workspace \
  ghcr.io/kalex3/cursor:latest \
  worker start
```

The container runs as UID 1000 (`cursor`). To persist login/config between runs, mount a volume at `/home/cursor/.cursor`
(and `/home/cursor/.config/cursor`). Files created in a bind mount are owned by UID 1000.

### Tags

| Tag | Meaning |
| --- | --- |
| `latest` | Latest build of `main` |
| `sha-<commit>` | Immutable build of a specific commit |

For fully reproducible setups pin by digest (`ghcr.io/kalex3/cursor@sha256:...`).

### Docker Compose and rules

`compose.yaml` is a ready-to-use example: it pulls the prebuilt image from GHCR, mounts `./workspace` at `/workspace`,
mounts [`./rules`](rules) at `~/.cursor/rules`, [`./skills`](skills) at `~/.cursor/skills`, and [`./agents`](agents) at `~/.cursor/agents` (user-level rules, skills, and subagents,
so they apply to every project and don't touch the workspace), mounts [`cli-config.json`](cli-config.json) over the CLI preferences, and persists login/state in named volumes.

Rules, skills, and agents are mounted **read-only**: they apply to every future session, so letting the agent edit them directly would let text injected
into one session (from a file or web page) persist. Instead, the agent can *propose* changes by writing complete files to
`~/proposals/{rules,skills,agents}/` (mounted from [`./proposals`](proposals)), which you review and merge by hand:

```sh
diff -ru rules proposals/rules; diff -ru skills proposals/skills; diff -ru agents proposals/agents   # review
cp proposals/rules/some-rule.mdc rules/                            # accept (then commit)
rm -r proposals/rules/some-rule.mdc                                 # discard
```

The image itself ships `container.mdc` (what's installed in the container) as a user-level rule, so it also applies with a plain `docker run`.

```sh
cp .env.example .env   # set CURSOR_API_KEY (Dashboard -> API Keys), or leave it and run `agent login` in the container
docker compose up -d   # `agent worker start`: a self-hosted Cloud Agent machine
```

A one-off interactive session replaces that command: `docker compose run --rm -it cursor -p "explain this repo"`.

Edit or add `.mdc` files in `rules/` and `.md` files in `agents/` to taste. Rules are kept small on purpose:
the always-on rules are `anti-sycophancy`, `anti-overengineering`, `container`, `karpathy-guidelines`, `leave-commits`, and `no-ai-attribution`; the rest attach by file glob
(Python/pandas, pytest, energy modelling, time-series validation, security, shell, Go, Rust, TypeScript/React, Docker).
Some are adapted from [awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) (CC0-1.0).
Subagents: `verifier`, `code-reviewer`, `security-auditor`, `model-auditor`, `test-writer`, `shell-reviewer`.
Skills: `karpathy-guidelines`, `ask-questions-if-underspecified`, `systematic-debugging`, `web-design-guidelines`.
`cli-config.json` sets vim mode, the Grok 4.7 256K High Fast default, an allowlist approval mode (only `Shell(ls)` is pre-approved), and turns commit and PR attribution off.

### Routing the agent through WireGuard

The compose example also starts [`ghcr.io/kalex3/wg`](https://github.com/kalex3/wg) and runs the agent with
`network_mode: service:wg`, so all of the agent's traffic (and DNS) leaves through the tunnel. Setup:

```sh
curl -fsSLO https://raw.githubusercontent.com/kalex3/wg/main/wg0.conf.example
cp wg0.conf.example wg0.conf && chmod 600 wg0.conf   # fill in keys/peers (git-ignored)
docker compose up -d                                 # starts wg, waits until healthy, then the worker
docker compose down                                   # also stops the wg sidecar
```

Use `AllowedIPs = 0.0.0.0/0` in the config to force *everything* through the tunnel (only destinations covered by
`AllowedIPs` are tunnelled otherwise). Set `WG_KILLSWITCH: "true"` on the `wg` service to reject traffic that would bypass that tunnel.
The host needs the `wireguard` kernel module. To run without a VPN, remove `network_mode`, `depends_on` and the `wg` service.

### Installing extra tools temporarily

The agent runs as the unprivileged `cursor` user and can't install packages. When it needs one, its rules make it ask you for a
temporary install, which you grant from the host with a root `exec` into the running service:

```sh
docker compose exec -u root cursor sh -c 'apt-get update && apt-get install -y --no-install-recommends jq'
```

`-u root` overrides the image's `USER`, and no `sudo` is needed. Installed packages live in that container's writable layer:
they survive a restart but disappear when the container is removed. With the WireGuard sidecar,
`apt` goes through the tunnel too. To make a tool permanent, add it to the `Dockerfile` or build a downstream image.

### Build locally

```sh
docker build -t cursor .
docker run --rm cursor --version
```

## What's installed

The Cursor Agent CLI (with its bundled `rg`), plus `git`, `curl`, `gh` (GitHub CLI), `ripgrep`, `wget`, `jq`, `pup`, `openssh-client`, `python3` (standard library only),
and basic utilities: `less`, `file`, `tree`, `diffutils`, `patch`, `findutils`, `unzip`, `zip`, `bzip2`, `xz-utils`, `procps`, `make`, `xxd`, `bsdextrautils` (`hexdump`, `hd`, `column`, ...),
and network diagnostics (`iproute2`, `iputils-ping`, `bind9-dnsutils`). `ping` needs the `NET_RAW` capability (see `compose.yaml`).
`gh` comes from Debian's package (currently 2.46, older than upstream) and only works if you set `GH_TOKEN` (see `.env.example`;
use a fine-grained, repo-scoped token, since anything the agent runs can read it). Need more (Node, Go, compilers, ...)? Build a downstream image with `FROM ghcr.io/kalex3/cursor:latest`.

## What's pinned

| Component | How |
| --- | --- |
| Base image | `debian:13.7-slim` + digest (Dependabot) |
| Dockerfile frontend | `docker/dockerfile` tag + digest |
| Cursor Agent CLI | Exact version + per-arch SHA-256, verified at build time |
| GitHub Actions | Full commit SHAs (Dependabot) |
| apt packages | Not pinned (Debian drops old versions); reproducibility comes from the base digest |

## Automation

- **CI** (`ci.yml`): hadolint, multi-arch (amd64/arm64) build with GHA layer cache, SBOM and provenance attestations. Pushes to GHCR on `main` (`latest`, `sha-<commit>`); pull requests only build and smoke-test.
- **Dependabot**: weekly updates for the Docker base image and GitHub Actions.
- **Update Cursor Agent** (`update-cursor-agent.yml`): daily check of the latest release; opens a PR bumping the version and checksums via `scripts/update-cursor-agent.sh`. Merging it commits the new pin on `main`.

## Layer caching

The Cursor Agent download lives in its own stage, so the runtime stage's apt layer is not invalidated by agent bumps, and apt downloads use BuildKit cache mounts.

## License

[MIT](LICENSE)
