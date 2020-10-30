# Introduction

This repository contains minimal Gentoo images for the Raspberry Pi 3 and 4 targeting AArch64 (also known as ARM64) and ship UEFI for the [Raspberry Pi 3](https://github.com/pftf/RPi3/) and [Raspberry Pi 4](https://github.com/pftf/RPi4) together with GRUB 2, Linux mainline (5.9.1 as of writing) and a Gentoo stage3 userspace with some extras: dhcpcd, wpa\_supplicant, ntp-client, OpenSSH and basic filesystem utilities.

## Raspberry Pi 3

You can simply download the [latest release](https://github.com/StephanvanSchaik/rpi-gentoo-images/releases) of the `rpi3-gentoo.img.bz2` image and write it to either a USB drive or MicroSD card:

```
wget https://github.com/StephanvanSchaik/rpi-gentoo-images/releases/download/2020-10-25/rpi3-gentoo.img.bz2
bzip -d rpi3-gentoo.img.bz2
dd if=rpi3-gentoo.img of=/dev/sda
```

Boot up your Raspberry Pi 3 with the USB drive or MicroSD card inserted. It should first show the colorful Raspberry Pi 3 screen followed by the actual Raspberry Pi logo for UEFI. Then it should boot into GRUB and finally Gentoo Linux.

## Raspberry Pi 4

Make sure you have the latest EEPROM update installed to enable USB booting. If not, you can download the [latest release](https://github.com/StephanvanSchaik/rpi-gentoo-images/releases) of the `rpi4-eeprom.img.bz2` image and write it to a MicroSD card:

```
wget https://github.com/StephanvanSchaik/rpi-gentoo-images/releases/download/2020-10-25/rpi4-eeprom.img.bz2
bzip -d rpi4-eeprom.img.bz2
dd if=rpi4-eeprom.img of=/dev/sda
```

Boot up Raspberry Pi 4 with the MicroSD card inserted. If everything went well it should fill your screen with green and rapidly blink the LED. Power off the Raspberry Pi 4.

Now you can download the [latest release](https://github.com/StephanvanSchaik/rpi-gentoo-images/releases/download/2020-10-25/rpi4-gentoo.img.bz2) of the `rpi4-gentoo.img.bz2` image and write it to a USB drive:

**Note**: the Linux 5.9.1 kernel that is shipped as part of the image does not yet have support for the MicroSD slot or WiFi.

```
wget https://github.com/StephanvanSchaik/rpi-gentoo-images/releases/download/2020-10-25/rpi4-gentoo.img.bz2
bzip -d rpi4-gentoo.img.bz2
dd if=rpi4-gentoo.img of=/dev/sda
```

Boot up your Raspberry Pi 4 with the USB drive inserted. It should first show the colorful Raspberry Pi 4 screen followed by the actual Raspberry Pi logo for UEFI. Then it should boot into GRUB and finally Gentoo Linux.

## Post-installation

Once you can boot into the Gentoo system, you can simply log in using `gentoo` as both the username and password. This is also the password for the `root` account. In addition, the system is also accessible through `ssh`.

To grow the partition to span the full disk, run the following as root:

```
growpart /dev/sda 2
resize2fs /dev/sda2
```

# Building your own images

It is also possible to build your own images with the build scripts provided in this repository. These build instructions assume you are doing the build process on Gentoo, but it may also be possible to get this to work on other distributions.

## Setting up the cross-compiler

**Note**: if you want to build this on AArch64, you can simply ignore this step.

To get a cross-compiler, we simply use the [crosstool-ng](https://crosstool-ng.github.io/) tool. Get it through your package manager:

```
emerge ct-ng
```

You can then use the following command to list the available targets:

```
ct-ng list-samples
```

Since we want to target `aarch64-unknown-linux-gnu` for the Raspberry Pi 3 and 4, we can simply configure crosstool-ng with that target:

```
ct-ng aarch64-unknown-linux-gnu
```

Finally, tell crosstool-ng build and install the cross-compiler:

```
ct-ng build
```

## Setting up QEMU

**Note**: if you want to build this on AArch64, you can simply ignore this step.

In order to `chroot` into a root file system meant for AArch64, we will need QEMU with user emulation. For this to work we actually have to produce a static binary of QEMU with user emulation that we can install into our target file system before we can `chroot` into it. So let's first enable the flags needed to build a statically linked version:

```
cat /etc/portage/package.use <<EOF
app-emulation/qemu static-user
dev-libs/glib static-libs
sys-libs/zlib static-libs
sys-apps/attr static-libs
dev-libs/libpcre static-libs
EOF
```

Then in `/etc/portage/make.conf`, make sure you have `aarch64` set for `QEMU_SOFTMMU_TARGETS` and `QEMU_USER_TARGETS` as follows:

```
QEMU_SOFTMMU_TARGETS="aarch64"
QEMU_USER_TARGETS="aarch64"
```

Now we can install QEMU:

```
emerge -av app-emulation/qemu
```

Then let's package up a binary package of QEMU:

```
quickpkg app-emulation/qemu
```

Now that we have QEMU packaged up, another component that we have to set up is `binfmt_misc`, which will allow us to register new executable handlers, in our case to have the kernel recognize AArch64 ELF files and execute them with QEMU automatically. Make sure your kernel has support for `CONFIG_BINFMT_MISC`:

```
zgrep CONFIG_BINFMT_MISC /proc/config.gz
```

Mount the `binfmt_misc` handler:

```
[ -d /proc/sys/fs/binfmt_misc ] || modprobe binfmt_misc
[ -f /proc/sys/fs/binfmt_misc/register ] || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
```

Then we can register a handler for AArch64 ELF files:

```
echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-aarch64:' > /proc/sys/fs/binfmt_misc/register
```

Finally, make sure that the `qemu-binfmt` service is up and running:

```
/etc/init.d/qemu-binfmt start
rc-update add qemu-binfmt
```

## Raspberry Pi 3

Build the kernel as follows:

```
pushd aarch64-kernel
./build.sh
popd
```

Build the rootfs as follows (as root):

```
pushd aarch64-root
./build.sh
popd
```

Then build the image as follows (as root):

```
pushd rpi3-image
./build.sh
popd
```

If everything went well, you should now have `rpi3-gentoo.img`.

## Raspberry Pi 4

Build the kernel as follows:

```
pushd rpi4-kernel
./build.sh
popd
```

Build the rootfs as follows (as root):

```
pushd aarch64-root
./build.sh
popd
```

Then build the image as follows (as root):

```
pushd rpi4-image
./build.sh
popd
```

If everything went well, you should now have `rpi4-gentoo.img`.

## Raspberry Pi 4 (EEPROM)

To build the EEPROM image:

```
pushd rpi4-eeprom
./build.sh
popd
```
