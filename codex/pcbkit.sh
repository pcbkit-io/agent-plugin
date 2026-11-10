#!/bin/sh
# Runs PCBKit's CLI for this plugin: this version's build for this computer, fetched once from
# PCBKit's releases into ~/.pcbkit/bin and checked against the checksum below.
set -eu
VERSION="0.1.5"
if [ -n "${PCBKIT_BIN:-}" ] && [ -x "$PCBKIT_BIN" ]; then exec "$PCBKIT_BIN" "$@"; fi
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) TARGET=darwin-arm64; SUM=113fdf27dfa5056bc8fc67036b44fbb9aaa0f9cc5d559359859e13f2c7c3771a ;;
  Darwin-x86_64) TARGET=darwin-x64; SUM=678771eb27cfb7a16d42a49b90419f8202e2e323ad388f3cc97db8b14a366685 ;;
  Linux-x86_64) TARGET=linux-x64; SUM=446eee9da3fcf2664a7fb3300aee2b2bdb460db295e2c6088796ae09d9926b4d ;;
  Linux-aarch64|Linux-arm64) TARGET=linux-arm64; SUM=1f129371115ce6328066276a88fc0358ab4b6a0d849383db1508cd904914ee30 ;;
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
