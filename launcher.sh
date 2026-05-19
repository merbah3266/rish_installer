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
        printf "\033[1;31m[x]\033[0m Unsupported architecture ($ARCH)\n" >&2
        self_cleanup
        exit 1
        ;;
esac
TMP_DIR="${TMPDIR:-/data/local/tmp}"
BINARY_PATH="$TMP_DIR/$BINARY"
URL="https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/binaries/$BINARY"
if command -v curl >/dev/null 2>&1; then
    curl -sLo "$BINARY_PATH" "$URL" || {
        printf "\033[1;31m[x]\033[0m Download failed (curl)\n" >&2
        self_cleanup
        exit 1
    }
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$BINARY_PATH" "$URL" || {
        printf "\033[1;31m[x]\033[0m Download failed (wget)\n" >&2
        self_cleanup
        exit 1
    }
else
    printf "\033[1;31m[x]\033[0m curl or wget are required\n" >&2
    self_cleanup
    exit 1
fi
chmod +x "$BINARY_PATH" 2>/dev/null || {
    printf "\033[1;31m[x]\033[0m chmod failed\n" >&2
    self_cleanup
    exit 1
}
"$BINARY_PATH" "$@"
EXIT_CODE=$?
rm -f "$BINARY_PATH"
self_cleanup
exit $EXIT_CODE
