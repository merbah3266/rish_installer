# Shizuku Rish Installer

A smart, highly customizable, and robust installer for Shizuku's Rish (Remote Shell) on Android terminals.

> **Did you know?** This project now has a **Native C Edition**! It's extremely fast, ultra-lightweight (~32KB), and requires almost zero external tools. [Check it out below](#native-c-edition-features).

## Quick Start

You have two versions to choose from: The original **Bash Script** (feature-rich with BusyBox fallback) and the **Native C Binary** (ultra-fast and standalone).

### Install Interactively

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266)
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh)
```

### Run using `sh` (No Bash required)

**Bash Version:**
```bash
curl -fSsL https://raw.githubusercontent.com/merbah3266/rish_installer/main/rish_launcher.sh | sh
```
**C Version:**
```bash
curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh | sh
```

### Pass flags via `sh`

**Bash Version:**
```bash
curl -fSsL https://raw.githubusercontent.com/merbah3266/rish_installer/main/rish_launcher.sh | sh -s -- --silent
```
**C Version:**
```bash
curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh | sh -s -- --silent
```

### Uninstall

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --uninstall
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --uninstall
```

## Native C Edition Features

Why should you try the C version? 

*   **Ultra-Lightweight:** The compiled binary is only **~32KB** in size!
*   **Blazing Fast:** Executes instantly as native machine code. No script parsing overhead.
*   **Almost Zero Dependencies:** Does not rely on system `unzip`, `sed`, `grep`, or even `curl` executables. It uses built-in `miniz` for ZIP extraction and `libcurl` for downloads.

## Features (Applies to both versions)

*   **Smart Offline-First:** Automatically tries to extract Rish from the installed Shizuku app before downloading from the internet.
*   **Interactive & Silent Modes:** User-friendly menu by default, or completely silent for automation and scripts.
*   **Multiple Sources:** Download from the official repo, alternative repos, direct URLs, or local APK files.
*   **Automatic BusyBox Fallback (Bash only):** If your terminal lacks standard tools, it automatically downloads a standalone BusyBox binary.
*   **Smart Installation Paths:** Tries to install to the system `$BIN` first; if permission is denied, it falls back to `$HOME` and creates symlinks automatically.
*   **Auto Package Detection:** Automatically detects your terminal's package name (e.g., `com.termux`) to configure Rish correctly.
*   **Safe by Design:** Refuses to run as `root` automatically, protecting your environment.

## Advanced Usage (Flags)

Both versions share the exact same command-line flags. You can bypass the interactive prompts by passing flags directly.

### Silent Mode
Installs without any interactive prompts. Only prints start, success, or failure messages.

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --silent
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --silent
```

### Force Reinstall
If Rish is already installed, bypass the "Reinstall? [y/N]" prompt and overwrite it directly.

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --reinstall
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --reinstall
```

### Specify Source (`--source` & `--path`)
You can explicitly tell the installer where to get the Shizuku APK.

**1. Force Offline Extraction (Errors out if Shizuku is not installed):**

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source local_app
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --source local_app
```

**2. Alternative GitHub Repo (`thedjchi/Shizuku`):**

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source thedjchi
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --source thedjchi
```

**3. Custom GitHub Repo:**

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source custom_repo --path "username/reponame"
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --source custom_repo --path "username/reponame"
```

**4. Direct URL to APK:**

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source custom_url --path "https://example.com/shizuku.apk"
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --source custom_url --path "https://example.com/shizuku.apk"
```

**5. Local APK File (No internet required):**

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source local_file --path "/sdcard/Download/shizuku.apk"
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --source local_file --path "/sdcard/Download/shizuku.apk"
```

### Combining Flags
You can combine `--silent` with any source flag.

**Silent reinstall from the thedjchi repo:**

**Bash Version:**
```bash
bash <(curl -fsSL tinyurl.com/rish3266) --silent --reinstall --source thedjchi
```
**C Version:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --silent --reinstall --source thedjchi
```

## How It Works (Under the Hood)

1.  **Package Detection:** The script/binary checks `$PREFIX`, `$PWD`, and `$HOME` to figure out your terminal app's Android package name (e.g., `com.termux`). This is required for Rish to bind to Shizuku.
2.  **APK Acquisition:** Based on your choice (or the default logic):
    *   It first attempts to run `cmd package path` to find the installed Shizuku APK and copy it.
    *   If offline fails or a remote source is selected, it queries the GitHub API to find the latest release APK URL and downloads it.
3.  **Extraction & Patching:** 
    *   *Bash:* Unzips the APK, uses `sed`/`grep` to patch the `rish` file.
    *   *C Native:* Uses `miniz` to extract directly from the ZIP stream, and C string manipulation to patch the file instantly.
4.  **Installation:** Attempts to install the files to `$BIN`. If permission is denied, it gracefully falls back to installing directly in `$HOME` and creates symlinks (`~/rish`, `~/rish_shizuku.dex`).

## Interactive Menu Options

When you run the installer without flags, you are presented with the following menu:

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

## Requirements & Notes

*   **Terminal App:** Termux or MT Manager terminal is highly recommended.
*   **Offline Mode Limitation:** The Offline extraction might not work in MT Manager terminal due to internal permission restrictions. If it fails, please choose an online source or a local APK file.
*   **Shizuku Running:** Ensure the Shizuku app is running and your terminal app is authorized in Shizuku's permissions.
*   **Internet Connection:** Required only if you are downloading from a GitHub repo or Direct URL.
*   **Shizuku Version:** It is highly recommended to use the [latest version](https://github.com/RikkaApps/Shizuku/releases/) of Shizuku from GitHub. The Play Store version is often outdated.

## Support

If the script does not work correctly, please [open an issue](https://github.com/merbah3266/rish_installer/issues) on the repository page so we can help you.
