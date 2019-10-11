#!/bin/bash

NET_NAME="net_4640"
VM_NAME="VM_ACIT4640"
PXE_VM="PXE_4640"

vbmg () { VBoxManage.exe "$@"; }
#DON'T FORGET TO CHANGE THIS LATER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
export PATH=/mnt/e/VirtualBox:$PATH


clean_all () {
	echo "Deleting old VM"
	vbmg natnetwork remove --netname "$NET_NAME"
	vbmg unregistervm "$VM_NAME" --delete
}




create_network () {
	echo "Creating nat_net"
	vbmg natnetwork add --netname "$NET_NAME" \
		--network 192.168.250.0/24 \
		--dhcp off \
		--enable \
		--port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
		--port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
		--port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
		--port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22"
}

create_vm () {
	echo "Creating VM"
	vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
	vbmg modifyvm "$VM_NAME" --memory 2600 --nic1 natnetwork \
		--cableconnected1 on \
		--nat-network1 "$NET_NAME" \
		--boot1 disk --boot2 net --boot3 none --boot4 none \
		--audio none

	SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
	VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
	VM_DIR=$(dirname "$VBOX_FILE")
	
	vbmg createmedium disk --filename "$VM_DIR"/"$VM_NAME".vdi \
		--format VDI \
		--size 10000

	vbmg storagectl "$VM_NAME" --name "Controller1" --add sata \
		--bootable on

	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--port 0 --device 0 \
		--type hdd \
		--medium "$VM_DIR"/"$VM_NAME".vdi

	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--type dvddrive --medium emptydrive \
		--port 1 --device 0
}
create_pxe() {
	echo "PXE server"
	vbmg startvm "$PXE_VM"

	while /bin/true; do
        ssh -i acit_admin_id_rsa -p 50222 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 2
        else
                break
        fi
	done
}

transfer_files(){
	echo "Transfering files"

	#If i don't ssh like this it will says ssh: connect to host 50222 port 22: Network unreachable
	ssh -i acit_admin_id_rsa -p 50222 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
            -q admin@localhost sudo chown admin /var/www/lighttpd
	scp -i acit_admin_id_rsa -P 50222 -r files/ admin@localhost:/var/www/lighttpd
	ssh -i acit_admin_id_rsa -p 50222 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
            -q admin@localhost "sudo mv /var/www/lighttpd/files/ks.cfg /var/www/lighttpd/ ; \
			sudo chown lighttpd /var/www/lighttpd ; \
			sudo chmod 755 /var/www/lighttpd/ks.cfg; \
			"
}

clean_all
create_network
create_vm
create_pxe
transfer_files

vbmg startvm "$VM_NAME"
