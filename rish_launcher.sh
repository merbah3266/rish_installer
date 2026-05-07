SCRIPT_URL="https://tinyurl.com/rish3266"
RAND_ID="$RANDOM"
TMP_DIR="${TMPDIR:-/tmp}/rish_launch.$RAND_ID"
TMP_SCRIPT="$TMP_DIR/rish_installer.sh"

cleanup() {
    rm -rf "$TMP_DIR" 2>/dev/null
}

trap cleanup INT EXIT

mkdir -p "$TMP_DIR" 2>/dev/null

if command -v bash >/dev/null 2>&1; then
    curl -fsSL "$SCRIPT_URL" -o "$TMP_SCRIPT" 2>/dev/null
    if [ ! -f "$TMP_SCRIPT" ]; then
        echo "Script download failed"
        exit 1
    fi
    bash "$TMP_SCRIPT"
else
    ARCH="$(uname -m)"
    case "$ARCH" in
        aarch64|arm64|armv8*) ARCH="arm64" ;;
        armv*|armhf|arm) ARCH="arm" ;;
        x86_64|amd64) ARCH="x86_64" ;;
        i386|i686|x86) ARCH="x86" ;;
        *) echo "Unsupported arch"; exit 1 ;;
    esac

    BB="$TMP_DIR/busybox"
    curl -fsSL "https://raw.githubusercontent.com/merbah3266/rish_installer/main/busybox/$ARCH/busybox" -o "$BB" 2>/dev/null
    if [ ! -f "$BB" ]; then
        echo "BusyBox download failed"
        exit 1
    fi
    chmod +x "$BB" 2>/dev/null

    curl -fsSL "$SCRIPT_URL" -o "$TMP_SCRIPT" 2>/dev/null
    if [ ! -f "$TMP_SCRIPT" ]; then
        echo "Script download failed"
        exit 1
    fi

    "$BB" ash "$TMP_SCRIPT"
fi
