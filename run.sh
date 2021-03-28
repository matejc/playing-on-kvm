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

qemu-kvm \
    -vga none \
    -m 16G \
    -cpu host,kvm=off \
    -smp 12,sockets=1,cores=6,threads=2 \
    -machine type=q35,accel=kvm,kernel_irqchip=on \
    -device vfio-pci,host=01:00.0,multifunction=on,x-vga=on \
    -device vfio-pci,host=01:00.1 \
    -drive if=pflash,format=raw,readonly,file=ovmf-x64/OVMF_CODE-pure-efi.fd \
    -drive if=pflash,format=raw,file=ovmf-x64/OVMF_VARS-pure-efi.fd \
    -usb \
    -device usb-host,vendorid=0x05e3,productid=0x0610 \  # usb hub
    -device usb-host,vendorid=0x1d50,productid=0x6122 \  # keyboard
    -device usb-host,vendorid=0x214e,productid=0x0005 \  # mouse
    -device usb-host,vendorid=0x041e,productid=0x30d3 \  # usb sound card
    -netdev bridge,id=vmnic,br=br0 \
    -device virtio-net-pci,netdev=vmnic,mac=$macaddress \
    -monitor stdio \
    -device AC97 \
    -drive file=/dev/sda,format=raw,cache=none,aio=native,if=virtio,index=1 \
    -drive file=./windows.iso,media=cdrom,index=2 \
    -drive file=./virtio-win-0.1.185.iso,media=cdrom,index=3 \
    -drive file=/dev/sdb,format=raw,cache=none,aio=native,if=virtio,index=4

