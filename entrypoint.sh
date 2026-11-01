#!/bin/sh
# First run seeds /data/settings.toml from the image, then rustxng runs as
# uid 10001. The bind-mounted directory arrives owned by root, hence the chown.
set -eu

DATA_DIR="${DATA_DIR:-/data}"
PORT="${RUSTXNG_PORT:-8888}"
SETTINGS="$DATA_DIR/settings.toml"

mkdir -p "$DATA_DIR/index-data"

# -s なので 0 バイトの残骸は「無い」扱いになる。生成は同一 FS 内の
# 一時ファイル + mv で行い、途中で落ちても半端な設定が残らない。
if [ ! -s "$SETTINGS" ]; then
  tmp="$DATA_DIR/.settings.toml.$$"
  cp /etc/rustxng-settings.toml "$tmp"
  secret=$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')
  if grep -q '^secret_key = ' "$tmp"; then
    sed -i "s|^secret_key = .*|secret_key = \"$secret\"|" "$tmp"
  else
    printf '\nsecret_key = "%s"\n' "$secret" >> "$tmp"
  fi
  # 自前 BM25 索引を使う（空のままでも警告だけで起動する）
  sed -i 's|^local_index_path = ""|local_index_path = "/data/index-data"|' "$tmp"
  chown rustxng:rustxng "$tmp"
  mv "$tmp" "$SETTINGS"
fi

chown rustxng:rustxng "$SETTINGS"
chown -R rustxng:rustxng "$DATA_DIR/index-data"

exec su-exec rustxng:rustxng rustxng --bind 0.0.0.0 --port "$PORT"
