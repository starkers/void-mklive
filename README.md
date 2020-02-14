## The Void Linux image/live/rootfs maker and installer

This repository contains utilities for Void Linux:

 * installer (The Void Linux el-cheapo installer for x86)
 * mklive    (The Void Linux live image maker for x86)

 * mkimage   (The Void Linux image maker for ARM platforms)
 * mkplatformfs (The Void Linux filesystem tool to produce a rootfs for a particular platform)
 * mkrootfs  (The Void Linux rootfs maker for ARM platforms)
 * mknet (Script to generate netboot tarballs for Void)

#### Build Dependencies
 * make

#### Dependencies
 * Compression type for the initramfs image
   * liblz4 (for lz4, xz) (default)
 * xbps>=0.45
 * qemu-user-static binaries (for mkrootfs)

#### Usage

Type

    $ make

and then see the usage output:

    $ ./mklive.sh -h
    $ ./mkrootfs.sh -h
    $ ./mkimage.sh -h

#### Examples

Build a native live image with runit and keyboard set to 'fr':

    # ./mklive.sh -k fr

Build an i686 (on x86\_64) live image with some additional packages:

    # ./mklive.sh -a i686 -p 'vim rtorrent'

Build an x86\_64 musl live image with packages stored in a local repository:

    # ./mklive.sh -a x86_64-musl -r /path/to/host/binpkgs

See the usage output for more information :-)


These scripts are in flux, if you want to build a duplicate of a
production image, its not a bad idea to ping maldridge on IRC.  This
message will be removed when this readme is replaced with complete
documentation.



# Building in docker

assemble package.base with the packages to be installed.. (See: `build-x86-images.sh.in`)
The "builder" image will download and save those into a cached repo `/cache`

You can then build inside docker by mapping `./out/` dir to `/out` inside the container..

```
docker build -t builder . -f Dockerfile.builder
docker run --privileged=true -v `pwd -P`/out:/out -it builder ./mklive.sh -r /cache -a x86_64 -o /out/void-live-x86_64-20200214.iso -p dialog cryptsetup lvm2 mdadm grub-i386-efi grub-x86_64-efi
```
