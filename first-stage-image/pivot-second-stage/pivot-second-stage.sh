#!/bin/sh

### Panic at the disco, when there's an error.

set -e

### Some variables for use later, you can imagine much of this coming from some
### "metadata" system (or the kernel command line like dracut), though that
### feels [at times] at conflict with what would be desired from the second
### stage metadata pkg.

NFS_ROOT=/nfsroot
NEW_ROOT=/newroot

IMAGE_BRANCH=stable
IMAGE_VERSION=latest
IMAGE_NAME=squashfs.img

NFS_SERVER=10.0.0.4
NFS_PATH=/

### Fairly arbitrary, pick what you will

NFS_OPTS=ro,nolock,nfsvers=3,rsize=131072,wsize=131072,hard,tcp,port=0,timeo=10,retrans=2,intr

### These are some modules we'll need later, but inexhaustive. The more you
### initialize up front, the longer you'll stay in stage one.

MODULES="bnxt_en nfs nfsv3 nfsv4"

### No really, the amount of care and feeding you need to do from initrd is not
### to be underestimated. It's frankly amazing that all the different options
### for booting work at all.

echo we have more respect for dracut now

### We are about to load some kernel modules, this may make more devices appear
### which in turn may need more initialization. Spin up enough infrastructure
### to allow mdev to function so we can at _least_ make it through dhcpd.

mount -t tmpfs -o size=64k,mode=0755 tmpfs /dev
mkdir /dev/pts
mount -t devpts devpts /dev/pts
mount -t proc proc /proc
mount -t sysfs sysfs /sys
echo /sbin/mdev > /proc/sys/kernel/hotplug
/sbin/mdev -s

for m in ${MODULES}; do
  echo Loading module $m
  modprobe $m
done

### Fire off a oneshot DHCP renewal, who cares if it fails

echo DHCPing
/sbin/dhcpcd --nobackground -f /dhcpcd.conf -1

### Currently an odd bug on my platform of choice, results in MTU not being
### determined from DHCP, so we configure it manually.

### TODO XXX FIXME you almost certainly don't need this.
ip link set mtu 9000 dev eth0

### Given a fondness and nostalgia for LTSP, what if the second stage was
### hosted on NFS? Really though, this could be a local partition, or iSCSI
### or anything else your heart desires. The world is your oyster, and you can
### build containers!

mkdir -p ${NFS_ROOT} ${NEW_ROOT}
mount -o ${NFS_OPTS} ${NFS_SERVER}:${NFS_PATH} ${NFS_ROOT}
mount -v -t squashfs ${NFS_ROOT}/${IMAGE_BRANCH}/${IMAGE_VERSION}/${IMAGE_NAME} ${NEW_ROOT}

### switch_root _normally_ tries to move these things for us, that's nice and
### all, but LinuxKit's init would be happy to handle that for you too. Unount
### these so we don't surprise the second layer. In particular, when rc.init is
### fired from the busybox init, if it finds `/proc/self` it thinks it's
### already been containerized.

umount /proc
umount /sys
umount /dev/pts
umount /dev

### Use of switch_root here is desired instead of pivot_root, because there are
### fewer edge cases the caller needs to consider, *AND* it will call `rm -rf`
### on the stage-1 initrd freeing your precious memory.

echo GOODBYE CRUEL WORLD, moving on up!

exec /sbin/switch_root ${NEW_ROOT} /init

### You are entering the twilight zone
