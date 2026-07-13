# Shizuku Rish Installer

A lightweight installer for Shizuku's Rish (Remote Shell) on Android terminal applications.

This project is available in two editions:

- **Bash Edition** (`main`) – Feature-rich, with automatic BusyBox fallback for minimal environments.
- **Native C Edition** (`clang_version`) – Lightweight, fast, and designed with minimal external dependencies.

Both editions provide the same installation experience, support the same command-line options, and are compatible with the same installation sources.

> **Did you know?** The Native C Edition is only about **32KB**, starts almost instantly, and performs ZIP extraction using the built-in **miniz** library instead of external utilities.

# Quick Start

Choose the edition you want to use.

## Install Interactively

### Bash Edition

```bash
bash <(curl -fsSL tinyurl.com/rish3266)
```

### Native C Edition

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh)
```

## Run using `sh` (No Bash required)

### Bash Edition

```bash
curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/main/rish_launcher.sh | sh
```

### Native C Edition

```bash
curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh | sh
```

## Pass Command-Line Flags via `sh`

### Bash Edition

```bash
curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/main/rish_launcher.sh | sh -s -- --silent
```

### Native C Edition

```bash
curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh | sh -s -- --silent
```

## Uninstall

### Bash Edition

```bash
bash <(curl -fsSL tinyurl.com/rish3266) --uninstall
```

### Native C Edition

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --uninstall
```

# Native C Edition Features

Why choose the Native C edition?

* **Ultra-Lightweight:** Compiled binary (~32KB).
* **Fast Startup:** Native executable with no shell parsing overhead.
* **Minimal Dependencies:** Uses built-in **miniz** for ZIP extraction and **libcurl** for downloads instead of relying on external tools such as `unzip`, `sed`, and `grep`.
* **Same User Experience:** Supports the same interactive menu, installation sources, and command-line options as the Bash edition.

# Features

The following features are available in both editions unless otherwise noted.

* **Offline Mode:** Extracts `rish` directly from the installed Shizuku application whenever possible.
* **Default Source:** Selecting `default` (explicitly with `--source default` or implicitly when no source is specified in Silent Mode) first attempts Offline Mode. If no local Shizuku installation is found, the installer downloads the latest release from `RikkaApps/Shizuku`.
* **Multiple Installation Sources:** Supports the installed application, GitHub releases, custom repositories, direct APK URLs, and local APK files.
* **Interactive & Silent Modes:** Suitable for both interactive use and automated scripts.
* **Automatic Package Detection:** Detects the terminal application's Android package automatically and patches `rish` accordingly.
* **Smart Installation Paths:** Attempts to install into the terminal's binary directory first, then falls back to the user's home directory when necessary.
* **Safe by Design:** Refuses to run as the root user.
* **BusyBox Fallback (Bash Edition only):** Automatically downloads BusyBox when required utilities are unavailable.

# Command-line Reference

Both editions support the exact same command-line interface.

## Available Options

| Option | Description |
|---------|-------------|
| `--silent` | Performs a non-interactive installation. |
| `--reinstall` | Reinstalls `rish` without asking for confirmation. |
| `--uninstall` | Removes all installed files. |
| `--source <mode>` | Selects the APK source. |
| `--path <value>` | Specifies a repository, URL, or local file path depending on the selected source. |

## Source Modes

The installer supports the following values for `--source`:

| Source | Description | Requires `--path` |
|---------|-------------|-------------------|
| `default` | Uses the default installation logic. First attempts Offline Mode, then falls back to the latest release from `RikkaApps/Shizuku` if necessary. | No |
| `local_app` | Extracts the APK from the installed Shizuku application only. | No |
| `thedjchi` | Downloads the latest release from `thedjchi/Shizuku`. | No |
| `custom_repo` | Downloads the latest release from any GitHub repository. | Yes |
| `custom_url` | Downloads an APK from a direct URL. | Yes |
| `local_file` | Uses an APK already stored on the device. | Yes |

## Examples

### Silent Installation

Installs without displaying any interactive prompts.

### Bash Edition

```bash
bash <(curl -fsSL tinyurl.com/rish3266) --silent
```

### Native C Edition

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --silent
```

### Force Reinstall

Skips the reinstall confirmation dialog if `rish` is already installed.

### Bash Edition

```bash
bash <(curl -fsSL tinyurl.com/rish3266) --reinstall
```

### Native C Edition

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --reinstall
```

### Offline Mode

Extracts the APK directly from the installed Shizuku application.

### Bash Edition

```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source local_app
```

### Native C Edition

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --source local_app
```

### Download from `thedjchi/Shizuku`

### Bash Edition

```bash
bash <(curl -fsSL tinyurl.com/rish3266) --source thedjchi
```

### Native C Edition

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) --source thedjchi
```

### Download from a Custom GitHub Repository

Specify the repository in the format:

```
username/repository
```

### Bash Edition

```bash
bash <(curl -fsSL tinyurl.com/rish3266) \
    --source custom_repo \
    --path username/repository
```

### Native C Edition

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) \
    --source custom_repo \
    --path username/repository
