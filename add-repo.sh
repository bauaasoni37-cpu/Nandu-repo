#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Script: add-repo.sh — Add Nandu's Personal Termux Repo
# Usage : curl -fsSL https://raw.githubusercontent.com/bauaasoni37-cpu/nandu-repo/main/add-repo.sh | bash
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}==> Adding nandu-repo to Termux APT sources...${RESET}"

mkdir -p "$PREFIX/etc/apt/sources.list.d"
cat << 'EOF' > "$PREFIX/etc/apt/sources.list.d/nandu-repo.list"
deb [trusted=yes] https://raw.githubusercontent.com/bauaasoni37-cpu/nandu-repo/main/repo ./
EOF

echo -e "${CYAN}==> Updating package lists...${RESET}"
pkg update -y || apt-get update -y

echo -e "${GREEN}======================================================${RESET}"
echo -e "${GREEN}✓ nandu-repo added successfully!${RESET}"
echo -e "${CYAN}Install demo package:  pkg install nandu-welcome${RESET}"
echo -e "${CYAN}Run it:                nandu-welcome${RESET}"
echo -e "${GREEN}======================================================${RESET}"
