#!/bin/sh
ROOT="/tmp/rpi4-eeprom"
IMAGE="/tmp/rpi4-eeprom.img"
FIRMWARE_URL="https://github.com/raspberrypi/rpi-eeprom/releases/download/v2020.09.03-138a1/rpi-boot-eeprom-recovery-2020-09-03-vl805-000138a1.zip"

echo "Allocating ${IMAGE}..."
{
truncate -s 64M ${IMAGE}
} &> /dev/null

echo "Creating partitions..."
{
fdisk ${IMAGE} <<EOF
o
n




t
c
w
EOF
LOOP=$(losetup --show -f -P ${IMAGE})
mkfs.vfat ${LOOP}p1
} &> /dev/null

echo "Mounting partitions..."
{
mkdir -p ${ROOT}
mount ${LOOP}p1 ${ROOT}
} &> /dev/null

echo "Downloading firmware..."
{
wget ${FIRMWARE_URL}
} &> /dev/null

echo "Extracting firmware..."
{
unzip $(basename ${FIRMWARE_URL}) -d ${ROOT}
} &> /dev/null

echo "Finalizing image..."
{
umount ${ROOT}
losetup -d ${LOOP}
mv ${IMAGE} $(basename ${IMAGE})
} &> /dev/null
