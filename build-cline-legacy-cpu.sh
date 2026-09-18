#!/bin/sh
set -eu

CLINE_TAG="${CLINE_TAG:-cli-v3.0.62}"
BUN_VERSION="${BUN_VERSION:-1.4.1}"
NODE_VERSION="${NODE_VERSION:-22.23.2}"
GRPC_TOOLS_VERSION="${GRPC_TOOLS_VERSION:-1.13.1}"
WORK_ROOT="${WORK_ROOT:-$HOME/cline-linux-legacy-build}"

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) ;;
  *)
    echo "ERROR: this build workflow currently supports Linux x86_64 only." >&2
    exit 1
    ;;
esac

if ! grep -qm1 '\bsse4_2\b' /proc/cpuinfo; then
  echo "ERROR: SSE4.2 was not detected. This workflow has not been validated on this CPU." >&2
  exit 1
fi

for cmd in curl git python3 tar; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $cmd" >&2
    exit 1
  fi
done

mkdir -p "$WORK_ROOT"
BUN_ROOT="$WORK_ROOT/bun"
NODE_ROOT="$WORK_ROOT/node-v$NODE_VERSION-linux-x64"
SRC_ROOT="$WORK_ROOT/cline"
MIRROR_ROOT="$WORK_ROOT/grpc-mirror"
BUN_ZIP="$WORK_ROOT/bun-linux-x64.zip"
NODE_TAR="$WORK_ROOT/node-v$NODE_VERSION-linux-x64.tar.xz"
GRPC_TGZ="$WORK_ROOT/grpc-tools-linux-x64.tar.gz"

echo "==> CPU"
grep -m1 '^model name' /proc/cpuinfo || true
printf 'flags: '
grep -m1 '^flags' /proc/cpuinfo | grep -oE '\b(sse4_2|avx|avx2)\b' | tr '\n' ' '
echo

echo "==> Bun $BUN_VERSION"
if [ ! -x "$BUN_ROOT/bun-linux-x64/bun" ]; then
  rm -rf "$BUN_ROOT"
  mkdir -p "$BUN_ROOT"
  curl -fL "https://github.com/oven-sh/bun/releases/download/bun-v$BUN_VERSION/bun-linux-x64.zip" -o "$BUN_ZIP"
  python3 -m zipfile -e "$BUN_ZIP" "$BUN_ROOT"
  chmod +x "$BUN_ROOT/bun-linux-x64/bun"
fi
BUN_BIN="$BUN_ROOT/bun-linux-x64/bun"
"$BUN_BIN" --version

echo "==> Node.js $NODE_VERSION"
if [ ! -x "$NODE_ROOT/bin/node" ]; then
  curl -fL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" -o "$NODE_TAR"
  rm -rf "$NODE_ROOT"
  tar -xJf "$NODE_TAR" -C "$WORK_ROOT"
fi
"$NODE_ROOT/bin/node" --version

echo "==> Cline $CLINE_TAG"
if [ ! -d "$SRC_ROOT/.git" ]; then
  git clone --branch "$CLINE_TAG" --depth 1 https://github.com/cline/cline.git "$SRC_ROOT"
else
  git -C "$SRC_ROOT" fetch --depth 1 origin "refs/tags/$CLINE_TAG:refs/tags/$CLINE_TAG"
  git -C "$SRC_ROOT" checkout -f "$CLINE_TAG"
fi

echo "==> Prepare grpc-tools localhost mirror"
mkdir -p "$MIRROR_ROOT/grpc-tools/v$GRPC_TOOLS_VERSION"
if [ ! -s "$GRPC_TGZ" ]; then
  curl -fL     "https://node-precompiled-binaries.grpc.io/grpc-tools/v$GRPC_TOOLS_VERSION/linux-x64.tar.gz"     -o "$GRPC_TGZ"
fi
cp "$GRPC_TGZ" "$MIRROR_ROOT/grpc-tools/v$GRPC_TOOLS_VERSION/linux-x64.tar.gz"

PORT=18765
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$MIRROR_ROOT"   >"$WORK_ROOT/grpc-mirror.log" 2>&1 &
MIRROR_PID=$!
trap 'kill "$MIRROR_PID" 2>/dev/null || true' EXIT INT TERM
sleep 1
curl -fsI "http://127.0.0.1:$PORT/grpc-tools/v$GRPC_TOOLS_VERSION/linux-x64.tar.gz" >/dev/null

export PATH="$BUN_ROOT/bun-linux-x64:$NODE_ROOT/bin:$PATH"
export npm_config_grpc_tools_binary_host_mirror="http://127.0.0.1:$PORT/"

echo "==> Install dependencies"
cd "$SRC_ROOT"
rm -rf node_modules
bun install --frozen-lockfile

echo "==> Build Linux x64 CLI"
bun -F @cline/cli build:platforms:single

OUT="$SRC_ROOT/apps/cli/dist/cli-linux-x64/bin/cline"

echo "==> Smoke test"
"$OUT" --version

echo
echo "PASS"
echo "Binary: $OUT"
echo "Existing system Cline installation was not modified."
