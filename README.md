This is the buildroot starting point for the NXP LS1046A Reference Design Board.

---

This is just a filesystem we're exploring for using on the initial version of our custom router. While it does have the two main pillars of modern Linux networking (`iproute2` for the basics, and `FRRouting` for the advanced stuff), it doesn't come with any configuration or GUI. It's *just* a filesystem.

That said, we are exploring the possibility of a custom GUI so we will likely use this repository as a foundation for that.

---

It has three main components (configuration files for other tools):
- Cross-compiling toolchain (crosstool-ng)
- Linux kernel
- Buildroot board configuration

Before we start, we need make sure you have all the necessary build tools installed:

```console
$ sudo apt install build-essential git autoconf bison flex texinfo help2man gawk \
libtool-bin libncurses5-dev unzip libbpf-dev libmount-dev fdisk
```

Also, you need to create a directory which'll hold the final cross-compiling binaries:
(and yes, you need to name it exactly like this because the path is hardcoded into config)

```console
$ sudo mkdir -p /opt/x-tools
$ su chown user:user /opt/x-tools # Replace user with your username/group
```

Now that we have all the dependencies, install and configure crosstool-ng.
Run the following somewhere **outside** this directory, preferably next to it:

```console
$ git clone https://github.com/crosstool-ng/crosstool-ng
$ cd crosstool-ng/
$ git checkout crosstool-ng-1.26.0
$ ./bootstrap
$ ./configure --enable-local
$ make
```

We now have the crosstools installed but no toolchains yet. Time to fix that. In the `crosstool-ng`, run:

```console
$ DEFCONFIG=../mono_filesystem/configs/crosstool-ng-1.26.0_defconfig ./ct-ng defconfig
```

Note how we use the `DEFCONFIG` environment variable to point to the defconfig in this repo?
This will create a `.config` file in crosstool directory that it will then use to correctly build the toolchain for our board, by running the following command. This may take a while (10 min or so).

```console
$ ./ct-ng build
```

The result is now a toolchain dir `/opt/x-tools/aarch64-mono-linux-gnu` which can now be used by buildroot for compiling, well, everything for our board: bootloaders, kernel and packages.

### Using buildroot

To build our target rootfs, we first need to take the defconfig from this repository, turn it into `.config` inside buildroot and finally build it. Again, this may take a while, even up to 30 min!

First, navigate to a directory that's adjacent to where you cloned this one, then run:

```console
$ git clone https://github.com/buildroot/buildroot
$ cd buildroot
$ git checkout 2024.05
$ make BR2_EXTERNAL=/path/to/this/repo ls1046a-rdb_defconfig
$ make -j16 # replace 16 with the amount of CPU cores * 2
```

Everything you need is now located in `buildroot/output/images` - the easiest way to get started is to to try it in QEMU:

```console
$ sudo apt install uml-utilities bridge-utils

$ sudo qemu-system-aarch64 \
  -m 2048 \
  -cpu cortex-a72 \
  -M virt \
  -nographic \
  -kernel output/images/Image \
  -drive file=output/images/rootfs.ext2,if=virtio,format=raw \
  -append "rootwait root=/dev/vda net.ifnames=0 ip=dhcp" \
  -netdev bridge,id=eth0,br=br0 \
  -device virtio-net-pci,netdev=eth0,mac=de:ad:be:ef:12:34 \
  -netdev bridge,id=eth1,br=br0 \
  -device virtio-net-pci,netdev=eth1,mac=de:ad:be:ef:56:78
```

This image has two interfaces:
- `eth0`, which doesn't have an IP configured and is meant as the WAN
- `eth1`, which has a static IP of 10.0.10.1 and is meant as LAN and has DHCP server bound to it

### Using Docker
First, make sure to have docker installed. Then run the below build command to prep the environment. Then use the docker run command to get into a persistent build environment for buildroot. First runs will always take a long time, but subsequent builds will be faster.

```console
docker build -t mono-linux .
docker run --rm -it -v $PWD:/home/ubuntu/mono_filesystem mono-linux <command>
```

**TODO:** Make the interfaces more freely configurable

If you have the LS1046A-RDB (or any other arm64 board should work, but we haven't tested any, yet), you can test this filesystem by mounting it through NFS; First, create a directory that you'll share with the network (modify IP and directory name as needed).

Also, we'll need both the Image file and the device tree, so make sure to create a tftp server (in `/srv/tftp` for consistency, but feel free to put it elsewhere and set up a simple TFTP server, which is out of scope of this guide).

```console
$ sudo mk -p /srv/nfs/buildroot
$ echo "/srv/nfs/buildroot 10.0.0.0/24(rw,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
$ sudo exportfs -ra
$ sudo tar -xavf output/images/rootfs.tar -C /srv/nfs/buildroot # uncompress rootfs into NFS dir
$ cp output/images/Image /srv/tftp
$ cp output/images/fsl-ls1046a-rdb-sdk.dtb /srv/tftp
```

Your network filesystem is now ready to be mounted into a physical board. In u-boot, stop the autoboot and run the following:

```console
=> setenv serverip 10.0.0.11 # Wherever your NFS and TFTP server is
=> dhcp
=> setenv bootargs "console=ttyS0,115200 earlycon=uart8250,mmio,0x21c0500 root=/dev/nfs ip=10.0.0.11::10.0.0.1:255.255.255.0::eth5:off nfsroot=10.0.0.71:/srv/nfs/buildroot,nfsvers=3,tcp rw"
=> tftp 0xc0000000 Image; tftp 0xa0000000 fsl-ls1046a-rdb-sdk.dtb
=> booti 0xc0000000 - 0xa0000000
```

Short explanation: First, we're setting the IP of the server with the kernel and device tree files, followed by the `dhcp` command which lets u-boot ask for an IP address. Once it receives it, we run the kernel arguments that'll make it load from the network rather than any local medium (SD card or an eMMC drive). with *bootargs* prepared, we can now load the kernel and device tree into memory and finally boot the device using the two. The minus sign tells u-boot we don't have any *initramfs*.

### Updating the components

If you update any component (with `$ make menuconfig`) and you want the change to be permanent (as in, part of this repository), then you need to make a defconfig file and save it in place of the one you've updated.

For linux kernel there is no need to add any paths as they are already build into the configuration:

```console
$ make linux-update-defconfig
```

For buildroot configuration, the same approach, because it remembered where the locations is by storing `BR2_EXTERNAL` which we used to *seed* from:

```console
$ make savedefconfig
```

Finally, for crosstool, you *will* have to provide it with the path to where the defconfig file is:

```console
$ DEFCONFIG=/path/to/this/repo/configs/crosstool-ng-1.26.0_defconfig ./ct-ng savedefconfig
```

