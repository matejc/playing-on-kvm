# Playing on Qemu/KVM

Playing games in the VM running Windows


## Initial configuration (NixOS)

Modify your `/etc/nixos/configuration.nix` to add this options:

    boot.kernelModules = [ "kvm-intel" ];
    boot.kernelParams = [
      "intel_iommu=on"
      "i915.enable_hd_vgaarb=1"
      "vfio_iommu_type1.allow_unsafe_interrupts=1"
      "kvm.allow_unsafe_assigned_interrupts=1"
      "kvm.ignore_msrs=1"
    ];
    boot.blacklistedKernelModules = [ "nvidiafb" "nouveau" ];
    virtualisation.libvirtd = {
      enable = true;
      qemuPackage = pkgs.qemu_kvm;
      allowedBridges = [ "virbr0" "br0" ];
    };
    services.gnome3.at-spi2-core.enable = true;

For other Linux distributions you can extract meaningful info from the upper snippet.


## Requirements

- Download `edk2.git-ovmf-x64-*` from https://www.kraxel.org/repos/jenkins/edk2/
- Download virtio-win ISO from https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md
- Download Windows ISO from https://www.microsoft.com/en-gb/software-download/windows10ISO


## Run the VM

Go through the options in `run.sh` and modify according to your hardware setup.

    $ sudo ./run.sh


## Extra

### Samba server

Meant for share between Linux host and Windows guest. Add it to your `configuration.nix`:

    services.samba = {
      enable = true;
      securityType = "user";
      extraConfig = ''
        workgroup = WORKGROUP
        server string = smbnix
        netbios name = smbnix
        hosts allow = 192.168.1.0/24 localhost
        hosts deny = 0.0.0.0/0
        guest account = nobody
        map to guest = bad user
        server role = standalone server
      '';
      shares = {
        private = {
          path = "/mnt/Shares/Private";
          public = "no";
          writable = "yes";
          printable = "no";
          "create mask" = "0765";
          "force user" = "matejc";
          "force group" = "users";
        };
      };
    };

