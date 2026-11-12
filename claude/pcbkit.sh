#!/bin/sh
# Runs PCBKit's CLI for this plugin: this version's build for this computer, fetched once from
# PCBKit's releases into ~/.pcbkit/bin and checked against the checksum below.
set -eu
VERSION="0.1.8"
if [ -n "${PCBKIT_BIN:-}" ] && [ -x "$PCBKIT_BIN" ]; then exec "$PCBKIT_BIN" "$@"; fi
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) TARGET=darwin-arm64; SUM=0859151e1f82e12a5ac16c1a4c703684c60cc901b6fae804f2d41ba6f5385e82 ;;
  Darwin-x86_64) TARGET=darwin-x64; SUM=6bfa0481e71defc866792e45a9e3601cd37a6193e359aa7229140337ff981299 ;;
  Linux-x86_64) TARGET=linux-x64; SUM=8874b4af245cccf2cc8b0078e129e5dd2403aae33643b2a8d9ec1410d5f40baa ;;
  Linux-aarch64|Linux-arm64) TARGET=linux-arm64; SUM=066b37a69c753edc7724d42729ac174ac22fa4ca31e7a39c5d4235d24263eecd ;;
  *) echo "PCBKit has no build for $(uname -s) $(uname -m) yet: https://github.com/pcbkit-io/agent-plugin/issues" >&2; exit 1 ;;
esac
DIR="${PCBKIT_HOME:-$HOME/.pcbkit}/bin"
BIN="$DIR/pcbkit-$VERSION"
PART="$BIN.gz.part"
LOCK="$BIN.fetching"

# Fetches the CLI and puts it in place. Runs apart from this script, so it finishes even when the
# agent's host gives up waiting for its first start; a fetch cut short goes on from where it stopped.
fetch() {
  URL="https://github.com/pcbkit-io/agent-plugin/releases/download/v$VERSION/pcbkit-$TARGET.gz"
  if command -v curl >/dev/null 2>&1; then curl -fsSL -C - "$URL" -o "$PART" || { rm -f "$PART"; curl -fsSL "$URL" -o "$PART"; }
  elif command -v wget >/dev/null 2>&1; then wget -qc -O "$PART" "$URL"
  else echo "PCBKit needs curl or wget to fetch its CLI."; return 1; fi
  if command -v shasum >/dev/null 2>&1; then GOT=$(shasum -a 256 "$PART" | cut -d' ' -f1)
  else GOT=$(sha256sum "$PART" | cut -d' ' -f1); fi
  if [ "$GOT" != "$SUM" ]; then rm -f "$PART"; echo "PCBKit's CLI could not be fetched: the file is not the one this plugin was built with."; return 1; fi
  gunzip -c "$PART" > "$BIN.tmp" && chmod +x "$BIN.tmp" && mv "$BIN.tmp" "$BIN" && rm -f "$PART"
}

if [ ! -x "$BIN" ]; then
  mkdir -p "$DIR"
  # A fetch left behind by a computer that went down: start over.
  if [ -d "$LOCK" ] && [ -n "$(find "$LOCK" -maxdepth 0 -mmin +15 2>/dev/null)" ]; then rmdir "$LOCK" 2>/dev/null || true; fi
  if mkdir "$LOCK" 2>/dev/null; then
    echo "PCBKit: fetching its CLI ($VERSION, $TARGET), once." >&2
    ( fetch > "$BIN.log" 2>&1; rmdir "$LOCK" ) < /dev/null > /dev/null 2>&1 &
  fi
  while [ ! -x "$BIN" ] && [ -d "$LOCK" ]; do sleep 0.2; done
  if [ ! -x "$BIN" ]; then cat "$BIN.log" >&2 2>/dev/null || true; exit 1; fi
fi
exec "$BIN" "$@"