```

### Download from a Direct APK URL

### Bash Edition

```bash
bash <(curl -fsSL tinyurl.com/rish3266) \
    --source custom_url \
    --path https://example.com/shizuku.apk
```

### Native C Edition

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) \
    --source custom_url \
    --path https://example.com/shizuku.apk
```

### Install from a Local APK

### Bash Edition

```bash
bash <(curl -fsSL tinyurl.com/rish3266) \
    --source local_file \
    --path /sdcard/Download/shizuku.apk
```

### Native C Edition

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) \
    --source local_file \
    --path /sdcard/Download/shizuku.apk
```

### Combining Options

Options may be combined.

Example:

```bash
--silent --reinstall --source thedjchi
```

Bash Edition:

```bash
bash <(curl -fsSL tinyurl.com/rish3266) \
    --silent \
    --reinstall \
    --source thedjchi
```

Native C Edition:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/merbah3266/rish_installer/clang_version/launcher.sh) \
    --silent \
    --reinstall \
    --source thedjchi
```

# How It Works

The installer performs the following steps:

1. **Package Detection**
   - Detects the Android package name of the current terminal application.
   - The detected package is used to patch `rish` so it communicates with the correct terminal application.

2. **APK Acquisition**
   - Depending on the selected source, the installer:
     - Extracts the installed Shizuku APK (Offline Mode),
     - Downloads the latest release from GitHub,
     - Downloads an APK from a direct URL,
     - Uses a local APK file.

3. **Extraction**
   - Both `rish` and `rish_shizuku.dex` are extracted from the APK.
   - Bash Edition uses external utilities (or BusyBox when required).
   - Native C Edition performs extraction using the built-in **miniz** library.

4. **Patching**
   - The installer replaces the placeholder package name inside `rish` with the detected Android package name.

5. **Installation**
   - Attempts to install into the terminal's binary directory.
   - If installation is not permitted, it automatically installs into the user's home directory instead.

6. **Cleanup**
   - Temporary files are removed automatically before exiting.

# Interactive Menu

Running the installer without command-line options opens the interactive menu.

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

# Requirements & Notes

* **Supported Terminals**
  * **Termux** — Fully supported and recommended.
  * **MT Manager Terminal** — Supported.
  * Other Android terminal applications may be compatible, but they are not officially supported. For the best experience, use one of the terminals listed above.

* **Offline Mode (Recommended)**
  * If Shizuku is already installed on your device, Offline Mode is the recommended installation method.
  * It extracts `rish` directly from the installed APK, ensuring it always matches the installed Shizuku version.

* **Play Store Users**
  * The Play Store release of Shizuku may not always match the latest GitHub release.
  * If you installed Shizuku from the Play Store, **Offline Mode is strongly recommended** because it extracts `rish` directly from your installed application instead of downloading a different release.

* **GitHub Users**
  * If you installed Shizuku from GitHub, you may use either Offline Mode or download the latest release directly.

* **Offline Mode Limitation**
  * Offline extraction may fail in MT Manager terminal because of Android permission restrictions.
  * If this happens, simply choose another installation source.

* **Internet Connection**
  * Required only when downloading from GitHub, a custom repository, or a direct APK URL.

* **Shizuku**
  * Ensure Shizuku is running.
  * Make sure your terminal application has been authorized in Shizuku before running `rish`.

* **Root**
  * Do not run the installer as the root user.

* **Native C Edition**
  * The source code for the Native C Edition is maintained in the [`clang_version`](https://github.com/merbah3266/rish_installer/tree/clang_version) branch.

# Support

Questions, bug reports, feature requests, suggestions, and feedback are always welcome. If you encounter an issue or have an idea to improve the project, please open an issue on the project's [GitHub Issues](https://github.com/merbah3266/rish_installer/issues) page.

# Star History

<a href="https://www.star-history.com/?repos=merbah3266%2Frish_installer&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=merbah3266/rish_installer&type=date&theme=dark&legend=top-left&sealed_token=rkgV5ZbCimpbq4rJQLc3u_-ZSyiEEatzxTGk3htqZB8EawFhqOrHFQ1Cymm6FGSYa-HWW81Kaydeh-tzjZtNc0G_qSnv5DeTHQXSeiX2JmQ_OuadyJFJtQ" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=merbah3266/rish_installer&type=date&legend=top-left&sealed_token=rkgV5ZbCimpbq4rJQLc3u_-ZSyiEEatzxTGk3htqZB8EawFhqOrHFQ1Cymm6FGSYa-HWW81Kaydeh-tzjZtNc0G_qSnv5DeTHQXSeiX2JmQ_OuadyJFJtQ" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=merbah3266/rish_installer&type=date&legend=top-left&sealed_token=rkgV5ZbCimpbq4rJQLc3u_-ZSyiEEatzxTGk3htqZB8EawFhqOrHFQ1Cymm6FGSYa-HWW81Kaydeh-tzjZtNc0G_qSnv5DeTHQXSeiX2JmQ_OuadyJFJtQ" />
 </picture>
</a>

# Credits

This project includes code from the following open-source project:

- **miniz** by Rich Geldreich
  - Repository: https://github.com/richgel999/miniz
  - License: MIT License
