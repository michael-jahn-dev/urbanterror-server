# Urban Terror server for Docker (amd64 + arm64)

A small Docker image for an [Urban Terror](https://www.urbanterror.info) 4.3 dedicated server, built from the **official, unmodified FrozenSand engine** ([ioq3-for-UrbanTerror-4](https://github.com/FrozenSand/ioq3-for-UrbanTerror-4)).

- Runs natively on **ARM64** (Raspberry Pi 4/5, Apple Silicon, ARM VPS) and **x86_64**
- No gameplay mods, vanilla Urban Terror
- Runs as an unprivileged user, works with a read-only container filesystem
- Image is tiny: **game data is not included** and is mounted from the host

## Why?

FrozenSand only ships x86 server binaries. Existing ARM images use modified engines with mods enabled by default. This image builds the official engine from source, with a one-line patch that adds `aarch64` to the list of known architectures.

## Quick start

### 1. Get the game data

The game data is proprietary and can't be redistributed, so download the official 4.3.4 package yourself (about 1.4 GB):

```bash
git clone https://github.com/michael-jahn-dev/urbanterror-server.git
cd urbanterror-server
wget http://cdn.urbanterror.info/urt/43/releases/zips/UrbanTerror434_full.zip
sha256sum UrbanTerror434_full.zip
# expected: 455687948057c918c0032d094c5a017d34b57451b813a6a77f9228afd1e428b0
unzip UrbanTerror434_full.zip
```

If the link is dead, get the package from [urbanterror.info/downloads](https://www.urbanterror.info/downloads/). You end up with an `UrbanTerror43/` folder next to `docker-compose.yml`. The x86 binaries inside are ignored.

### 2. Configure

```bash
cp server.example.cfg UrbanTerror43/q3ut4/server.cfg
cp UrbanTerror43/q3ut4/mapcycle_example.txt UrbanTerror43/q3ut4/mapcycle.txt
```

Edit `UrbanTerror43/q3ut4/server.cfg` and at least set `sv_hostname` and `rconpassword`.

The container runs as UID 1000, so it needs write access to the game folder (logs, auto-generated configs):

```bash
sudo chown -R 1000:1000 UrbanTerror43
```

### 3. Start

```bash
docker compose up -d --build
docker compose logs -f
```

The first build compiles the engine and takes a few minutes on a Raspberry Pi. To skip building, use the prebuilt image in `docker-compose.yml`:

```yaml
image: ghcr.io/michael-jahn-dev/urbanterror-server:latest
```

### 4. Open the port

Forward **UDP 27960** on your router to the host if players should join from the internet.

## Configuration

| What | How |
| --- | --- |
| Server settings | `UrbanTerror43/q3ut4/server.cfg` |
| Map rotation | `UrbanTerror43/q3ut4/mapcycle.txt` |
| Custom maps | drop `.pk3` files into `UrbanTerror43/q3ut4/` |
| Logs | `UrbanTerror43/q3ut4/games.log` |
| LAN only (no master server) | override the command with `+set dedicated 1` |
| Different port | change `net_port` in the command and the port mapping |

Overriding the command in `docker-compose.yml`, e.g. for port 27961 and LAN only:

```yaml
command: ["+set", "dedicated", "1", "+set", "net_port", "27961", "+exec", "server.cfg"]
ports:
  - "27961:27961/udp"
```

To list all maps in your game data:

```bash
for f in UrbanTerror43/q3ut4/*.pk3; do unzip -l "$f" | grep -o 'maps/[^ ]*\.bsp'; done | sed 's#maps/##; s#\.bsp##' | sort -u
```

## Notes

- On ARM the game logic runs in the QVM interpreter instead of the x86 JIT. That costs a bit of CPU, but a Raspberry Pi 5 handles a full server easily.
- The engine is based on Quake 3 and isn't actively maintained anymore. The compose file drops all capabilities, blocks privilege escalation and limits memory. Use a strong RCON password.
- Building the engine at a specific commit or tag: `docker compose build --build-arg ENGINE_REF=<tag>`

## License

The Dockerfile and configs in this repository are released under GPL-2.0, like the engine they build. Urban Terror and its game data are property of FrozenSand and are not part of this repository or image.
