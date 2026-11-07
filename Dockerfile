# LaTeX toolchain for latex-doc-composer: TinyTeX + every package the
# templates need, on Debian. Used through ./dmake (macOS/Linux) or
# dmake.cmd (Windows). Build manually with: docker compose build
FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git make perl curl ca-certificates xz-utils fontconfig \
 && rm -rf /var/lib/apt/lists/*

ENV TINYTEX_HOME=/opt/TinyTeX
# Step 1: TinyTeX itself (slow download; cached unless setup.sh/lib.sh change).
COPY scripts/setup.sh scripts/lib.sh scripts/check-tex.sh /opt/ldc/scripts/
RUN LDC_TEX_ONLY=1 bash /opt/ldc/scripts/setup.sh --yes \
 && /opt/TinyTeX/bin/*/tlmgr option sys_bin /usr/local/bin \
 && /opt/TinyTeX/bin/*/tlmgr path add

# Step 2: the packages the templates need (re-runs when packages.txt changes).
COPY templates/ /opt/ldc/templates/
COPY scripts/packages.txt /opt/ldc/scripts/
RUN bash /opt/ldc/scripts/setup.sh --yes \
 # writable so builds can auto-install missing packages (lost when the container exits)
 && chmod -R a+rwX /opt/TinyTeX \
 && rm -rf /opt/ldc

# The repo is mounted at /work and may be owned by another uid.
RUN git config --system --add safe.directory '*'
ENV HOME=/tmp LDC_IN_DOCKER=1
WORKDIR /work
CMD ["make", "help"]
