# rustxng (container image)

Container image for [sahenjp/RustXNG](https://github.com/sahenjp/RustXNG), built so a
NAS can follow upstream releases automatically.

- `publish.yml` runs daily, reads the newest upstream release tag, and pushes
  `ghcr.io/solidlime/rustxng-container:{latest,vX.Y.Z}` **only when that tag is not published yet**.
  An unchanged upstream tag means an unchanged image digest, so watchtower stays quiet.
- The image downloads the upstream statically linked musl binary and verifies the
  published `sha256`. There is no Rust toolchain and no build on the NAS.
- `entrypoint.sh` seeds `/data/settings.toml` on first start (random `secret_key`,
  local BM25 index at `/data/index-data`), then runs rustxng as uid 10001.

## Run on the NAS

```bash
mkdir -p /volume1/docker/rustxng
docker compose -f compose.yml up -d
```

Or paste `compose.yml` into a Portainer stack. Open `http://nas:8888/`.

## Updating

watchtower picks up new digests by itself. To force it by hand:

```bash
docker compose pull && docker compose up -d
```

## Local index (optional)

`local_index_path` already points at `/data/index-data`, but the index is empty,
so nothing changes until you crawl. The crawler (`rustxng-index`) is **not** part of
the release assets - it has to be built from source:

```bash
cargo build --release --bin rustxng-index
rustxng-index crawl --seeds seeds.txt --out /volume1/docker/rustxng/index-data --max-pages 5000
```

RustXNG warns and starts normally when the index is missing or empty.

## 運用上の注意

- `/data/index-data/` は NAS 上では再生成できない。ローカル索引を作る `rustxng-index` は
  release asset に含まれておらず、イメージ内にも無い。消えたら索引は失われるので
  `/volume1/docker/rustxng` のバックアップを取ること。
- `/data/settings.toml` は初回起動時のみ生成される。以後イメージを更新しても上書きされない。
  `secret_key` を失うとセッション類は無効になる。
- watchtower が 300 秒間隔でこのイメージの digest を見ており、upstream の新リリースが
  publish された時だけ再作成される。

## License

Upstream is AGPL-3.0-or-later; `LICENSE` and `NOTICE` are shipped inside the image
at `/usr/share/licenses/rustxng/`.
