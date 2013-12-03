#!/bin/bash -e

HYPERVISOR=$1
SRC_NAME=$2
TARGET_NAME=$3

VM_TYPE="pc-1.1"
BRIDGE="virbr0"

usage() {
  echo "$0 --hypervisor hypervisor --disk src_disk --target target [--type pc-1.1] [--bridge virbr0] [--dnsmasq-host dnsmasq-host]"
}

while [ ! -z "$1" ]; do
  case "$1" in
    -h|--hypervisor) HYPERVISOR=$2 ; shift 2 ;;
    -d|--disk) SRC_NAME=$2 ; shift 2 ;;
    -t|--target) TARGET_NAME=$2 ; shift 2 ;;
    --type) VM_TYPE=$2 ; shift 2 ;;
    --bridge) BRIDGE=$2 ; shift 2 ;;
    --dnsmasq-host) DNSMASQ_HOST=$2 ; shift 2;;
    *) usage ; exit 2 ;;
  esac
done

if [ -z "$HYPERVISOR" -o -z "$SRC_NAME" -o -z "$TARGET_NAME" ]; then
  usage
  exit 1
fi

if [ -z "$DNSMASQ_HOST" ]; then
  DNSMASQ_HOST="$HYPERVISOR"
fi

echo "Using hypervisor $HYPERVISOR"
echo "Cloning $SRC_NAME to $TARGET_NAME"

VIRSH="ssh $HYPERVISOR virsh --connect qemu:///system"
disk="${SRC_NAME}_vda.qcow2"

TARGET_DISK="${TARGET_NAME}_vda.qcow2"

LOCK_FILE="/tmp/lock_`basename $disk`"
while true; do
  if ssh $HYPERVISOR "[ ! -f $LOCK_FILE ] && touch $LOCK_FILE"; then
    break;
  fi
  echo "File $disk is locked (lock file : $LOCK_FILE)"
  sleep 5
done
echo "Cloning $disk to $TARGET_DISK"
$VIRSH vol-clone --pool default `basename $disk` $TARGET_DISK
ssh $HYPERVISOR "rm $LOCK_FILE"


DISK_PATH=$($VIRSH vol-dumpxml --pool default $TARGET_DISK | grep path | perl -pe 's/.*>(.*)<.*/\1/')

echo "Disk path $DISK_PATH"

cat <<EOF | ssh $HYPERVISOR "cat > /tmp/$TARGET_NAME.xml"

<domain type='kvm'>
  <name>$TARGET_NAME</name>
  <memory unit='MiB'>1024</memory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='$VM_TYPE'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/kvm</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$DISK_PATH'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='bridge'>
      <source bridge='$BRIDGE'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
    </video>
  </devices>
</domain>

EOF

$VIRSH define /tmp/$TARGET_NAME.xml
ssh $HYPERVISOR rm /tmp/$TARGET_NAME.xml

$VIRSH start $TARGET_NAME

echo "$TARGET_NAME started"

count=0
while true; do
  count=$((count + 1))
  if [ "$count" = "60" ]; then
    echo "Timeout"
    exit 12
  fi
  mac=$($VIRSH dumpxml $TARGET_NAME | grep mac | grep address | perl -pe "s/^.*address='([^']+)'.*$/\\1/g")
  if [ "$mac" = "" ]; then
    echo "Wait mac address $count"
    sleep 2
    continue
  fi

  ip=$(ssh $DNSMASQ_HOST cat /var/lib/misc/dnsmasq.leases | egrep "$mac" | awk '{print $3}')
  if [ "$ip" = "" ]; then
    echo "Wait ip for mac address : $mac $count on $DNSMASQ_HOST"
    sleep 2
    continue
  fi

  echo "MAC $mac"
  echo "IP $ip"

  echo "Done."

  break
done
