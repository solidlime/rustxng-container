# syntax=docker/dockerfile:1
# RustXNG (upstream: sahenjp/RustXNG) as a container image.
#
# The upstream release already ships a statically linked musl binary, so this
# image only downloads it and verifies the published sha256. No Rust toolchain,
# no compile - the NAS never builds anything.

FROM alpine:3.21

ARG RUSTXNG_VERSION
RUN set -eux; \
    test -n "${RUSTXNG_VERSION}"; \
    apk add --no-cache ca-certificates curl su-exec; \
    base="https://github.com/sahenjp/RustXNG/releases/download/${RUSTXNG_VERSION}"; \
    raw="https://raw.githubusercontent.com/sahenjp/RustXNG/${RUSTXNG_VERSION}"; \
    asset="rustxng-${RUSTXNG_VERSION}-x86_64-unknown-linux-musl"; \
    curl -fsSL "$base/$asset" -o "/tmp/$asset"; \
    curl -fsSL "$base/$asset.sha256" -o "/tmp/$asset.sha256"; \
    expected=$(cut -d' ' -f1 "/tmp/$asset.sha256"); \
    test -n "$expected"; \
    printf '%s  %s\n' "$expected" "/tmp/$asset" | sha256sum -c -; \
    install -m 0755 "/tmp/$asset" /usr/local/bin/rustxng; \
    rm -f "/tmp/$asset" "/tmp/$asset.sha256"; \
    curl -fsSL "$raw/settings.toml" -o /etc/rustxng-settings.toml; \
    mkdir -p /usr/share/licenses/rustxng; \
    curl -fsSL "$raw/LICENSE" -o /usr/share/licenses/rustxng/LICENSE; \
    curl -fsSL "$raw/NOTICE" -o /usr/share/licenses/rustxng/NOTICE || true; \
    apk del curl; \
    addgroup -g 10001 rustxng; \
    adduser -u 10001 -G rustxng -D -H rustxng

COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

# Settings and the local BM25 index live here; keep it on a bind mount.
VOLUME ["/data"]
EXPOSE 8888

ENTRYPOINT ["/entrypoint.sh"]
