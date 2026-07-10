# Claude Code Usage Monitor — Docker

A containerized build of [Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor)
(`claude-monitor`), a terminal tool that reports your Claude Code token usage.

The monitor reads Claude Code's **local usage files** — no API key, no network
access. This wrapper builds the tool from source into a slim image and runs it
against your host's `~/.claude` data, mounted read-only.

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- [`just`](https://github.com/casey/just) (optional — see [Without `just`](#without-just))

## Quick start

```sh
just build      # build the image from upstream `main`
just run        # launch the live monitor
```

## Building

`just build` builds the image from the upstream source. Pass a git ref
(branch, tag, or commit SHA) to pin a specific version:

```sh
just build            # latest `main`
just build v4.0.0     # a tagged release
just build <sha>      # a specific commit
```

Under the hood a multi-stage build compiles a wheel from source, then installs
only that wheel into a clean runtime image (no git or build toolchain ships in
the final image).

## Running

`just run` starts the monitor. It runs with an interactive TTY (required for
the live view), mounts your Claude data read-only, and removes the container on
exit. Any extra arguments pass straight through to `claude-monitor`:

```sh
just run                              # default realtime view (Eastern time)
just run --plan max20                 # set your plan
just run --view daily                 # daily aggregate
just run --once --output json         # single JSON snapshot, then exit
just run --theme dark
```

### Timezones

`just run` uses **Eastern time** by default. There are shortcuts for the other
US zones and UTC — each forwards extra args just like `run`:

| Recipe | Timezone |
|--------|----------|
| `just run` | `America/New_York` (Eastern, default) |
| `just run-central` | `America/Chicago` |
| `just run-mountain` | `America/Denver` |
| `just run-pacific` | `America/Los_Angeles` |
| `just run-utc` | `UTC` |

```sh
just run-pacific --plan max20 --view daily
```

For any other zone, pass an IANA name explicitly (it overrides the default):

```sh
just run --timezone Europe/London
```

### Where your data comes from

By default the wrapper mounts `~/.claude` from your host and points the tool at
it via `CLAUDE_CONFIG_DIR`. If your Claude Code data lives elsewhere, override
the source directory:

```sh
CLAUDE_DIR=/path/to/your/.claude just run
```

The mount is **read-only** — the container can never modify your real Claude
files. The monitor's own preferences live inside the container and are
discarded when it exits.

## Without `just`

The `just` recipes are thin wrappers around Docker. The equivalents:

```sh
# build
docker build --build-arg GIT_REF=main -t claude-code-usage-monitor:latest .

# run
docker run -it --rm \
    -v "$HOME/.claude:/data/.claude:ro" \
    -e CLAUDE_CONFIG_DIR=/data/.claude \
    claude-code-usage-monitor:latest --plan max20
```

## Common flags

| Flag | Description |
|------|-------------|
| `--plan` | `custom` / `pro` / `max5` / `max20` |
| `--view` | `realtime` / `daily` / `monthly` / `session` / `burn-rate` |
| `--output` | `rich` / `json` / `text` / `csv` |
| `--once` | Print a single snapshot and exit |
| `--theme` | `light` / `dark` / `classic` / `auto` |

See the [upstream README](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor)
for the full option list.
