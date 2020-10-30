#!/bin/sh
SOURCE_URL="https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-5.9.1.tar.gz"
CPUS="-j32 -l30"

echo "Downloading $(basename ${SOURCE_URL})..."
{
[ -f $(basename ${SOURCE_URL}) ] || wget -c ${SOURCE_URL}
} &> /dev/null

echo "Unpacking $(basename ${SOURCE_URL})..."
{
[ -d $(basename ${SOURCE_URL} .tar.gz) ] || tar -xzf $(basename ${SOURCE_URL})
} &> /dev/null

echo "Building $(basename ${SOURCE_URL} .tar.gz) for Raspberry Pi 4 (AArch64)..."
{
cp kernel-config $(basename ${SOURCE_URL} .tar.gz)/
cd $(basename ${SOURCE_URL} .tar.gz)
make ARCH=arm64 CROSS_COMPILE=$HOME/x-tools/aarch64-unknown-linux-gnu/bin/aarch64-unknown-linux-gnu- olddefconfig
make ARCH=arm64 CROSS_COMPILE=$HOME/x-tools/aarch64-unknown-linux-gnu/bin/aarch64-unknown-linux-gnu- ${CPUS}
} &> /dev/null

echo "Installing $(basename ${SOURCE_URL} .tar.gz) for Raspberry Pi 4 (AArch64)..."
{
mkdir ../boot
make ARCH=arm64 CROSS_COMPILE=$HOME/x-tools/aarch64-unknown-linux-gnu/bin/aarch64-unknown-linux-gnu- INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=.. modules_install
make ARCH=arm64 CROSS_COMPILE=$HOME/x-tools/aarch64-unknown-linux-gnu/bin/aarch64-unknown-linux-gnu- INSTALL_PATH=../boot install
} &> /dev/null
