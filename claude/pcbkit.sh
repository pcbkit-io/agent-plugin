#!/bin/sh
# Runs PCBKit's CLI for this plugin: this version's build for this computer, fetched once from
# PCBKit's releases into ~/.pcbkit/bin and checked against the checksum below.
set -eu
VERSION="0.1.0"
if [ -n "${PCBKIT_BIN:-}" ]; then exec "$PCBKIT_BIN" "$@"; fi
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) TARGET=darwin-arm64; SUM=489664650050086f14a4d2644190051a8b23c1ac5feea1f63193203fc0613119 ;;
  Darwin-x86_64) TARGET=darwin-x64; SUM=1aa2179cfe6af35d715db3e4e40c1e3613be33f3e70979ebacd479424beff628 ;;
  Linux-x86_64) TARGET=linux-x64; SUM=6cb4e3e7a35e0794650924c45b4441ef2ae11beae5990331d70e1988dcf76814 ;;
  Linux-aarch64|Linux-arm64) TARGET=linux-arm64; SUM=7f1e4bcd147c2a4b2a7610e046b4dcac871e81e3e2e68328466b6d7425066978 ;;
  *) echo "PCBKit has no build for $(uname -s) $(uname -m) yet: https://github.com/pcbkit-io/agent-plugin/issues" >&2; exit 1 ;;
esac
DIR="${PCBKIT_HOME:-$HOME/.pcbkit}/bin"
BIN="$DIR/pcbkit-$VERSION"
if [ ! -x "$BIN" ]; then
  mkdir -p "$DIR"
  # A fetch cut short (the host gave up waiting) goes on from where it stopped the next time.
  PART="$BIN.gz.part"
  TMP="$BIN.$$.tmp"
  trap 'rm -f "$TMP"' EXIT
  URL="https://github.com/pcbkit-io/agent-plugin/releases/download/v$VERSION/pcbkit-$TARGET.gz"
  echo "PCBKit: fetching its CLI ($VERSION, $TARGET), once." >&2
  if command -v curl >/dev/null 2>&1; then curl -fsSL -C - "$URL" -o "$PART" || { rm -f "$PART"; curl -fsSL "$URL" -o "$PART"; }
  elif command -v wget >/dev/null 2>&1; then wget -qc -O "$PART" "$URL"
  else echo "PCBKit needs curl or wget to fetch its CLI." >&2; exit 1; fi
  if command -v shasum >/dev/null 2>&1; then GOT=$(shasum -a 256 "$PART" | cut -d' ' -f1)
  else GOT=$(sha256sum "$PART" | cut -d' ' -f1); fi
  if [ "$GOT" != "$SUM" ]; then rm -f "$PART"; echo "PCBKit's CLI could not be fetched: the file is not the one this plugin was built with." >&2; exit 1; fi
  gunzip -c "$PART" > "$TMP"
  chmod +x "$TMP"
  mv "$TMP" "$BIN"
  rm -f "$PART"
fi
exec "$BIN" "$@"
