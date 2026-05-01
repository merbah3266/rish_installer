BIN_PATH="$(command -v bash)"
BIN="$(dirname "$BIN_PATH")"
RISH="$BIN/rish"
DEX="$BIN/rish_shizuku.dex"
ACTION="install"
SILENT_MODE=0
SOURCE_MODE="default"
SOURCE_PATH=""
for a in "$@"; do
  case "$a" in
    --uninstall) ACTION="uninstall" ;;
    --reinstall) ACTION="reinstall" ;;
    --silent) SILENT_MODE=1 ;;
    --source) 
      shift; SOURCE_MODE="$1" 
      ;;
    --path) 
      shift; SOURCE_PATH="$1" 
      ;;
  esac
done
if [ "$ACTION" = "uninstall" ]; then
  rm -f "$RISH" "$DEX" "$HOME/rish" "$HOME/rish_shizuku.dex"
  find "$HOME" -maxdepth 1 -type l -name "rish*" -delete 2>/dev/null || true
  echo "[+] rish has been removed."
  exit 0
fi
if [ -t 1 ]; then
  C0='\033[0m'; CR='\033[31m'; CG='\033[32m'; CY='\033[33m'; CB='\033[34m'; CC='\033[36m'
else
  C0=''; CR=''; CG=''; CY=''; CB=''; CC=''
