#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Script: build-repo.sh  (Nandu Personal Termux Repo)
# Usage : bash build-repo.sh
# Builds every package in packages/* as .deb, copies to repo/, and regenerates
# the Packages / Packages.gz / Release apt index files.
# ==============================================================================

set -e
cd "$(dirname "$(readlink -f "$0")")"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

REPO_DIR="$PWD/repo"
DEBS_DIR="$PWD/debs"
PKGS_DIR="$PWD/packages"

rm -rf "$REPO_DIR"/*.deb
mkdir -p "$REPO_DIR" "$DEBS_DIR"

# ---- 1. Build each package ------------------------------------------------
for pkgdir in "$PKGS_DIR"/*/; do
    [ -d "$pkgdir" ] || continue
    field() { awk -v k="$1" '$0 ~ "^"k":" { sub(/^[^:]*: /, ""); print; exit }' "$pkgdir/DEBIAN/control"; }
    name=$(field Package)
    version=$(field Version)
    arch=$(field Architecture)
    deb="$DEBS_DIR/${name}_${version}_${arch}.deb"
    debname=$(basename "$deb")

    echo -e "${CYAN}==> Building ${name}_${version}_${arch}.deb ...${RESET}"
    find "$pkgdir" -exec chmod 755 {} + 2>/dev/null || true
    chmod 755 "$pkgdir/DEBIAN"
    chmod 755 "$pkgdir/DEBIAN"/*
    find "$pkgdir/data" -type f -exec chmod 755 {} + 2>/dev/null || true

    dpkg-deb -b "$pkgdir" "$deb"
    cp -f "$deb" "$REPO_DIR/$debname"
    echo -e "${GREEN}    -> $debname built${RESET}"
done

# ---- 2. Regenerate apt index ---------------------------------------------
echo -e "${CYAN}==> Generating Packages index ...${RESET}"
python3 - "$REPO_DIR" << 'EOF'
import os, sys, gzip, hashlib, glob
from datetime import datetime, timezone

repo = sys.argv[1]
blocks = []

for deb in sorted(glob.glob(os.path.join(repo, "*.deb"))):
    with open(deb, "rb") as f:
        content = f.read()
    size = len(content)
    md5 = hashlib.md5(content).hexdigest()
    sha1 = hashlib.sha1(content).hexdigest()
    sha256 = hashlib.sha256(content).hexdigest()

    meta = {}
    raw = os.popen(f"dpkg-deb -f {deb}").read()
    for line in raw.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            meta[k.strip()] = v.strip()

    order = ["Package", "Version", "Architecture", "Maintainer",
             "Installed-Size", "Depends", "Section", "Priority",
             "Homepage", "Description", "Filename", "Size",
             "MD5sum", "SHA1", "SHA256"]
    lines = [f"{k}: {meta[k]}" for k in order if k in meta and k not in
             ("Filename", "Size", "MD5sum", "SHA1", "SHA256")]
    lines += [f"Filename: ./{os.path.basename(deb)}",
              f"Size: {size}",
              f"MD5sum: {md5}",
              f"SHA1: {sha1}",
              f"SHA256: {sha256}"]
    blocks.append("\n".join(lines))

packages = "\n\n".join(blocks) + "\n\n"
with open(os.path.join(repo, "Packages"), "w") as f:
    f.write(packages)
with gzip.open(os.path.join(repo, "Packages.gz"), "wb") as f:
    f.write(packages.encode())

p_md5 = hashlib.md5(packages.encode()).hexdigest()
p_sha = hashlib.sha256(packages.encode()).hexdigest()
p_size = len(packages)
gz = open(os.path.join(repo, "Packages.gz"), "rb").read()
g_md5 = hashlib.md5(gz).hexdigest()
g_sha = hashlib.sha256(gz).hexdigest()
g_size = len(gz)

release = f"""Origin: nandu-repo
Label: Nandu Personal Repo
Suite: stable
Codename: stable
Date: {datetime.now(timezone.utc).strftime('%a, %d %b %Y %H:%M:%S UTC')}
Architectures: all aarch64
Components: main
Description: Nandu's personal Termux APT repository.
MD5Sum:
 {p_md5} {p_size} Packages
 {g_md5} {g_size} Packages.gz
SHA256:
 {p_sha} {p_size} Packages
 {g_sha} {g_size} Packages.gz
"""
with open(os.path.join(repo, "Release"), "w") as f:
    f.write(release)

print("Packages index written to", repo)
EOF

echo -e "${GREEN}======================================================${RESET}"
echo -e "${GREEN}✓ Repo ready! Contents of repo/:${RESET}"
ls -la "$REPO_DIR"
echo -e "${GREEN}======================================================${RESET}"
echo -e "Next: push the 'repo' folder to GitHub, then on any Termux run:"
echo -e "  pkg update && pkg install nandu-welcome"
