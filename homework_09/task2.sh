#!/bin/bash

yum install -y epel-release && yum update
yum install -y spawn-fcgi php php-cli mod_fcgid httpd

sed 's/#SOCKET/SOCKET/g' /etc/sysconfig/spawn-fcgi > /etc/sysconfig/spawn-fcgi.tmp
sed 's/#OPTIONS/OPTIONS/g' /etc/sysconfig/spawn-fcgi.tmp > /etc/sysconfig/spawn-fcgi

cat >> /etc/systemd/system/spawn-fcgi.service << EOF
[Unit]
Description=Spawn-fcgi startup service by OTUS
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n \$OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

systemctl start spawn-fcgi.service