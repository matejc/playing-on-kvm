#!/usr/bin/env bash

# unbind the driver from the PCI device and bind it to the vfio
#  you can find similar functions all over the internet
vfiobind() {
    dev="$1"
    vendor=$(cat /sys/bus/pci/devices/$dev/vendor)
    device=$(cat /sys/bus/pci/devices/$dev/device)
    if [ -e /sys/bus/pci/devices/$dev/driver ]; then
        echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
    fi
    echo $vendor $device | tee /sys/bus/pci/drivers/vfio-pci/remove_id || true
    echo $vendor $device | tee /sys/bus/pci/drivers/vfio-pci/new_id
}

# to see exactly what the script is doing and
#  terminate itself if command does not exit with 0
set -xe

modprobe vfio-pci

vfiobind 0000:01:00.0  # graphic card
vfiobind 0000:01:00.1  # graphic card audio
# the same goes for any other PCI device like: audio (even if you use built in - motherboard audio) or USB controller

export QEMU_AUDIO_DRV=alsa QEMU_AUDIO_TIMER_PERIOD=0 QEMU_PA_SAMPLES=128

for f in /proc/sys/net/bridge/bridge-nf-*; do echo 0 > $f; done
macaddress="DE:AD:BE:EF:49:09"  # printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))

#TOTAL_CORES='0-11'
#TOTAL_CORES_MASK=FFF            # 0-11, bitmask 0b111111111111
#HOST_CORES='4-5,10-11'            # Cores reserved for host
#HOST_CORES_MASK=C3              # 0-1,6-7, bitmask 0b000011000011
#VIRT_CORES='0-3,6-9'           # Cores reserved for virtual machine(s)

#cset set -c $TOTAL_CORES -s machine.slice
#cset shield --kthread on --cpu $VIRT_CORES

#cset shield --exec qemu-kvm -- \
qemu-kvm \
    -m 20G \
    -cpu host,hv_relaxed,hv_vapic,hv_time,hv_spinlocks=0x1fff \
    -smp 12,cores=6,threads=2 \
    -machine type=q35,accel=kvm,kernel_irqchip=on \
    -vga none \
    -device vfio-pci,host=01:00.0,multifunction=on,x-vga=on \
    -device vfio-pci,host=01:00.1 \
    -drive if=pflash,format=raw,readonly,file=ovmf-x64/OVMF_CODE-pure-efi.fd \
    -drive if=pflash,format=raw,file=ovmf-x64/OVMF_VARS-pure-efi.fd \
    -usb \
    -device usb-host,vendorid=0x05e3,productid=0x0610 \
    -device usb-host,vendorid=0x046d,productid=0xc330 \
    -device usb-host,vendorid=0x214e,productid=0x0005 \
    -device usb-host,vendorid=0x041e,productid=0x30d3 \
    -device usb-host,vendorid=0x046d,productid=0xc21f \
    -netdev bridge,id=vmnic,br=br0 \
    -device virtio-net-pci,netdev=vmnic,mac=$macaddress \
    -monitor stdio \
    -device AC97 \
    -drive file=/dev/sda,format=raw,cache=none,aio=native,if=virtio,index=1 \
    -drive file=./windows.iso,media=cdrom,index=2 \
    -drive file=./virtio-win-0.1.185.iso,media=cdrom,index=3 \
    -drive file=/dev/sdb,format=raw,cache=none,aio=native,if=virtio,index=4

#echo $TOTAL_CORES_MASK > /sys/bus/workqueue/devices/writeback/cpumask
#cset shield --reset

./disable-devices.sh
