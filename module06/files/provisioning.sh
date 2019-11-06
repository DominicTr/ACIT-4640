#!/bin/bash

setup_firewall () {
    firewall-cmd --zone=public --add-service=ssh
	firewall-cmd --zone=public --add-service=http
	firewall-cmd --zone=public --add-service=https
	firewall-cmd --runtime-to-permanent
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
	sed -r -i 's/CHANGEME/acit4640/g' /home/todo-app/app/config/database.js
	chown -R todo-app /home/todo-app/app
    chmod a+rx /home/todo-app
}
production_setup () {

	mkdir /etc/nginx
	yum -y install nginx
	sudo cp /home/admin/nginx.conf /etc/nginx/nginx.conf --force
	systemctl enable nginx && systemctl start nginx
	sudo cp /home/admin/todoapp.service /lib/systemd/system
	systemctl daemon-reload
	systemctl enable todoapp
	systemctl start todoapp
}
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
setup_firewall
create_todo_app_user
application_setup
production_setup