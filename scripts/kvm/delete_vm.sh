#!/bin/sh -e

HYPERVISOR=$1
TARGET_NAME=$2

usage() {
 	echo "$0 --hypervisor hypervisor --target target"
}

while [ ! -z "$1" ]; do
  case "$1" in
    -h|--hypervisor) HYPERVISOR=$2 ; shift 2 ;;
    -t|--target) TARGET_NAME=$2 ; shift 2 ;;
    *) usage ; exit 2 ;;
  esac
done

if [ -z "$HYPERVISOR" -o -z "$TARGET_NAME" ]; then
  usage
  exit 1
fi

echo "Using hypervisor $HYPERVISOR"
echo "Deleting $TARGET_NAME"

VIRSH="ssh $HYPERVISOR virsh --connect qemu:///system"
disks=`$VIRSH dumpxml $TARGET_NAME | grep "\\.qcow2" | perl -pe "s/^.*file='([^']+)'.*$/\\1/g"`

is_running=`$VIRSH dominfo $TARGET_NAME | egrep 'running|paused' || true`
if [ "$is_running" != "" ]; then
  $VIRSH destroy $TARGET_NAME
fi

$VIRSH undefine $TARGET_NAME

for i in $disks; do
  $VIRSH vol-delete --pool default `basename $i`
done

echo "Done."
