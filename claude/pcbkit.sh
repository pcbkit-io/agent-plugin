#!/bin/sh
# Runs PCBKit's CLI for this plugin: this version's build for this computer, fetched once from
# PCBKit's releases into ~/.pcbkit/bin and checked against the checksum below.
set -eu
VERSION="0.1.9"
if [ -n "${PCBKIT_BIN:-}" ] && [ -x "$PCBKIT_BIN" ]; then exec "$PCBKIT_BIN" "$@"; fi
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) TARGET=darwin-arm64; SUM=fea0b8429593d099857b635e8181d0184cafe488d9ed7e087426ec1af2031eee ;;
  Darwin-x86_64) TARGET=darwin-x64; SUM=3a7beee3a998a94d9ca80011925b9c9faf6fa24e8a1be6dbb727b53eac9d862f ;;
  Linux-x86_64) TARGET=linux-x64; SUM=f4c5746034f219198e1a3e71571b5c7577d762d919a6a24d60d07e5f5f807e64 ;;
  Linux-aarch64|Linux-arm64) TARGET=linux-arm64; SUM=78c4669f4ff4bc37d8b4d3d62e0d7adbd2493982a4454a8ad5a9c9a73fd50453 ;;
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
