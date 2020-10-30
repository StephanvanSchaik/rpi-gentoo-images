# Introduction

This repository contains minimal Gentoo images for the Raspberry Pi 3 and 4 targeting AArch64 (also known as ARM64) and ship UEFI for the [Raspberry Pi 3](https://github.com/pftf/RPi3/) and [Raspberry Pi 4](https://github.com/pftf/RPi4) together with GRUB 2, Linux mainline (5.9.1 as of writing) and a Gentoo stage3 userspace with some extras: dhcpcd, wpa\_supplicant, ntp-client, OpenSSH and basic filesystem utilities.

# Raspberry Pi 3

You can simply download the [latest release](https://github.com/StephanvanSchaik/rpi-gentoo-images/releases) of the `rpi3-gentoo.img.bz2` image and write it to either a USB drive or MicroSD card:

```
wget https://github.com/StephanvanSchaik/rpi-gentoo-images/releases/download/2020-10-25/rpi3-gentoo.img.bz2
bzip -d rpi3-gentoo.img.bz2
dd if=rpi3-gentoo.img of=/dev/sda
```

Boot up your Raspberry Pi 3 with the USB drive or MicroSD card inserted. It should first show the colorful Raspberry Pi 3 screen followed by the actual Raspberry Pi logo for UEFI. Then it should boot into GRUB and finally Gentoo Linux.

# Raspberry Pi 4

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

# Post-installation

Once you can boot into the Gentoo system, you can simply log in using `gentoo` as both the username and password. This is also the password for the `root` account. In addition, the system is also accessible through `ssh`.

To grow the partition to span the full disk, run the following as root:

```
growpart /dev/sda 2
resize2fs /dev/sda2
```
