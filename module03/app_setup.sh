#!/bin/bash

setup_user() {
    echo "Configuring system"
    adduser admin
    echo 'admin:$6$UZek30c6jszpAoQr$E8TlrDjEU9EFMPXROaSFryN9veV.OJeuZkYNL0M.x8Lrvv8temTgLSEBzG5ZGJPMQmHnUQgXk9KCpuC9jUi7r1' | chpasswd -e
    usermod -aG wheel admin
    sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers
    useradd -m -r todo-app && passwd -l todo-app
}
setup_system() {
    echo "Setting up system"
    mkdir ~admin/.ssh/
    chown -R admin:admin /home/admin/.ssh/
    curl https://acit4640.y.vu/docs/module02/resources/acit_admin_id_rsa.pub -o /home/admin/.ssh/authorized_keys.pub
    firewall-cmd --zone=public --add-service=http;
    firewall-cmd --zone=public --add-service=ssh;
    firewall-cmd --zone=public --add-service=https;
    firewall-cmd --runtime-to-permanent
    setenforce 0
    sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
}
install_packages () { 
    echo "Installing packages"
    yum -y install epel-release vim git tcpdump curl net-tools bzip2
    yum -y update
    yum -y install nodejs npm
    yum -y install mongodb-server
    yum -y install nginx
}
install_app () { 
    echo "Installing app";
    cd /home/todo-app/
    su - todo-app -c "mkdir app"
    su - todo-app -c "git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app/"
    cd app
    npm install
    cp -f /root/database.js /home/todo-app/app/config/database.js
    cp -f /root/nginx.conf /etc/nginx/nginx.conf
    cp -f /root/todoapp.service /lib/systemd/system/todoapp.service
}
startup_app () { 
    echo "Configuring app";
    systemctl enable mongod && systemctl start mongod
    systemctl enable nginx && systemctl start nginx
    systemctl daemon-reload
    systemctl enable todoapp && systemctl start todoapp
}

setup_user
setup_system
install_packages
install_app
startup_app

echo "DONE?"