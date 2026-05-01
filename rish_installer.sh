BIN="$(dirname "$(command -v bash)")"
RISH="$BIN/rish"; DEX="$BIN/rish_shizuku.dex"
ACTION="install"; SILENT_MODE=0; SOURCE_MODE="default"; SOURCE_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) ACTION="uninstall" ;;
    --reinstall) ACTION="reinstall" ;;
    --silent) SILENT_MODE=1 ;;
    --source=*) SOURCE_MODE="${1#*=}" ;;
    --source) shift; SOURCE_MODE="$1" ;;
    --path=*) SOURCE_PATH="${1#*=}" ;;
    --path) shift; SOURCE_PATH="$1" ;;
  esac
  shift
done
if [ "$ACTION" = "uninstall" ]; then
  rm -f "$RISH" "$DEX" "$HOME/rish" "$HOME/rish_shizuku.dex"
  find "$HOME" -maxdepth 1 -type l -name "rish*" -delete 2>/dev/null || true
  echo "[+] rish has been removed."; exit 0
fi
if [ -t 1 ]; then C0='\033[0m' CR='\033[1;31m' CG='\033[1;32m' CY='\033[1;33m' CB='\033[1;34m' CC='\033[1;36m'; else C0='' CR='' CG='' CY='' CB='' CC=''; fi
msg(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CB}[i]${C0} $1"; }
ok(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CG}[+]${C0} $1"; }
warn(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CY}[!]${C0} $1"; }
err(){ echo -e "${CR}[x]${C0} $1"; exit 1; }
step(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CC}==>${C0} $1"; }
cleanup(){ rm -rf "${TMP_SUBDIR:-}"; }; trap cleanup EXIT
detect_pkg(){
  p="${PREFIX:-$(pwd)}"
  if [[ "$p" == /data/data/* ]]; then echo "${p#/data/data/}" | cut -d/ -f1; return; fi
  if [[ "$p" == /data/user/* ]]; then echo "$p" | cut -d/ -f5; return; fi
  if [ -n "$HOME" ]; then
    if [[ "$HOME" == /data/data/* ]]; then echo "${HOME#/data/data/}" | cut -d/ -f1; return; fi
    if [[ "$HOME" == /data/user/* ]]; then echo "$HOME" | cut -d/ -f5; return; fi
  fi
  echo "unknown"
}
PKG="$(detect_pkg)"; [ "$PKG" = "unknown" ] && err "Package detect failed"
if [ -f "$RISH" ] && [ "$ACTION" != "reinstall" ] && [ "$SILENT_MODE" -eq 0 ]; then
  echo -ne "${CY}[?]${C0} rish installed. Reinstall? [y/N]: "; read -r c < /dev/tty
  case "$c" in y|Y) ACTION="reinstall" ;; *) msg "Cancelled."; exit 0 ;; esac
fi
if [ "$SILENT_MODE" -eq 0 ] && [ -z "$SOURCE_PATH" ]; then
  echo -e "\n${CB}Select source:${C0}\n 1) Offline (Extract app)\n 2) RikkaApps/Shizuku\n 3) thedjchi/Shizuku\n 4) Custom Repo\n 5) Direct URL\n 6) Local APK"
  read -p "Choice [1-6]: " src_choice < /dev/tty
  case "$src_choice" in
    1) SOURCE_MODE="local_app" ;; 2) SOURCE_MODE="default" ;; 3) SOURCE_MODE="thedjchi" ;;
    4) SOURCE_MODE="custom_repo"; read -p "Repo (user/repo): " SOURCE_PATH < /dev/tty ;;
    5) SOURCE_MODE="custom_url"; read -p "URL: " SOURCE_PATH < /dev/tty ;;
    6) SOURCE_MODE="local_file"; read -p "Path: " SOURCE_PATH < /dev/tty ;;
    *) SOURCE_MODE="default" ;;
  esac
fi
[ "$SILENT_MODE" -eq 1 ] && echo "[+] Starting silent rish installation..."
TMP_SUBDIR="$(mktemp -d "${TMPDIR:-/tmp}/rish.XXXX")"
PLAN_A=1; for t in unzip sed grep install; do command -v "$t" >/dev/null || PLAN_A=0; done
if [ "$PLAN_A" -eq 1 ]; then UNZIP=unzip; SED=sed; GREP=grep; INSTALL=install
else
  warn "Using busybox"; ARCH="$(uname -m)"; case "$ARCH" in aarch64|arm64|armv8*) ARCH=arm64;; armv*|armhf|arm) ARCH=arm;; x86_64|amd64) ARCH=x86_64;; i386|i686|x86) ARCH=x86;; *) err "Unsupported arch";; esac
  BB="$TMP_SUBDIR/busybox"; step "Downloading BusyBox..."; curl -fsSL "https://raw.githubusercontent.com/merbah3266/rish_installer/main/busybox/$ARCH/busybox" -o "$BB" || err "BB download failed"; chmod +x "$BB"
  UNZIP="$BB unzip"; SED="$BB sed"; GREP="$BB grep"; INSTALL="$BB install"; ok "BusyBox ready."
fi
APK_PATH="$TMP_SUBDIR/app.apk"; OFFLINE_OK=0
if [ "$SOURCE_MODE" = "local_app" ] || [ "$SOURCE_MODE" = "default" ]; then
  step "Offline attempt..."; EXTRACTED="$(cmd package path moe.shizuku.privileged.api --user 0 2>/dev/null | cut -d: -f2)"
  if [ -n "$EXTRACTED" ] && cp "$EXTRACTED" "$APK_PATH" 2>/dev/null; then ok "Local APK extracted"; OFFLINE_OK=1
  elif [ "$SOURCE_MODE" = "local_app" ]; then err "Shizuku not found locally"
  else warn "Offline failed, falling back online..."; fi
fi
if [ "$OFFLINE_OK" -eq 0 ]; then
  case "$SOURCE_MODE" in
    local_file) step "Using local file"; [ -z "$SOURCE_PATH" ] && err "No path"; [ ! -f "$SOURCE_PATH" ] && err "File not found"; cp "$SOURCE_PATH" "$APK_PATH" || err "Copy failed"; ok "Copied" ;;
    custom_url) step "Downloading from URL"; [ -z "$SOURCE_PATH" ] && err "No URL"; curl -fsSL -o "$APK_PATH" "$SOURCE_PATH" || err "Download failed"; ok "Downloaded" ;;
    default|thedjchi|custom_repo)
      if [ "$SOURCE_MODE" = "default" ]; then REPO="RikkaApps/Shizuku"; elif [ "$SOURCE_MODE" = "thedjchi" ]; then REPO="thedjchi/Shizuku"; else REPO="$SOURCE_PATH"; fi
      step "Fetching from $REPO..."; URL="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\.apk\)".*/\1/p' | head -n1)"; [ -z "$URL" ] && err "URL fetch failed"
      step "Downloading APK..."; curl -fsSL -o "$APK_PATH" "$URL" || err "Download failed"; ok "Downloaded" ;;
    *) err "Invalid source" ;;
  esac
fi
step "Extracting..."; $UNZIP -qq "$APK_PATH" -d "$TMP_SUBDIR" || err "Unzip failed"
[ ! -f "$TMP_SUBDIR/assets/rish" ] && err "rish not found"; [ ! -f "$TMP_SUBDIR/assets/rish_shizuku.dex" ] && err "dex not found"
SH_PATH="$(command -v sh)"; [ -z "$SH_PATH" ] && err "sh not found"
TMP_RISH="$(mktemp "$TMP_SUBDIR/rish.XXXX")"; echo "#!$SH_PATH" > "$TMP_RISH"; $GREP -v '^#' "$TMP_SUBDIR/assets/rish" >> "$TMP_RISH"; $SED -i "s/PKG/$PKG/g" "$TMP_RISH"
step "Installing..."; INSTALL_SUCCESS=0
if $INSTALL -m755 "$TMP_RISH" "$RISH" 2>/dev/null && $INSTALL -m400 "$TMP_SUBDIR/assets/rish_shizuku.dex" "$DEX" 2>/dev/null; then
  ok "Installed to bin ($BIN)"; ln -sf "$RISH" "$HOME/rish" 2>/dev/null; ln -sf "$DEX" "$HOME/rish_shizuku.dex" 2>/dev/null; INSTALL_SUCCESS=1
else
  warn "Bin failed, trying Home..."; if $INSTALL -m755 "$TMP_RISH" "$HOME/rish" && $INSTALL -m400 "$TMP_SUBDIR/assets/rish_shizuku.dex" "$HOME/rish_shizuku.dex"; then ok "Installed to Home"; INSTALL_SUCCESS=1; fi
fi
if [ "$INSTALL_SUCCESS" -eq 1 ]; then [ "$SILENT_MODE" -eq 1 ] && echo "[+] Success: rish installed." || ok "Setup complete. Run 'rish' or '~/rish'"; else err "Installation failed"; fi
