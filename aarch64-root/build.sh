#!/bin/sh
ROOT="rootfs"
MAKEOPTS="-j32 -l30"
EMERGE_OPTS="-j32 -l30"

echo "Downloading and unpacking stage3 tarball..."
{
mkdir -p ${ROOT}
wget -O - http://distfiles.gentoo.org/releases/arm64/autobuilds/$(wget -O - http://distfiles.gentoo.org/releases/arm64/autobuilds/latest-stage3-arm64.txt 2>/dev/zero | tail -n1 | cut -f1 -d' ') | tar xJp -C ${ROOT}
} &> /dev/null

echo "Updating /etc/portage/make.conf..."
cat <<EOF >>${ROOT}/etc/portage/make.conf
USE="bindist"
FEATURES="buildpkg -pid-sandbox -network-sandbox"
GRUB_PLATFORMS="efi-32 efi-64"
MAKEOPTS="$MAKEOPTS"
EMERGE_DEFAULT_OPTS="$EMERGE_OPTS"
EOF

echo "Preparing chroot..."
{
[[ "$(uname -m)" == "aarch64" ]] || ROOT=${ROOT} emerge --usepkgonly --oneshot --nodeps qemu
mount --rbind /dev ${ROOT}/dev
mount --make-rslave ${ROOT}/dev
mount -t proc /proc ${ROOT}/proc
mount --rbind /sys ${ROOT}/sys
mount --make-rslave ${ROOT}/sys
mount --bind /usr/portage ${ROOT}/usr/portage
mount tmpfs ${ROOT}/tmp -t tmpfs -o size=1G
mount tmpfs ${ROOT}/var/tmp/portage -t tmpfs -o size=16G,uid=portage,gid=portage,mode=775,noatime,exec
cp /etc/resolv.conf ${ROOT}/etc/resolv.conf
} &> /dev/null

echo "Installing Portage..."
{
chroot ${ROOT} /bin/bash --login -c emerge-webrsync
} &> /dev/stdout

echo "Creating binary packages of @system..."
{
chroot ${ROOT} /bin/bash --login -c "quickpkg --include-config=y '*/*'"
} &> /dev/stdout

echo "Installing packages..."
{
echo "sys-kernel/linux-firmware linux-fw-redistributable no-source-code" >> ${ROOT}/etc/portage/package.license
chroot ${ROOT} /bin/bash --login -c "emerge vim eix grub linux-firmware dhcpcd wpa_supplicant ntp openssh growpart dosfstools btrfs-progs gptfdisk parted"
} &> /dev/stdout

echo "Finalizing..."
umount -R ${ROOT}/var/tmp/portage
umount -R ${ROOT}/tmp
umount -R ${ROOT}/usr/portage
umount -R ${ROOT}/sys
umount -R ${ROOT}/proc
umount -R ${ROOT}/dev
