#!/bin/sh
# Runs PCBKit's CLI for this plugin: this version's build for this computer, fetched once from
# PCBKit's releases into ~/.pcbkit/bin and checked against the checksum below.
set -eu
VERSION="2.0.3"
# (The CLI is told where this file is: `pcbkit init` copies it into a repository.)
case "$0" in /*) PCBKIT_LAUNCHER="$0" ;; *) PCBKIT_LAUNCHER="$PWD/$0" ;; esac
export PCBKIT_LAUNCHER
if [ -n "${PCBKIT_BIN:-}" ] && [ -x "$PCBKIT_BIN" ]; then exec "$PCBKIT_BIN" "$@"; fi
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) TARGET=darwin-arm64; SUM=604e7b2cabbace778695a659f205ea54b7378e5a6cfcb6e6c75e5f577c829d95 ;;
  Darwin-x86_64) TARGET=darwin-x64; SUM=2972a6be3272e31fd977dc225f397ea33d330dd92523f2de82316271c0fb868a ;;
  Linux-x86_64) TARGET=linux-x64; SUM=00010f6c094e7ce9c5862a097b71c471f86ef38b649ff7af18b7d0e76f3d3054 ;;
  Linux-aarch64|Linux-arm64) TARGET=linux-arm64; SUM=f5b096566902fc41aae5b45327df12b35800dda23cd03fefe736621ae2627707 ;;
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
