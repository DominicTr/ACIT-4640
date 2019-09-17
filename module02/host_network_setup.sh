#!/bin/bash

export PATH=/mnt/e/VirtualBox:$PATH
vbmg () { ./VBoxManage.exe "$@"; }


vbmg natnetwork add --netname net_4640 --dhcp off --ipv6 off --network 192.168.250.0/24 --enable \
    --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
    --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
    --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"

vbmg createvm --name VM_ACIT4640 --ostype RedHat_64 --register
vbmg modifyvm VM_ACIT4640 --cpus 1 --memory 1024 --nic1 natnetwork --nat-network1 net_4640 --audio none
VM_NAME="VM_ACIT4640"
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")
echo $VM_DIR


vbmg createmedium disk --filename "${VM_DIR}/VM-4640" --size 10000 --format VDI
vbmg storagectl VM_ACIT4640 --name SATA --add sata --portcount 2 --bootable on
vbmg storageattach VM_ACIT4640 --storagectl SATA --device 0 --port 0 --type hdd --medium "${VM_DIR}/VM-4640.vdi"
vbmg storagectl VM_ACIT4640 --name IDE --add ide
vbmg storageattach VM_ACIT4640 --storagectl IDE --device 0 --port 0 --type hdd --medium emptydrive