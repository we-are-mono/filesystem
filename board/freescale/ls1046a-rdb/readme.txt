**************
NXP LS1046A-rdb
**************

This file documents the Buildroot support for the LS1046A Freeway Board.

for more details about the board and the QorIQ Layerscape SoC, see the following pages:
  - https://www.nxp.com/design/design-center/software/qoriq-developer-resources/layerscape-ls1046a-reference-design-board:LS1046A-RDB
  - https://www.nxp.com/LS1046A-RDB

for the software NXP LSDK (Layerscape Software Development Kit), see
  - https://www.nxp.com/docs/en/user-guide/LSDKUG_Rev21.08.pdf

the components from NXP are:
  - rcw, LSDK 21.08
  - atf (fork), LSDK 21.08
  - uboot (fork), LSDK 21.08
  - qoriq-fm-ucode (blob), LSDK 21.08
  - linux (fork), LSDK 21.08

Build
=====

First, configure Buildroot for the LS1046A Reference Design Board:

  make ls1046a-rdb_defconfig

Build all components:

  make

You will find in output/images/ the following files:
  - bl2_sd.pbl
  - fip.bin
  - fsl_fman_ucode_ls1046_r1.0_106_4_18.bin
  - fsl_fman_ucode_ls1046_r1.0_108_4_9.bin
  - fsl-ls1046a-rdb.dtb
  - fsl-ls1046a-rdb-sdk.dtb
  - Image
  - PBL.bin
  - rootfs.ext2
  - rootfs.ext4
  - sdcard.img
  - u-boot.bin

Create a bootable SD card
=========================

To determine the device associated to the SD card have a look in the
/proc/partitions file:

  cat /proc/partitions

Buildroot prepares a bootable "sdcard.img" image in the output/images/
directory, ready to be dumped on a SD card. Launch the following
command as root:

  dd if=output/images/sdcard.img of=/dev/sdX

*** WARNING! This will destroy all the card content. Use with care! ***

For details about the medium image layout, see the definition in
board/freescale/ls1046a-rdb/genimage.cfg.

Boot the LS1046A-rdb board
=========================

To boot your newly created system:
- insert the SD card in the SD slot of the board;
- Configure the switches SW1[1:9] = 0_0100_0000 (select SD Card boot option)
- put a Micro-USB cable into UART1 Port and connect using a terminal emulator
  at 115200 bps, 8n1. Or remove the jumper on J72, connect a USB to TTL cable
  to J73, and connect using a terminal emualtor at 115200 bps, 8n1.
- power on the board.
