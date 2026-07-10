# syntax=docker/dockerfile:1

##############################################################################
# Stage 1 — build a wheel from the upstream source
##############################################################################
FROM python:3.13-slim AS builder

# Upstream repo and the ref to build (branch, tag, or full commit SHA).
ARG REPO_URL=https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor.git
ARG GIT_REF=main

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir build

WORKDIR /src
# Shallow-clone the ref; fall back to a full clone + checkout for commit SHAs,
# which `--branch` cannot target.
RUN git clone --depth 1 --branch "${GIT_REF}" "${REPO_URL}" . \
    || (git clone "${REPO_URL}" . && git checkout "${GIT_REF}")

RUN python -m build --wheel --outdir /dist

##############################################################################
# Stage 2 — slim runtime image (no git / build toolchain)
##############################################################################
FROM python:3.13-slim AS runtime

# Install only the built wheel plus its runtime dependencies.
COPY --from=builder /dist/*.whl /tmp/
RUN pip install --no-cache-dir /tmp/*.whl \
    && rm -rf /tmp/*.whl

# Run as an unprivileged user rather than root.
RUN useradd --create-home --uid 1000 monitor
USER monitor
WORKDIR /home/monitor

# The monitor reads Claude Code usage data from here. The host's ~/.claude is
# mounted at this path (read-only) at run time.
ENV CLAUDE_CONFIG_DIR=/data/.claude

ENTRYPOINT ["claude-monitor"]
