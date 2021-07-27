#/usr/bin/env bash

macaddress="DE:AD:BE:EF:49:09"  # printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))

qemu-kvm \
    -vga qxl -device qxl \
    -m 20G \
    -cpu host,kvm=off,hv_time,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff,hv_vendor_id=01:00.0 \
    -smp 10,cores=5,threads=2   \
    -vcpu vcpunum=0,affinity=0  \
    -vcpu vcpunum=1,affinity=6  \
    -vcpu vcpunum=2,affinity=1  \
    -vcpu vcpunum=3,affinity=7  \
    -vcpu vcpunum=4,affinity=2  \
    -vcpu vcpunum=5,affinity=8  \
    -vcpu vcpunum=6,affinity=3  \
    -vcpu vcpunum=7,affinity=9  \
    -vcpu vcpunum=8,affinity=4  \
    -vcpu vcpunum=9,affinity=10 \
    -machine type=q35,accel=kvm,kernel_irqchip=on \
    -device vfio-pci,host=01:00.0,multifunction=on,x-vga=on \
    -device vfio-pci,host=01:00.1 \
    -drive if=pflash,format=raw,readonly,file=ovmf-x64/OVMF_CODE-pure-efi.fd \
    -drive if=pflash,format=raw,file=ovmf-x64/OVMF_VARS-pure-efi.fd \
    -usb \
    -device usb-host,vendorid=0x05e3,productid=0x0610 \
    -device usb-host,vendorid=0x1532,productid=0x0221 \
    -device usb-host,vendorid=0x214e,productid=0x0005 \
    -device usb-host,vendorid=0x041e,productid=0x30d3 \
    -netdev bridge,id=vmnic,br=br0 \
    -device virtio-net-pci,netdev=vmnic,mac=$macaddress \
    -monitor stdio \
    -device AC97 \
    -drive file=/dev/sda,format=raw,cache=none,aio=native,if=virtio,index=1 \
    -drive file=./windows.iso,media=cdrom,index=2 \
    -drive file=./virtio-win-0.1.185.iso,media=cdrom,index=3 \
    -drive file=/dev/sdb,format=raw,cache=none,aio=native,if=virtio,index=4


