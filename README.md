# Nandu Personal Termux Repo (nandu-repo)

Nandu ka personal Termux APT repository. Is repo se `pkg install` kar ke packages install kar sakte ho.

## Quick install (after pushing to GitHub)

```bash
curl -fsSL https://raw.githubusercontent.com/bauaasoni37-cpu/Nandu-repo/main/add-repo.sh | bash
pkg install nandu-welcome
nandu-welcome
```

## Demo package

| Package        | Description                              |
|----------------|------------------------------------------|
| `nandu-welcome` | Welcome demo package (prints message)     |

## Repo structure

```
nandu-repo/
├── add-repo.sh                    # Termux me repo add karne wali script
├── build-repo.sh                  # Packages build + index regenerate script
├── packages/
│   └── nandu-welcome/             # Har package ka source dir
│       ├── DEBIAN/
│       │   ├── control            # Package metadata
│       │   └── postinst           # Install hone par chalne wala script
│       └── data/data/com.termux/files/usr/bin/nandu-welcome
├── debs/                          # Built .deb archives
└── repo/                          # Ye folder GitHub pe push karna hai
    ├── Packages                   # apt index (auto-generated)
    ├── Packages.gz
    ├── Release
    └── nandu-welcome_1.0.0_all.deb
```

## Naya package add karna

1. Naya folder banao: `packages/<package-name>/DEBIAN/control` (Package, Version, Architecture fields ke saath)
2. Files rakho `data/data/com.termux/files/usr/...` ke andar (Termux prefix!)
3. `bash build-repo.sh` chalao — `.deb` build hogi aur index auto-update hoga
4. `repo/` folder ko GitHub pe push karo

## GitHub pe host karna

1. GitHub pe naya repo banao: `nandu-repo`
2. Local `repo/` folder ka content (Packages, Packages.gz, Release, .deb files) usme `repo/` folder me push karo
3. `add-repo.sh` ko bhi repo ke root me rakh do
4. Kisi bhi Termux me:
   ```bash
   pkg update
   pkg install nandu-welcome
   ```

> Note: `deb [trusted=yes]` used hai, isliye GPG signing ki zaroorat nahi. Personal/trusted use ke liye theek hai.

## Local test (bina GitHub ke)

```bash
printf 'deb [trusted=yes] file:///data/data/com.termux/files/home/nandu-repo/repo ./\n' > "$PREFIX/etc/apt/sources.list.d/nandu-repo.list"
apt-get update
pkg install nandu-welcome
```
