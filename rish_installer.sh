BIN="$(dirname "$(command -v bash 2>/dev/null)")"
RISH="$BIN/rish"; DEX="$BIN/rish_shizuku.dex"
ACTION="install"; SILENT_MODE=0; SOURCE_MODE="default"; SOURCE_PATH=""; SOURCE_PROVIDED=0
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) ACTION="uninstall" ;;
    --reinstall) ACTION="reinstall" ;;
    --silent) SILENT_MODE=1 ;;
    --source=*) SOURCE_MODE="${1#*=}"; SOURCE_PROVIDED=1 ;;
    --source) shift; SOURCE_MODE="$1"; SOURCE_PROVIDED=1 ;;
    --path=*) SOURCE_PATH="${1#*=}" ;;
    --path) shift; SOURCE_PATH="$1" ;;
  esac
  shift
done
if [ -t 1 ]; then C0='\033[0m' CR='\033[1;31m' CG='\033[1;32m' CY='\033[1;33m' CB='\033[1;34m' CC='\033[1;36m'; else C0='' CR='' CG='' CY='' CB='' CC=''; fi
cancel(){ echo -e "${CY}[!]${C0} $1"; exit 0; }
msg(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CB}[i]${C0} $1"; }
ok(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CG}[+]${C0} $1"; }
warn(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CY}[!]${C0} $1"; }
err(){ echo -e "${CR}[x]${C0} $1"; exit 1; }
step(){ [ "$SILENT_MODE" -eq 0 ] && echo -e "${CC}==>${C0} $1"; }
cleanup() {
    [ -n "$TMP_SUBDIR" ] && rm -rf "$TMP_SUBDIR" 2>/dev/null
}
on_cancel() {
    echo -e "\n${CY}[!]${C0} Operation cancelled by user."
    exit 1
}
trap on_cancel INT
trap cleanup EXIT
if [ "$ACTION" = "uninstall" ]; then
  rm -f "$RISH" "$DEX" "$HOME/rish" "$HOME/rish_shizuku.dex" 2>/dev/null
  find "$HOME" -maxdepth 1 -type l -name "rish*" -delete 2>/dev/null || true
  echo -e "${CG}[+]${C0} rish has been removed."; exit 0
