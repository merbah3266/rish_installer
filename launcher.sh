self_cleanup() {
    case "$0" in
        *proc*) ;;
        *)
            [ -w "$0" ] && rm -f "$0"
            ;;
    esac
}

[ "$(id -u)" -eq 0 ] && {
    printf "\033[1;31m[x]\033[0m Please do not run this as root!\n" >&2
    self_cleanup
    exit 1
}

ARCH=$(uname -m)

case "$ARCH" in
    aarch64|arm64|armv8*)
        BINARY="rish_installer_arm64"
        ;;
    armv7*|arm|armhf)
        BINARY="rish_installer_armv7"
        ;;
    *)
        printf "\033[1;31m[x]\033[0m Unsupported architecture (%s)\n" "$ARCH" >&2
        self_cleanup
        exit 1
        ;;
esac

URL="https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/binaries/$BINARY"

TMP_BIN="${TMPDIR:-$HOME}/$BINARY"
HOME_BIN="$HOME/$BINARY"

download() {
    if command -v curl >/dev/null 2>&1; then
        curl -sLo "$1" "$URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$1" "$URL"
    else
        printf "\033[1;31m[x]\033[0m curl or wget are required\n" >&2
        return 1
    fi
}

run_binary() {
    chmod +x "$1" 2>/dev/null || return 1
    "$1" "$@"
}

download "$TMP_BIN" || {
    printf "\033[1;31m[x]\033[0m Download failed\n" >&2
    self_cleanup
    exit 1
}

[ -s "$TMP_BIN" ] || {
    printf "\033[1;31m[x]\033[0m Empty download\n" >&2
    self_cleanup
    exit 1
}

if run_binary "$TMP_BIN" "$@"; then
    EXIT_CODE=$?
    rm -f "$TMP_BIN"
    self_cleanup
    exit $EXIT_CODE
fi

mv -f "$TMP_BIN" "$HOME_BIN" 2>/dev/null
chmod +x "$HOME_BIN" 2>/dev/null

printf "[!] retrying from HOME...\n" >&2

if run_binary "$HOME_BIN" "$@"; then
    EXIT_CODE=$?
    rm -f "$HOME_BIN"
    self_cleanup
    exit $EXIT_CODE
fi

printf "\033[1;31m[x]\033[0m Execution failed in both TMP and HOME\n" >&2

rm -f "$HOME_BIN" "$TMP_BIN"
self_cleanup
exit 1
