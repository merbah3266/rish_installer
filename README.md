# Shizuku Rish Installer

A smart, highly customizable, and robust installer for Shizuku's Rish (Remote Shell) on Android terminals.

---

## Features

*   **Smart Offline-First:** Automatically tries to extract Rish from the installed Shizuku app before downloading from the internet.
*   **Interactive & Silent Modes:** User-friendly menu by default, or completely silent for automation and scripts.
*   **Multiple Sources:** Download from the official repo, alternative repos, direct URLs, or local APK files.
*   **Automatic BusyBox Fallback:** If your terminal lacks standard tools (`unzip`, `sed`, `grep`), it automatically downloads a standalone BusyBox binary to use instead.
*   **Smart Installation Paths:** Tries to install to the system `$BIN` first; if permission is denied, it falls back to `$HOME` and creates symlinks automatically.
*   **Auto Package Detection:** Automatically detects your terminal's package name (e.g., `com.termux`) to configure Rish correctly.

---

## Quick Start (Basic Usage)

**To install interactively:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266)
```

**To uninstall:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --uninstall
```

**To run Rish after installation:**
```bash
rish
```
*(If `rish` doesn't work, use `~/rish`)*

---

## Advanced Usage (Flags)

You can bypass the interactive prompts by passing flags directly.

### Silent Mode
Installs without any interactive prompts. Only prints start, success, or failure messages.
*Logic: In silent mode, the script prioritizes extracting from the installed app (Offline). If that fails, it automatically falls back to downloading from the official RikkaApps repo.*
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --silent
```

### Force Reinstall
If Rish is already installed, bypass the "Reinstall? [y/N]" prompt and overwrite it directly.
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --reinstall
```

### Specify Source (`--source` & `--path`)
You can explicitly tell the script where to get the Shizuku APK.

**1. Force Offline Extraction (Errors out if Shizuku is not installed):**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source local_app
```

**2. Alternative GitHub Repo (`thedjchi/Shizuku`):**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source thedjchi
```

**3. Custom GitHub Repo:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source custom_repo --path "username/reponame"
```

**4. Direct URL to APK:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source custom_url --path "https://example.com/shizuku.apk"
```

**5. Local APK File (No internet required):**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source local_file --path "/sdcard/Download/shizuku.apk"
```

### Combining Flags
You can combine `--silent` with any source flag to create the exact installation flow you need:

**Silent install from a direct URL:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --silent --source custom_url --path "https://example.com/app.apk"
```

**Silent reinstall from the thedjchi repo:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --silent --reinstall --source thedjchi
```

---

## How It Works (Under the Hood)

1.  **Package Detection:** The script checks `$PREFIX`, `$PWD`, and `$HOME` to figure out your terminal app's Android package name (e.g., `com.termux`). This is required for Rish to bind to Shizuku.
2.  **Tool Verification:** It checks if `unzip`, `sed`, `grep`, and `install` are available. If not, it detects your CPU architecture and downloads a standalone BusyBox binary to use instead.
3.  **APK Acquisition:** Based on your choice (or the default logic):
    *   It first attempts to run `cmd package path` to find the installed Shizuku APK and copy it.
    *   If offline fails or a remote source is selected, it queries the GitHub API to find the latest release APK URL and downloads it via `curl`.
4.  **Extraction & Patching:** The script unzips the APK, extracts `assets/rish` and `assets/rish_shizuku.dex`, removes comment lines from `rish`, replaces the `PKG` placeholder with your detected package name, and attaches the correct shebang (`#!/path/to/sh`).
5.  **Installation:** It attempts to install the files to `$BIN` (where `bash` resides). If permission is denied, it gracefully falls back to installing directly in `$HOME` and creates symlinks (`~/rish`, `~/rish_shizuku.dex`) for easy access.

---

## Interactive Menu Options

When you run the script without flags, you are presented with the following menu:

```text
Select source:
 1) Offline (Extract app)
 2) RikkaApps/Shizuku
 3) thedjchi/Shizuku
 4) Custom Repo
 5) Direct URL
 6) Local APK
Choice [1-6]:
```

*   **Option 1:** Tries to copy the APK from the installed Shizuku app. (Fails if Shizuku is not installed).
*   **Option 2:** Downloads the latest release from the official [RikkaApps/Shizuku](https://github.com/RikkaApps/Shizuku) repository.
*   **Option 3:** Downloads the latest release from the [thedjchi/Shizuku](https://github.com/thedjchi/Shizuku) alternative repository.
*   **Option 4:** Prompts you for a `username/reponame` to download from a custom GitHub repository.
*   **Option 5:** Prompts you for a direct URL linking to an `.apk` file.
*   **Option 6:** Prompts you for a local file path (e.g., `/sdcard/Download/app.apk`) to install from.

---

## Requirements & Notes

*   **Terminal App:** Termux or MT Manager terminal is highly recommended.
*   **Offline Mode Limitation:** The Offline extraction (`local_app` or silent default) might not work in MT Manager terminal due to internal permission restrictions. If it fails in MT Manager, please choose an online source or a local APK file instead.
*   **Shizuku Running:** Ensure the Shizuku app is running and your terminal app is authorized in Shizuku's permissions.
*   **Internet Connection:** Required only if you are downloading from a GitHub repo or Direct URL. Not required for `local_app` or `local_file` sources.
*   **Shizuku Version:** It is highly recommended to use the [latest version](https://github.com/RikkaApps/Shizuku/releases/) of Shizuku from GitHub. The Play Store version is often outdated and may not work correctly with Rish.

## Support

If the script does not work correctly, please [open an issue](https://github.com/merbah3266/rish_installer/issues) on the repository page so we can help you.
