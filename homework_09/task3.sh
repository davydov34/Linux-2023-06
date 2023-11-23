#!/bin/bash

sed -i '/Environment=LANG=C/a EnvironmentFile=/etc/sysconfig/httpd-%I' \
        /usr/lib/systemd/system/httpd.service

cat >> /etc/sysconfig/httpd-first << EOF
OPTIONS=-f conf/first.conf
EOF

cat >> /etc/sysconfig/httpd-second << EOF
OPTIONS=-f conf/second.conf
EOF

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf

sed 's/Listen 80/PidFIle \/var\/run\/httpd-second.pid\nListen 8080/' \
    /etc/httpd/conf/httpd.conf > \
    /etc/httpd/conf/second.conf

systemctl start httpd@first
systemctl start httpd@second
 
