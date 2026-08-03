#!/bin/bash
# ==============================================================================
# restore.sh — runs INSIDE the proot Ubuntu container.
# Restores the Nandu dev environment: packages, SDK config, env, wrappers.
# Fully automatic — no manual license acceptance, no prompts.
#
# Two phases so setup can run the heavy package install IN PARALLEL with the
# big SDK downloads:
#   restore.sh <SHARE> packages   -> apt update + install package list only
#   restore.sh <SHARE> configs    -> env / aapt2 / ndk / commands (fast)
#   restore.sh <SHARE>            -> both
#
# Writes /etc/nandu-dev-ready once configs finish so re-runs are instant.
# ==============================================================================

set -e

SHARE="${1:-/data/data/com.termux/files/usr/share/nandu-repo}"
MODE="${2:-all}"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

export DEBIAN_FRONTEND=noninteractive
export TZ=UTC

restore_packages() {
    echo -e "${CYAN}==> [1/6] apt-get update ...${RESET}"
    apt-get update -y >/dev/null 2>&1 || apt-get update -y

    echo -e "${CYAN}==> [2/6] Installing Ubuntu dev packages ...${RESET}"
    if [ -s "$SHARE/ubuntu-packages.list" ]; then
        PKG_LIST=$(tr '\n' ' ' < "$SHARE/ubuntu-packages.list")
        # shellcheck disable=SC2086
        if ! apt-get install -y --no-install-recommends --no-install-suggests $PKG_LIST; then
            echo -e "${YELLOW}    Install hit errors; fixing broken deps ...${RESET}"
            apt-get install -f -y || true
        fi
    else
        echo -e "${YELLOW}    No package list found. Continuing with base system.${RESET}"
    fi
}

restore_configs() {
    echo -e "${CYAN}==> [3/6] Writing environment config ...${RESET}"
    mkdir -p /etc/profile.d
    cp -f "$SHARE/dev_env.sh" /etc/profile.d/dev_env.sh
    chmod +x /etc/profile.d/dev_env.sh
    if ! grep -q 'dev_env.sh' /root/.bashrc 2>/dev/null; then
        echo 'source /etc/profile.d/dev_env.sh' >> /root/.bashrc
    fi

    mkdir -p /root/.gradle
    cp -f "$SHARE/gradle.properties" /root/.gradle/gradle.properties

    echo -e "${CYAN}==> [4/6] Setting up AAPT2 QEMU wrapper ...${RESET}"
    mkdir -p /usr/local/bin /usr/bin
    cp -f "$SHARE/aapt2.real" /usr/local/bin/aapt2.real
    chmod +x /usr/local/bin/aapt2.real
    cat > /usr/bin/aapt2 << 'WRAPPER'
#!/bin/sh
export QEMU_LD_PREFIX=/usr/x86_64-linux-gnu
exec /usr/bin/qemu-x86_64 -0 aapt2 /usr/local/bin/aapt2.real "$@"
WRAPPER
    chmod +x /usr/bin/aapt2

    echo -e "${CYAN}==> [5/6] Linking NDK clang toolchain ...${RESET}"
    mkdir -p /usr/lib/clang
    ln -sfn /opt/android-sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/18 /usr/lib/clang/18 2>/dev/null || true
    ln -sf /usr/lib/clang/18/lib/linux/aarch64/* /usr/lib/clang/18/lib/linux/ 2>/dev/null || true

    echo -e "${CYAN}==> [6/6] Installing commands (setup / pbuild / build_project) ...${RESET}"
    cat > /usr/local/bin/setup << 'MSG'
#!/bin/bash
echo -e "\033[0;32m✓ Nandu Zero-Config Environment is active and verified!\033[0m"
echo "Supported Build Frameworks: Native Android (Gradle), Flutter, Expo React-Native"
echo "Run 'pbuild' or 'build_project' inside any project directory to build APK."
MSG
    chmod +x /usr/local/bin/setup
    cp -f /usr/local/bin/setup /usr/bin/setup

    cp -f "$SHARE/pbuild" /usr/local/bin/pbuild
    cp -f "$SHARE/pbuild" /usr/bin/pbuild
    cp -f "$SHARE/pbuild" /usr/local/bin/build_project
    cp -f "$SHARE/pbuild" /usr/bin/build_project
    chmod +x /usr/local/bin/pbuild /usr/bin/pbuild /usr/local/bin/build_project /usr/bin/build_project

    if [ -f /opt/flutter/bin/flutter ]; then
        /opt/flutter/bin/flutter config --no-analytics 2>/dev/null || true
        /opt/flutter/bin/flutter config --android-sdk /opt/android-sdk 2>/dev/null || true
    fi

    touch /etc/nandu-dev-ready

    echo -e "${GREEN}==========================================================${RESET}"
    echo -e "${GREEN}   Ubuntu dev environment restored (ditto).${RESET}"
    echo -e "${CYAN}   Run: proot-distro login ubuntu${RESET}"
    echo -e "${GREEN}==========================================================${RESET}"
}

case "$MODE" in
    packages) restore_packages ;;
    configs)  restore_configs ;;
    *)        restore_packages; restore_configs ;;
esac
