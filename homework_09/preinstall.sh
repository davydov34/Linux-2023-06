#!/bin/bash

yum install -y update
yum install -y vim

sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld