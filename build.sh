#!/bin/sh
#
# Build latest stable ARM kernel for QEMU Raspberry Pi 3 Emulation
#
#######################################################
set -x

git config --global --add safe.directory /workspace

MODEL=rpi_3
REMOTE=https://www.kernel.org
TOOLCHAIN=aarch64-linux-gnu
COMMIT=$(curl -s "$REMOTE" | grep -A1 latest_link | tail -n1 | grep -E -o '>[^<]+' | grep -E -o '[^>]+')
VERSION=$(echo "$COMMIT" | cut -d'-' -f2 | cut -d'.' -f1)

export ARCH=arm64
export CROSS_COMPILE=${TOOLCHAIN}-

curl -L -O -C - "https://cdn.kernel.org/pub/linux/kernel/v$VERSION.x/linux-$COMMIT.tar.xz" || exit 1

# Kernel Compilation
if [ ! -d "linux-$COMMIT" ]; then
	tar xf "linux-$COMMIT.tar.xz"
fi

cd "linux-$COMMIT" || exit 1

KERNEL_VERSION=$(make kernelversion)
KERNEL_TARGET_FILE_NAME=../qemu_kernel_$MODEL-$KERNEL_VERSION
echo "Building Qemu Raspberry Pi kernel qemu-kernel-$KERNEL_VERSION"

# Config
cp arch/arm/configs/vexpress_defconfig arch/arm64/configs
make -j 4 -k CC="ccache ${TOOLCHAIN}-gcc" vexpress_defconfig
scripts/kconfig/merge_config.sh .config ../config

# Compiling
#make CC="ccache ${TOOLCHAIN}-gcc" ARCH=arm64 CROSS_COMPILE=${TOOLCHAIN}- xconfig
make -j 4 -k CC="ccache ${TOOLCHAIN}-gcc" Image

cat arch/arm64/boot/dts/arm/vexpress-v2f-1xv7-ca53x2.dtb >>arch/arm64/boot/Image
cp arch/arm64/boot/Image "$KERNEL_TARGET_FILE_NAME"