fi
msg(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CB}[i]${C0} $1"; }
ok(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CG}[+]${C0} $1"; }
warn(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CY}[!]${C0} $1"; }
err(){ echo -e "${CR}[x]${C0} $1"; exit 1; }
step(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CC}==>${C0} $1"; }
cleanup(){ rm -rf "${TMP_SUBDIR:-}"; }
trap cleanup EXIT
detect_pkg(){
  p="${PREFIX:-}"
  [ -z "$p" ] && p="$(pwd)"
  if [[ "$p" == /data/data/* ]]; then echo "${p#/data/data/}" | cut -d/ -f1; return; fi
  if [[ "$p" == /data/user/* ]]; then echo "$p" | cut -d/ -f5; return; fi
  if [ -n "$HOME" ]; then
    if [[ "$HOME" == /data/data/* ]]; then echo "${HOME#/data/data/}" | cut -d/ -f1; return; fi
    if [[ "$HOME" == /data/user/* ]]; then echo "$HOME" | cut -d/ -f5; return; fi
  fi
  echo "unknown"
}
PKG="$(detect_pkg)"
[ "$PKG" = "unknown" ] && err "Package detect failed"
if [ -f "$RISH" ] && [ "$ACTION" != "reinstall" ] && [ "$SILENT_MODE" -eq 0 ]; then
  echo -ne "${CY}[?]${C0} rish is already installed. Reinstall? [y/N]: "
  read -r c < /dev/tty
  case "$c" in
    y|Y) ACTION="reinstall" ;;
    *) msg "Cancelled."; exit 0 ;;
  esac
fi
if [ "$SILENT_MODE" -eq 0 ] && [ -z "$SOURCE_PATH" ]; then
  echo ""
  echo "Please select the source for Shizuku APK:"
  echo "  1) Extract from installed app (Offline - Recommended)"
  echo "  2) RikkaApps/Shizuku (Default GitHub Repo)"
  echo "  3) thedjchi/Shizuku (Alternative GitHub Repo)"
  echo "  4) Custom GitHub Repo (owner/repo)"
  echo "  5) Direct URL to APK"
  echo "  6) Local APK file path"
  echo ""
  read -p "Enter choice [1-6]: " src_choice < /dev/tty
  case "$src_choice" in
    1) SOURCE_MODE="local_app" ;;
    2) SOURCE_MODE="default" ;;
    3) SOURCE_MODE="thedjchi" ;;
    4) 
      SOURCE_MODE="custom_repo"
      read -p "Enter GitHub repo (e.g., user/repo): " custom_repo < /dev/tty
      SOURCE_PATH="$custom_repo"
      ;;
    5) 
      SOURCE_MODE="custom_url"
      read -p "Enter APK URL: " custom_url < /dev/tty
      SOURCE_PATH="$custom_url"
      ;;
    6) 
      SOURCE_MODE="local_file"
      read -p "Enter local APK path: " local_path < /dev/tty
      SOURCE_PATH="$local_path"
      ;;
    *) SOURCE_MODE="default" ;;
  esac
fi
if [ "$SILENT_MODE" -eq 1 ]; then
  echo "[+] Starting silent rish installation..."
fi
BASE_TMPDIR="${TMPDIR:-/tmp}"
TMP_SUBDIR="$(mktemp -d "$BASE_TMPDIR/rish.XXXXXX")"
PLAN_A=1
for t in unzip sed grep install; do
  command -v "$t" >/dev/null || PLAN_A=0
done
if [ "$PLAN_A" -eq 1 ]; then
  UNZIP=unzip; SED=sed; GREP=grep; INSTALL=install
else
  warn "Using busybox..."
  ARCH="$(uname -m)"
  case "$ARCH" in
    aarch64|arm64|armv8*) ARCH=arm64;;
    armv*|armhf|arm) ARCH=arm;;
    x86_64|amd64) ARCH=x86_64;;
    i386|i686|x86) ARCH=x86;;
    *) err "Unsupported arch";;
  esac
  URL="https://raw.githubusercontent.com/merbah3266/rish_installer/main/busybox/$ARCH/busybox"
  BB="$TMP_SUBDIR/busybox"
  step "Downloading BusyBox..."
  curl -fsSL "$URL" -o "$BB" || err "BusyBox download failed"
  chmod +x "$BB"
  UNZIP="$BB unzip"; SED="$BB sed"; GREP="$BB grep"; INSTALL="$BB install"
  ok "BusyBox ready."
fi
APK_PATH="$TMP_SUBDIR/app.apk"
case "$SOURCE_MODE" in
  local_app)
    step "Offline attempt (Extracting from installed app)"
    EXTRACTED="$(cmd package path moe.shizuku.privileged.api --user 0 2>/dev/null | cut -d: -f2)"
    if [ -z "$EXTRACTED" ]; then
      if [ "$SILENT_MODE" -eq 1 ]; then err "Shizuku app not found locally. Cannot proceed in silent mode."; fi
      warn "Shizuku app not found locally. Please select another source."
      exec "$0" "$@" # Restart script to ask again
    fi
    cp "$EXTRACTED" "$APK_PATH" || err "Permission denied to copy local APK"
    ok "Local APK extracted"
    ;;
  local_file)
    step "Using local file"
    [ -z "$SOURCE_PATH" ] && err "No local path provided"
    [ ! -f "$SOURCE_PATH" ] && err "File not found: $SOURCE_PATH"
    cp "$SOURCE_PATH" "$APK_PATH" || err "Failed to copy local file"
    ok "Local file copied"
    ;;
  custom_url)
    step "Downloading from direct URL"
    [ -z "$SOURCE_PATH" ] && err "No URL provided"
    curl -fsSL -o "$APK_PATH" "$SOURCE_PATH" || err "Download failed from URL"
    ok "Download complete"
    ;;
  default|thedjchi|custom_repo)
    if [ "$SOURCE_MODE" = "default" ]; then
      REPO="RikkaApps/Shizuku"
    elif [ "$SOURCE_MODE" = "thedjchi" ]; then
      REPO="thedjchi/Shizuku"
    else
      REPO="$SOURCE_PATH"
    fi
    step "Fetching latest release from $REPO..."
    URL="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
      | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\.apk\)".*/\1/p' | head -n1)"
    [ -z "$URL" ] && err "Failed to fetch APK URL from $REPO"
    step "Downloading APK..."
    curl -fsSL -o "$APK_PATH" "$URL" || err "Download failed"
    ok "Download complete"
    ;;
  *)
    err "Invalid source mode"
    ;;
esac
step "Extracting files..."
 $UNZIP -qq "$APK_PATH" -d "$TMP_SUBDIR" || err "Extraction failed"
[ ! -f "$TMP_SUBDIR/assets/rish" ] && err "rish not found in APK"
[ ! -f "$TMP_SUBDIR/assets/rish_shizuku.dex" ] && err "dex not found in APK"
SH_PATH="$(command -v sh)"
[ -z "$SH_PATH" ] && err "sh not found"
TMP_RISH="$(mktemp "$TMP_SUBDIR/rish.XXXXXX")"
echo "#!$SH_PATH" > "$TMP_RISH"
 $GREP -v '^#' "$TMP_SUBDIR/assets/rish" >> "$TMP_RISH"
 $SED -i "s/PKG/$PKG/g" "$TMP_RISH"
step "Installing rish..." 
INSTALL_SUCCESS=0
if $INSTALL -m755 "$TMP_RISH" "$RISH" 2>/dev/null && \
   $INSTALL -m400 "$TMP_SUBDIR/assets/rish_shizuku.dex" "$DEX" 2>/dev/null; then
    ok "Installed to bin directory ($BIN)"
    ln -sf "$RISH" "$HOME/rish" 2>/dev/null
    ln -sf "$DEX" "$HOME/rish_shizuku.dex" 2>/dev/null
    INSTALL_SUCCESS=1
else
    warn "Cannot write to bin directory. Trying Home directory..."
    if $INSTALL -m755 "$TMP_RISH" "$HOME/rish" && \
       $INSTALL -m400 "$TMP_SUBDIR/assets/rish_shizuku.dex" "$HOME/rish_shizuku.dex"; then
        ok "Installed to Home directory."
        INSTALL_SUCCESS=1
    else
        INSTALL_SUCCESS=0
    fi
fi
if [ "$INSTALL_SUCCESS" -eq 1 ]; then
    if [ "$SILENT_MODE" -eq 1 ]; then
        echo "[+] Success: rish installed successfully."
    else
        ok "Setup complete. Run 'rish' directly or '~/rish'."
    fi
else
    err "Installation failed completely."
fi
