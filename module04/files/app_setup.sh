#!/bin/bash

create_account () {
	useradd -m admin
	echo "admin:P@ssw0rd" | chpasswd
	usermod -aG wheel admin

	cp files/sudoers /etc/sudoers
	chown root:root /etc/sudoers
	chmod 440 /etc/sudoers
}

setup_firewall () {
	firewall-cmd --zone=public --add-service=ssh
	firewall-cmd --zone=public --add-service=http
	firewall-cmd --zone=public --add-service=https
	firewall-cmd --runtime-to-permanent

}

install_packages () {
	echo "Update function"
	yum -y install epel-release vim git tcpdump curl net-tools bzip2 nginx
	yum -y update
}

create_todo_app_user () {
	useradd -m -r todo-app && passwd -l todo-app
	yum -y install nodejs npm
	yum -y install mongodb-server
	systemctl enable mongod && systemctl start mongod
}

application_setup () {
	mkdir -p /home/todo-app/app
	git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app
	cd /home/todo-app/app && npm install
	cp /root/files/database.js /home/todo-app/app/config/database.js
	chown -R todo-app /home/todo-app/app
}

production_setup () {
	chmod a+rx /home/todo-app
	mkdir /etc/nginx
	yum -y install nginx
	cp /root/files/nginx.conf /etc/nginx/nginx.conf
	systemctl enable nginx && systemctl start nginx
	cp /root/files/todoapp.service /lib/systemd/system
	systemctl daemon-reload
	systemctl enable todoapp
	systemctl start todoapp
}

create_account
setup_firewall
install_packages
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
create_todo_app_user
application_setup
production_setup