fi
detect_pkg(){
  p="${PREFIX:-$(pwd)}"
  case "$p" in
    /data/data/*) echo "${p#/data/data/}" | cut -d/ -f1; return ;;
    /data/user/*) echo "$p" | cut -d/ -f5; return ;;
  esac
  if [ -n "$HOME" ]; then
    case "$HOME" in
      /data/data/*) echo "${HOME#/data/data/}" | cut -d/ -f1; return ;;
      /data/user/*) echo "$HOME" | cut -d/ -f5; return ;;
    esac
  fi
  echo "unknown"
}
PKG="$(detect_pkg)"; [ "$PKG" = "unknown" ] && err "Package detect failed"
if [ -f "$RISH" ] && [ "$ACTION" != "reinstall" ] && [ "$SILENT_MODE" -eq 0 ]; then
  echo -ne "${CY}[?]${C0} rish installed. Reinstall? [y/N]: "; read -r c < /dev/tty
  case "$c" in y|Y) ACTION="reinstall" ;; *) cancel "Cancelled."; exit 0 ;; esac
fi
if [ "$SILENT_MODE" -eq 0 ] && [ "$SOURCE_PROVIDED" -eq 0 ]; then
  echo -e "\n${CB}Select source:${C0}\n 1) Offline (Extract app)\n 2) RikkaApps/Shizuku\n 3) thedjchi/Shizuku\n 4) Custom Repo\n 5) Direct URL\n 6) Local APK"
  read -p "Choice [1-6]: " src_choice < /dev/tty
  case "$src_choice" in
    1) SOURCE_MODE="local_app" ;; 2) SOURCE_MODE="default" ;; 3) SOURCE_MODE="thedjchi" ;;
    4) SOURCE_MODE="custom_repo"; read -p "Repo (user/repo): " SOURCE_PATH < /dev/tty ;;
    5) SOURCE_MODE="custom_url"; read -p "URL: " SOURCE_PATH < /dev/tty ;;
    6) SOURCE_MODE="local_file"; read -p "Path: " SOURCE_PATH < /dev/tty ;;
    *) cancel "Invalid choice. Cancelled." ;;
  esac
fi
[ "$SILENT_MODE" -eq 1 ] && echo -e "${CG}[+]${C0} Starting silent rish installation..."
RAND_ID="$RANDOM"
TMP_SUBDIR="${TMPDIR:-/tmp}/rish.$RAND_ID"
mkdir -p "$TMP_SUBDIR" 2>/dev/null
PLAN_A=1; for t in unzip sed grep install; do command -v "$t" >/dev/null 2>&1 || PLAN_A=0; done
if [ "$PLAN_A" -eq 1 ]; then UNZIP=unzip; SED=sed; GREP=grep; INSTALL=install
else
  warn "Using busybox"; ARCH="$(uname -m)"; case "$ARCH" in aarch64|arm64|armv8*) ARCH=arm64;; armv*|armhf|arm) ARCH=arm;; x86_64|amd64) ARCH=x86_64;; i386|i686|x86) ARCH=x86;; *) err "Unsupported arch";; esac
  BB="$TMP_SUBDIR/busybox"; step "Downloading BusyBox..."; curl -fsSL "https://raw.githubusercontent.com/merbah3266/rish_installer/main/busybox/$ARCH/busybox" -o "$BB" 2>/dev/null || err "BB download failed"; chmod +x "$BB" 2>/dev/null
  UNZIP="$BB unzip"; SED="$BB sed"; GREP="$BB grep"; INSTALL="$BB install"; ok "BusyBox ready."
fi
APK_PATH="$TMP_SUBDIR/app.apk"; OFFLINE_OK=0
if [ "$SOURCE_MODE" = "local_app" ] || [ "$SOURCE_MODE" = "default" ]; then
  step "Offline attempt..."; EXTRACTED="$(cmd package path moe.shizuku.privileged.api --user 0 2>/dev/null | cut -d: -f2)"
  if [ -n "$EXTRACTED" ] && cp "$EXTRACTED" "$APK_PATH" 2>/dev/null; then ok "Local APK extracted"; OFFLINE_OK=1
  elif [ "$SOURCE_MODE" = "local_app" ]; then cancel "Shizuku not found locally. Cancelled."
  else warn "Offline failed, falling back online..."; fi
fi
if [ "$OFFLINE_OK" -eq 0 ]; then
  case "$SOURCE_MODE" in
    local_file) step "Using local file"; [ -z "$SOURCE_PATH" ] && cancel "No path provided. Cancelled."; [ ! -f "$SOURCE_PATH" ] && cancel "File not found. Cancelled."; cp "$SOURCE_PATH" "$APK_PATH" 2>/dev/null || cancel "Copy failed. Cancelled."; ok "Copied" ;;
    custom_url) step "Downloading from URL"; [ -z "$SOURCE_PATH" ] && cancel "No URL provided. Cancelled."; curl -fsSL -o "$APK_PATH" "$SOURCE_PATH" 2>/dev/null || cancel "Download failed. Cancelled."; ok "Downloaded" ;;
    default|thedjchi|custom_repo)
      if [ "$SOURCE_MODE" = "default" ]; then REPO="RikkaApps/Shizuku"; elif [ "$SOURCE_MODE" = "thedjchi" ]; then REPO="thedjchi/Shizuku"; else REPO="$SOURCE_PATH"; fi
      [ -z "$REPO" ] && cancel "No repo provided. Cancelled."
      step "Fetching from $REPO..."; URL="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\.apk\)".*/\1/p' 2>/dev/null)"; [ -z "$URL" ] && cancel "URL fetch failed. Cancelled."
      step "Downloading APK..."; curl -fsSL -o "$APK_PATH" "$URL" 2>/dev/null || cancel "Download failed. Cancelled."; ok "Downloaded" ;;
    *) cancel "Invalid source. Cancelled." ;;
  esac
fi
step "Extracting..."; $UNZIP -qq "$APK_PATH" -d "$TMP_SUBDIR" 2>/dev/null || err "Unzip failed"
[ ! -f "$TMP_SUBDIR/assets/rish" ] && err "rish not found"; [ ! -f "$TMP_SUBDIR/assets/rish_shizuku.dex" ] && err "dex not found"
SH_PATH="$(command -v sh 2>/dev/null)"; [ -z "$SH_PATH" ] && err "sh not found"
TMP_RISH="$TMP_SUBDIR/rish.$RAND_ID"; echo "#!$SH_PATH" > "$TMP_RISH" 2>/dev/null; $GREP -v '^#' "$TMP_SUBDIR/assets/rish" >> "$TMP_RISH" 2>/dev/null; $SED -i "s/PKG/$PKG/g" "$TMP_RISH" 2>/dev/null

step "Installing..."; INSTALL_SUCCESS=0
if $INSTALL -m755 "$TMP_RISH" "$RISH" 2>/dev/null && $INSTALL -m400 "$TMP_SUBDIR/assets/rish_shizuku.dex" "$DEX" 2>/dev/null; then
  ok "Installed to bin ($BIN)"; ln -sf "$RISH" "$HOME/rish" 2>/dev/null; ln -sf "$DEX" "$HOME/rish_shizuku.dex" 2>/dev/null; INSTALL_SUCCESS=1
else
  warn "Bin failed, trying Home..."; if $INSTALL -m755 "$TMP_RISH" "$HOME/rish" 2>/dev/null && $INSTALL -m400 "$TMP_SUBDIR/assets/rish_shizuku.dex" "$HOME/rish_shizuku.dex" 2>/dev/null; then ok "Installed to Home"; INSTALL_SUCCESS=1; fi
fi
if [ "$INSTALL_SUCCESS" -eq 1 ]; then [ "$SILENT_MODE" -eq 1 ] && echo -e "${CG}[+]${C0} Success: rish installed." || ok "Setup complete. Run 'rish' or '~/rish'"; else err "Installation failed"; fi
