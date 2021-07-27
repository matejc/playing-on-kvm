#!/usr/bin/env bash
# This script dynamically manages allocated hugepages size depending on running libvirt VMs.
# Based on Thomas Lindroth's shell script which sets up host for VM: http://sprunge.us/JUfS
# put this script to /etc/libvirt/hooks/qemu

TOTAL_CORES='0-11'
TOTAL_CORES_MASK=FFF            # 0-11, bitmask 0b111111111111
HOST_CORES='5,11'            # Cores reserved for host
HOST_CORES_MASK=C3              # 0-1,6-7, bitmask 0b000011000011
VIRT_CORES='0-4,6-10'           # Cores reserved for virtual machine(s)

VM_NAME=$1

shield_vm() {
    cset set -c $TOTAL_CORES -s machine.slice
    # Shield two cores cores for host and rest for VM(s)
    cset shield --kthread on --cpu $VIRT_CORES
}

unshield_vm() {
    echo $TOTAL_CORES_MASK > /sys/bus/workqueue/devices/writeback/cpumask
    cset shield --reset
}

# For manual invocation
if [[ $VM_NAME == 'shield' ]];
then
    shield_vm
    exit 0
elif [[ $VM_NAME == 'unshield' ]];
then
    unshield_vm
    exit 0
fi
