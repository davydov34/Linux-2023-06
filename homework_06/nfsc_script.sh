#!/bin/bash -eux
	
	yum install -y nfs-utils

	systemctl enable firewalld --now
	
	mkdir /nfs_share
	
	echo "192.168.50.10:/srv/share/ /nfs_share nfs vers=3,proto=udp defaults 0 0" >> /etc/fstab

	systemctl daemon-reload
	
	systemctl restart remote-fs.target

	mount | grep 192.168.50.10 > /nfs_share/output_mount_client
