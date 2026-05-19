ARCH=$(uname -m)
case "$ARCH" in
aarch64|arm64|armv8*) BINARY="rish_installer_arm64" ;;
armv7*|arm|armhf) BINARY="rish_installer_armv7" ;;
*) echo "Error: Unsupported architecture ($ARCH)" >&2; exit 1 ;;
esac
TMP_DIR="${TMPDIR:-/data/local/tmp}"
BINARY_PATH="$TMP_DIR/$BINARY"
URL="https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/binaries/$BINARY"
if command -v curl >/dev/null 2>&1; then
curl -sLo "$BINARY_PATH" "$URL" || { echo "Error: Download failed (curl)" >&2; exit 1; }
elif command -v wget >/dev/null 2>&1; then
wget -qO "$BINARY_PATH" "$URL" || { echo "Error: Download failed (wget)" >&2; exit 1; }
else
echo "Error: curl or wget are required" >&2; exit 1
fi
chmod +x "$BINARY_PATH" 2>/dev/null || { echo "Error: chmod failed" >&2; exit 1; }
"$BINARY_PATH" "$@"
EXIT_CODE=$?
rm -f "$BINARY_PATH"
if [ -w "$0" ]; then
rm -f "$0"
fi
exit $EXIT_CODE
