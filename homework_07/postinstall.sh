#!/bin/bash

yum install -y update
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc vim
yum install -y openssl-devel zlib-devel pcre2-devel

cd ~
wget "https://nginx.org/packages/centos/7/SRPMS/nginx-1.24.0-1.el7.ngx.src.rpm"
wget "https://www.openssl.org/source/openssl-1.1.1v.tar.gz" --no-check-certificate
tar -xf  openssl-1.1.1v.tar.gz

#Сборка NGINX
rpm -i nginx-1.*
sed -e '/--with-ld-opt=..{WITH_LD_OPT}../ a --with-openssl=/root/openssl-1.1.1v \\' rpmbuild/SPECS/nginx.spec > ~/temp.spec && mv -f ~/temp.spec rpmbuild/SPECS/nginx.spec
yum-builddep rpmbuild/SPECS/nginx.spec
rpmbuild -bb rpmbuild/SPECS/nginx.spec

yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1*
systemctl enable nginx
systemctl start nginx

mkdir /usr/share/nginx/html/repo
cp rpmbuild/RPMS/x86_64/nginx-1* /usr/share/nginx/html/repo/

createrepo /usr/share/nginx/html/repo/
sed -e '/index..index.html.index.htm/ a autoindex on;' /etc/nginx/conf.d/default.conf > /etc/nginx/conf.d/default.conf.tmp && mv -f /etc/nginx/conf.d/default.conf.tmp /etc/nginx/conf.d/default.conf

nginx -s reload

cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

