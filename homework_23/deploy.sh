#!/bin/bash

yum install -y update
yum install -y vim

useradd otusadm
useradd otus

echo "Otus2023!" | passwd --stdin otusadm
echo "Otus2023!" | passwd --stdin otus

groupadd -f admin

usermod root -a -G admin
usermod vagrant -a -G admin
usermod otusadm -a -G admin

cat >> /usr/local/bin/login.sh << \EOF
#!/bin/bash 

  if [ $(date +%A) = "Saturday" ] || [ $(date +%A) = "Sunday" ]; then

        if getent group admin | grep -qw "$PAM_USER" ; then
		echo "IF - Exit 0"
                exit 0
            else
		echo "IF-ELSE - Exit 1"
                exit 1
            fi
  else
    echo "END IF = Exit 0"
    exit 0
  fi
EOF

chmod +x /usr/local/bin/login.sh

sed -i "4i account    required     pam_exec.so /usr/local/bin/login.sh" /etc/pam.d/sshd