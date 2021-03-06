#!/bin/bash

# $1: scenario / ceph store type

set -o xtrace
set -o errexit

mkdir -p /opt/data/kolla

if [ $1 = 'cinder-lvm' ] || [ $1 = 'zun' ]; then
    # cinder-volumes volume group
    free_device=$(losetup -f)
    fallocate -l 5G /var/lib/cinder_data.img
    losetup $free_device /var/lib/cinder_data.img
    pvcreate $free_device
    vgcreate cinder-volumes $free_device
elif [ $1 = 'swift' ]; then
    # swift partition
    free_device=$(losetup -f)
    fallocate -l 5G /var/lib/swift_data.img
    losetup $free_device /var/lib/swift_data.img
    parted $free_device -s -- mklabel gpt mkpart KOLLA_SWIFT_DATA 1 -1
    free_partition=${free_device}p1
    mkfs.xfs -L d0 $free_partition
elif [ $1 = 'filestore' ]; then
    #setup devices for Kolla Ceph filestore OSD
    dd if=/dev/zero of=/opt/data/kolla/ceph-osd1.img bs=5M count=1000
    LOOP=$(losetup -f)
    losetup $LOOP /opt/data/kolla/ceph-osd1.img
    parted $LOOP -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_OSD1 1 -1

    dd if=/dev/zero of=/opt/data/kolla/ceph-journal1.img bs=5M count=512
    LOOP=$(losetup -f)
    losetup $LOOP /opt/data/kolla/ceph-journal1.img
    parted $LOOP -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_OSD1_J 1 -1
elif [ $1 = 'bluestore' ]; then
    # Setup devices for Kolla Ceph bluestore OSD
    dd if=/dev/zero of=/opt/data/kolla/ceph-osd0.img bs=5M count=100
    LOOP=$(losetup -f)
    losetup $LOOP /opt/data/kolla/ceph-osd0.img
    parted $LOOP -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS_OSD0 1 -1

    dd if=/dev/zero of=/opt/data/kolla/ceph-osd0-b.img bs=5M count=1000
    LOOP=$(losetup -f)
    losetup $LOOP /opt/data/kolla/ceph-osd0-b.img
    parted $LOOP -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS_OSD0_B 1 -1

    dd if=/dev/zero of=/opt/data/kolla/ceph-osd0-w.img bs=5M count=200
    LOOP=$(losetup -f)
    losetup $LOOP /opt/data/kolla/ceph-osd0-w.img
    parted $LOOP -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS_OSD0_W 1 -1

    dd if=/dev/zero of=/opt/data/kolla/ceph-osd0-d.img bs=5M count=200
    LOOP=$(losetup -f)
    losetup $LOOP /opt/data/kolla/ceph-osd0-d.img
    parted $LOOP -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS_OSD0_D 1 -1
else
    echo "Unknown type" >&2
    exit 1
fi

partprobe
