# Claude Code Usage Monitor — Docker wrapper
#
# `just`         list available recipes
# `just build`   build the image from upstream source (main)
# `just run`     run the monitor against your local ~/.claude data

image := "claude-code-usage-monitor:latest"

# Host directory holding your Claude Code data. Override with CLAUDE_DIR=... .
claude_dir := env_var_or_default("CLAUDE_DIR", home_directory() / ".claude")

# List available recipes.
_default:
    @just --list

# Build the image. Optionally pass an upstream git ref, e.g. `just build v4.0.0`.
build ref="main":
    docker build --build-arg GIT_REF={{ ref }} -t {{ image }} .

# Run the monitor in Eastern time. Extra args pass straight through, e.g. `just run --plan max20 --view daily`.
run *args:
    @just _run America/New_York {{ args }}

# Run in UTC.
run-utc *args:
    @just _run UTC {{ args }}

# Run in US Central time.
run-central *args:
    @just _run America/Chicago {{ args }}

# Run in US Mountain time.
run-mountain *args:
    @just _run America/Denver {{ args }}

# Run in US Pacific time.
run-pacific *args:
    @just _run America/Los_Angeles {{ args }}

# Internal: run the monitor in a given IANA timezone.
_run tz *args:
    docker run -it --rm \
        -v "{{ claude_dir }}:/data/.claude:ro" \
        -e CLAUDE_CONFIG_DIR=/data/.claude \
        {{ image }} --timezone {{ tz }} {{ args }}
