#!/bin/sh
# First run seeds /data/settings.toml from the image, then rustxng runs as
# uid 10001. The bind-mounted directory arrives owned by root, hence the chown.
set -eu

DATA_DIR="${DATA_DIR:-/data}"
PORT="${RUSTXNG_PORT:-8888}"

mkdir -p "$DATA_DIR/index-data"

if [ ! -f "$DATA_DIR/settings.toml" ]; then
  cp /etc/rustxng-settings.toml "$DATA_DIR/settings.toml"
  secret=$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')
  sed -i "s|^secret_key = .*|secret_key = \"$secret\"|" "$DATA_DIR/settings.toml"
  # 自前 BM25 索引を使う（空のままでも警告だけで起動する）
  sed -i 's|^local_index_path = ""|local_index_path = "/data/index-data"|' "$DATA_DIR/settings.toml"
fi

chown -R rustxng:rustxng "$DATA_DIR"

exec su-exec rustxng:rustxng rustxng --bind 0.0.0.0 --port "$PORT"
