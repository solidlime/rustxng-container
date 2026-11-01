# rustxng (container image)

Container image for [sahenjp/RustXNG](https://github.com/sahenjp/RustXNG), built so a
NAS can follow upstream releases automatically.

- `publish.yml` runs daily, reads the newest upstream release tag, and pushes
  `ghcr.io/solidlime/rustxng-container:{latest,vX.Y.Z,vX.Y.Z-<recipe-sha>}` **only when that
  tag is not published yet**. The recipe sha covers `Dockerfile` + `entrypoint.sh`, so fixing
  the image itself rebuilds it without waiting for an upstream release; an unchanged recipe
  and upstream tag mean an unchanged digest, which keeps watchtower quiet.
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

watchtower picks up new digests by itself. The container actually runs from a
**Portainer stack** (stack_id 72, `/data/compose/72/docker-compose.yml`), so the
`compose.yml` in this repo is not the file on the NAS - `docker compose -f compose.yml up -d`
does nothing there. To force an update by hand, pull and recreate:

```bash
docker pull ghcr.io/solidlime/rustxng-container:latest
```

then in Portainer: **Stacks -> rustxng -> Update the stack** (with *re-pull image*).

## Rolling back

Note the running image id before updating, so the old one stays addressable:

```bash
docker ps --filter name=rustxng --format '{{.Image}}'
docker tag <current image id> rustxng:pre-update
```

If the new image misbehaves, point the stack's image at `rustxng:pre-update` and recreate it
in Portainer. `/data` is a bind mount, so settings and the index survive the swap.

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
- 更新の反映は watchtower 任せ。既定の巡回は **24 時間に 1 回**（この NAS では毎日 06:21 JST
  前後）なので、publish 直後には反映されない。すぐ反映したい時は上の「手で更新する」を実行する。

## License

Upstream is AGPL-3.0-or-later; `LICENSE` and `NOTICE` are shipped inside the image
at `/usr/share/licenses/rustxng/`.
