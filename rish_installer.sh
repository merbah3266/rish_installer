set -euo pipefail
if command -v tput >/dev/null 2>&1 && [ -t 1 ] && [ "$(tput colors 2>/dev/null)" -ge 8 ]; then
  R='\033[1;31m'; G='\033[1;32m'; B='\033[1;34m'; Y='\033[1;33m'; X='\033[0m'
else
  R=''; G=''; B=''; Y=''; X=''
fi
msg(){ echo -e "${B}[*]${X} $1"; }
ok(){ echo -e "${G}[+]${X} $1"; }
warn(){ echo -e "${Y}[-]${X} $1"; }
err(){ echo -e "${R}[!]${X} $1"; }
hide_cursor(){
  if command -v tput >/dev/null 2>&1; then
    tput civis 2>/dev/null || echo -ne '\e[?25l'
  else
    echo -ne '\e[?25l'
  fi
}
show_cursor(){
  if command -v tput >/dev/null 2>&1; then
    tput cnorm 2>/dev/null || echo -ne '\e[?25h'
  else
    echo -ne '\e[?25h'
  fi
}
cleanup(){
  show_cursor
  if [ -n "${TMPDIR:-}" ] && [ -d "${TMPDIR}" ]; then
    rm -rf "${TMPDIR}"
  fi
}
trap cleanup EXIT INT TERM HUP
if [ "$(id -u)" = 0 ]; then
  err "Running as root is not allowed"
  exit 1
fi
BIN_PATH=${BASH:-$(command -v bash 2>/dev/null)}
if [ -n "$BIN_PATH" ]; then
  BIN=$(dirname "$BIN_PATH")
else
  BIN=$(dirname "$(command -v sh)")
fi
RISH="$BIN/rish"
for tool in curl unzip sed install; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    err "Required tool '$tool' is missing"
    exit 1
  fi
done
if [ -f "$RISH" ]; then
  warn "rish already exists — will update"
else
  msg "rish not found — will install"
fi
hide_cursor
msg "Fetching latest Shizuku release info..."
U=$(curl -sL "https://api.github.com/repos/RikkaApps/Shizuku/releases/latest" \
  | grep -E "browser_download_url" \
  | grep "\.apk" \
  | head -n1 \
  | sed -E 's/.*"(https.*\.apk)".*/\1/' ) || {
  show_cursor
  err "Failed to fetch release info"
  exit 1
}
if [ -z "${U}" ]; then
  show_cursor
  err "No APK URL found in release info"
  exit 1
fi
msg "Downloading Shizuku APK..."
TMPDIR=$(mktemp -d)
if ! curl -sS -L -o "$TMPDIR/S.apk" "$U"; then
  show_cursor
  err "Failed to download APK from: $U"
  rm -rf "$TMPDIR"
  exit 1
fi
msg "Extracting rish from Shizuku APK..."
unzip -q "$TMPDIR/S.apk" -d "$TMPDIR"
if [ ! -f "$TMPDIR/assets/rish" ] || [ ! -f "$TMPDIR/assets/rish_shizuku.dex" ]; then
  show_cursor
  err "APK does not contain required files (assets/rish or assets/rish_shizuku.dex)"
  rm -rf "$TMPDIR"
  exit 1
fi
msg "Installing rish..."
install -m644 "$TMPDIR/assets/rish_shizuku.dex" "$BIN/"
install -m755 "$TMPDIR/assets/rish" "$BIN/"
if [ -f "$RISH" ]; then
  sed -i '/^#/d;s/PKG/com.termux/g' "$RISH" || warn "sed modification on $RISH failed"
fi
ln -sf "$BIN/rish" "$HOME/rish" || warn "Failed to create $HOME/rish"
ln -sf "$BIN/rish_shizuku.dex" "$HOME/rish_shizuku.dex" || warn "Failed to create $HOME/rish_shizuku.dex"
rm -rf "$TMPDIR"
ok "rish installation completed successfully"
show_cursor
exit 0