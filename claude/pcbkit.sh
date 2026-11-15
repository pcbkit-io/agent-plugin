#!/bin/sh
# Runs PCBKit's CLI for this plugin: this version's build for this computer, fetched once from
# PCBKit's releases into ~/.pcbkit/bin and checked against the checksum below.
set -eu
VERSION="2.0.4"
# (The CLI is told where this file is: `pcbkit init` copies it into a repository.)
case "$0" in /*) PCBKIT_LAUNCHER="$0" ;; *) PCBKIT_LAUNCHER="$PWD/$0" ;; esac
export PCBKIT_LAUNCHER
if [ -n "${PCBKIT_BIN:-}" ] && [ -x "$PCBKIT_BIN" ]; then exec "$PCBKIT_BIN" "$@"; fi
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) TARGET=darwin-arm64; SUM=e8874aae76ae4ed67a2f89a259b59aff04e68b703ab773afba2476d1e2f88492 ;;
  Darwin-x86_64) TARGET=darwin-x64; SUM=f7410f06c3dfb35ae99221597e9a9d599b80623c75a0e3c1b5ae00da1ec52472 ;;
  Linux-x86_64) TARGET=linux-x64; SUM=18948f847eaaf8cb4d3ddff3af151406ceca00d99bf9d04d3cce16bd8165025a ;;
  Linux-aarch64|Linux-arm64) TARGET=linux-arm64; SUM=5462e058a138372e765916b285922c19e9e9b461a87d3313cb1233425ac5e10e ;;
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
  # (A connection that goes silent is given up after a minute, so the lock below is let go.)
  if command -v curl >/dev/null 2>&1; then
    T="--connect-timeout 20 --speed-limit 1024 --speed-time 60"
    # shellcheck disable=SC2086
    curl -fsSL $T -C - "$URL" -o "$PART" || { rm -f "$PART"; curl -fsSL $T "$URL" -o "$PART"; }
  elif command -v wget >/dev/null 2>&1; then wget -qc -T 60 -O "$PART" "$URL"
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
