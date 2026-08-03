# Nandu Personal Termux Repo (Nandu-repo)

Nandu ka personal Termux APT repository. Is repo se `pkg install` kar ke packages install kar sakte ho.

## One-shot dev environment

```bash
curl -fsSL https://raw.githubusercontent.com/bauaasoni37-cpu/Nandu-repo/main/add-repo.sh | bash
```
```bash
pkg install setup -y
```

`pkg install setup` automatically:
1. Installs `proot-distro` (agar missing hai)
2. Creates Ubuntu container (`proot-distro install ubuntu`)
3. Downloads **Android SDK + NDK** and **Flutter** from GitHub Releases (parallel + resume support) while **simultaneously** installing the ~45 Ubuntu dev packages (Java 17, build-essential, cmake, ninja, git, nodejs, qemu-user, pigz, ...)
4. Applies all configs automatically: `dev_env.sh`, `~/.gradle/gradle.properties`, AAPT2 QEMU wrapper, NDK clang links, `setup`/`pbuild`/`build_project` commands

**Koi manual license accept nahi karna padta, koi manual setup nahi.** Re-run `setup` kabhi bhi — already existing sab skip ho jayega (instant).

> Timing: pehli baar me ~2GB SDK download + extract hoga (network pe depend). Android SDK ~940MB, Flutter ~1.1GB — dono ek saath download hote hain. Re-runs instant.

## Quick install (demo package)

```bash
curl -fsSL https://raw.githubusercontent.com/bauaasoni37-cpu/Nandu-repo/main/add-repo.sh | bash
pkg install nandu-welcome
nandu-welcome
```

## Packages

| Package        | Description                                       |
|----------------|---------------------------------------------------|
| `setup`        | One-shot full dev environment (proot Ubuntu + SDKs + build tools) |
| `nandu-welcome`| Welcome demo package (prints message)              |

## Hosting

- **APT repo** GitHub Pages se serve hota hai: `https://bauaasoni37-cpu.github.io/Nandu-repo/repo`
- **SDK tarballs** GitHub Releases se: `https://github.com/bauaasoni37-cpu/Nandu-repo/releases/download/sdk-v1.0.0/`
  - `android-sdk.tar.gz` (~940 MB) → `/opt/android-sdk`
  - `flutter-sdk.tar.gz` (~1.1 GB) → `/opt/flutter`
- `main` push karne ke baad Pages mirror update karo: `git push origin main:gh-pages`

## Repo structure

```
Nandu-repo/
├── add-repo.sh                    # Termux me repo add karne wali script
├── build-repo.sh                  # Packages build + index regenerate script
├── packages/
│   ├── setup/                     # One-shot dev env package (source)
│   │   ├── DEBIAN/control
│   │   ├── DEBIAN/postinst        # pkg install pe setup auto-run
│   │   └── data/data/com.termux/files/usr/
│   │       ├── bin/{setup,pbuild,build_project}
│   │       └── share/nandu-repo/  # restore.sh, package list, dev_env.sh, aapt2.real
│   └── nandu-welcome/             # Demo package (source)
├── debs/                          # Built .deb archives
└── repo/                          # Ye folder GitHub pe push hota hai
    ├── Packages / Packages.gz / Release
    ├── setup_1.2.1_all.deb
    └── nandu-welcome_1.0.0_all.deb
```

## Naya package add karna

1. Naya folder banao: `packages/<package-name>/DEBIAN/control` (Package, Version, Architecture fields ke saath)
2. Files rakho `data/data/com.termux/files/usr/...` ke andar (Termux prefix!)
3. `bash build-repo.sh` chalao — `.deb` build hogi aur index auto-update hoga
4. `repo/` folder ko GitHub pe push karo:
   ```bash
   git add -A && git commit -m "add <package>" && git push
   git push origin main:gh-pages
   ```

## Local test (bina GitHub ke)

```bash
printf 'deb [trusted=yes] file:///data/data/com.termux/files/home/nandu-repo/repo ./\n' > "$PREFIX/etc/apt/sources.list.d/nandu-repo.list"
apt-get update
pkg install nandu-welcome
```
