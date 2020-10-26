#!/bin/sh
KERNEL_BUILD="../rpi4-kernel"
KERNEL="${KERNEL_BUILD}/linux-5.9.1"
BUILD_ROOT="../aarch64-root/rootfs"
ROOT="rootfs"
IMAGE="rpi4-gentoo.img"

echo "Allocating ${IMAGE}..."
{
truncate -s 15G ${IMAGE}
} &> /dev/null

echo "Partitioning ${IMAGE}..."
{
gdisk $IMAGE <<EOF
o
y
n


+64M
ef00
n




w
y
EOF
partprobe
LOOP=$(losetup --show -f -P ${IMAGE})
mkfs.vfat ${LOOP}p1
mkfs.ext4 ${LOOP}p2
} &> /dev/null

echo "Mounting root partition..."
{
mkdir -p ${ROOT}
mount ${LOOP}p2 ${ROOT}
} &> /dev/null

echo "Installing rootfs..."
{
cp -ax ${BUILD_ROOT}/* ${ROOT}
} &> /dev/stdout

echo "Mounting EFI system partition..."
{
mkdir -p ${ROOT}/boot/efi
mount ${LOOP}p1 ${ROOT}/boot/efi
} &> /dev/null

echo "Downloading UEFI firmware..."
{
[ -f RPi4_UEFI_Firmware_v1.20.zip ] || wget https://github.com/pftf/RPi4/releases/download/v1.20/RPi4_UEFI_Firmware_v1.20.zip
} &> /dev/null

echo "Installing UEFI firmware..."
{
unzip RPi4_UEFI_Firmware_v1.20.zip -d ${ROOT}/boot/efi
cp RPI_EFI.fd ${ROOT}/boot/efi
} &> /dev/null

echo "Configuring hostname..."
{
echo "hostname=\"gentoo\"" > ${ROOT}/etc/conf.d/hostname
} &> /dev/null

echo "Generating fstab..."
{
cat <<EOF >>${ROOT}/etc/fstab
$(blkid -s UUID ${LOOP}p2 | cut -f2 -d' ') / btrfs noatime 0 1
$(blkid -s UUID ${LOOP}p1 | cut -f2 -d' ') /boot/efi vfat defaults 0 0
EOF
} &> /dev/null

echo "Preparing chroot..."
{
[[ "$(uname -m)" == "aarch64" ]] || ROOT=${ROOT} emerge --usepkgonly --oneshot --nodeps qemu
mount --rbind /dev ${ROOT}/dev
mount --make-rslave ${ROOT}/dev
mount -t proc /proc ${ROOT}/proc
mount --rbind /sys ${ROOT}/sys
mount --make-rslave ${ROOT}/sys
mount tmpfs ${ROOT}/tmp -t tmpfs -o size=1G
mount tmpfs ${ROOT}/var/tmp/portage -t tmpfs -o size=16G,uid=portage,gid=portage,mode=775,noatime,exec
mkdir -p ${ROOT}/usr/src/linux
mount --bind ${KERNEL} ${ROOT}/usr/src/linux
cp /etc/resolv.conf ${ROOT}/etc/resolv.conf
} &> /dev/null

echo "Updating eix database..."
{
chroot ${ROOT} /bin/bash --login -c eix-update
} &> /dev/null

echo "Configuring users..."
{
chroot ${ROOT} /bin/bash --login -c "useradd -mUG wheel gentoo"
sed -i -e "s,^root:[^:]\+:,root:$(openssl passwd -1 gentoo):," ${ROOT}/etc/shadow
sed -i -e "s,^gentoo:[^:]\+:,gentoo:$(openssl passwd -1 gentoo):," ${ROOT}/etc/shadow
} &> /dev/stdout

echo "Configuring services..."
{
chroot ${ROOT} /bin/bash --login -c "rc-update add dhcpcd default"
chroot ${ROOT} /bin/bash --login -c "rc-update add sshd default"
chroot ${ROOT} /bin/bash --login -c "rc-update add ntp-client default"
} &> /dev/null

echo "Installing GRUB..."
{
chroot ${ROOT} /bin/bash --login -c grub-install
mkdir -p ${ROOT}/boot/efi/EFI/boot
cp ${ROOT}/boot/efi/EFI/gentoo/grubaa64.efi ${ROOT}/boot/efi/EFI/boot/bootaa64.efi
} &> /dev/null

echo "Installing $(basename ${KERNEL})..."
{
cp -ax ${KERNEL_BUILD}/boot/* ${ROOT}/boot/
cp -ax ${KERNEL_BUILD}/lib/* ${ROOT}/lib/
} &> /dev/null

echo "Generating initramfs..."
{
chroot ${ROOT} /bin/bash --login -c "genkernel --install initramfs"
} &> /dev/stdout

echo "Configuring GRUB..."
{
chroot ${ROOT} /bin/bash --login -c "grub-mkconfig -o /boot/grub/grub.cfg"
} &> /dev/null

echo "Finalizing..."
{
sed -i '/^MAKEOPTS=/d' ${ROOT}/etc/portage/make.conf
sed -i '/^EMERGE_DEFAULT_OPTS=/d' ${ROOT}/etc/portage/make.conf
[[ "$(uname -m)" == "aarch64" ]] || RROOT=${ROOT} emerge -C qemu
rm ${ROOT}/etc/resolv.conf
} &> /dev/null

echo "Optimizing image..."
{
rm ${ROOT}/usr/src/linux
umount -R ${ROOT}
e2fsck -f ${LOOP}p2
resize2fs -M ${LOOP}p2
SECTORS=$(expr $(tune2fs -l ${LOOP}p2 | grep "Block count" | cut -f2 -d':' | tr -d ' ') \* $(tune2fs -l ${LOOP}p2 | grep "Block size" | cut -f2 -d':' | tr -d ' ') / 512)
losetup -d ${LOOP}
gdisk ${IMAGE} <<EOF
d
2
n


+${SECTORS}

w
y
EOF
partprobe
truncate -s $(expr $(expr $(sfdisk -l ${IMAGE} -o end | tail -n 1) + 34) \* 512) ${IMAGE}
gdisk ${IMAGE} <<EOF
r
d
w
y
EOF
} &> /dev/stdout
