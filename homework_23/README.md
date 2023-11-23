# Задание к уроку 23 - Linux PAM

## Задача:
- Запретить всем пользователям, кроме группы "admin" лоигн в выходные (суббота и воскресенье), без учёта праздников.

## Реализация задачи:
1. Создание пользователей "otusadm" и "otus":
> [root@pam ~]# useradd otusadm  
> [root@pam ~]# useradd otus

2. Задаем пользователям пароли:
> [root@pam ~]# echo "Otus2023!" | passwd --stdin otusadm  
Changing password for user otusadm.  
passwd: all authentication tokens updated successfully.  
[root@pam ~]# echo "Otus2023!" | passwd --stdin otus  
Changing password for user otus.
passwd: all authentication tokens updated successfully.

3. Создаём группу admin:
> [root@pam ~]# groupadd -f admin

4. Пользователей root, vagrant и otusadmin включаем в группу admin:
> [root@pam ~]# usermod root -a -G admin  
[root@pam ~]# usermod vagrant -a -G admin  
[root@pam ~]# usermod otusadm -a -G admin

5. Проверям возможность подключения по SSH:
>[root@pam ~]# ssh otus@192.168.57.10  
The authenticity of host '192.168.57.10 (192.168.57.10)' can't be established.
ECDSA key fingerprint is SHA256:8SyYq+W3Trs3pFNqqf+0753uQFehtwHaXGulU8k2oD8.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes  
otus@192.168.57.10's password:   
Last failed login: Sat Sep 23 18:54:00 UTC 2023 from 192.168.57.10 on ssh:notty  
There was 1 failed login attempt since the last successful login.  
[otus@pam ~]$ whoami  
otus  
[otus@pam ~]$ exit  
logout  
Connection to 192.168.57.10 closed.   
[otus@pam ~]$    
[root@pam ~]# ssh otusadm@192.168.57.10  
otusadm@192.168.57.10's password:   
Last failed login: Sat Sep 23 18:56:13 UTC 2023 from 192.168.57.10 on ssh:notty  
There was 1 failed login attempt since the last successful login.

6. Проверяем наличие пользователей в группе admin:
> [otusadm@pam ~]$ cat /etc/group | grep admin  
printadmin: x:996:  
admin: x:1003:root,vagrant,otusadm

7. Создаем файл скрипта login.sh и размещаем его в директории /usr/local/bin/, который имеет следующее содержание:
```bash
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
``````

8. Добавляем права на исполнение:
> [root@pam ~]# chmod +x /usr/local/bin/login.sh  
[root@pam ~]# ls -l /usr/local/bin/login.sh  
-rwxr-xr-x. 1 root root 203 Sep 23 19:15 /usr/local/bin/login.sh

9. Вносим изменение в файл /etc/pam.d/sshd, добавив скрипт login.sh через модуль pam_exec:
```
#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
account    required     pam_exec.so /usr/local/bin/login.sh
account    required     pam_sepermit.so
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_motd.so
session    include      password-auth
session    include      postlogin
```

10. На момент завершения выполнения задания 24.09.2023 (воскресенье), проверим возможность подключения по SSH под двумя пользователями, otus и otus adm.

> davydov@davydov-UBUNTU:\/\$ ssh otus@192.168.57.10  
> otus@192.168.57.10's password:  
> /usr/local/bin/login.sh failed: exit code 1  
> Connection closed by 192.168.57.10 port 22  
> davydov@davydov-UBUNTU:\/\$  
> davydov@davydov-UBUNTU:\/\$ ssh otusadm@192.168.57.10  
> otusadm@192.168.57.10's password:  
> Last login: Sun Sep 24 06:35:13 2023 from 192.168.57.1
> [otusadm@pam ~]$  

- **Задача успешно выполнена. Вход для пользователя otus вы выходной день невозможен, в это же время otusadm вход в систему остаётся доступен.**

---
Дополнительная проверка возможности подключения по SSH для пользователя "otus" в будние дни:

Изменим дату в системе:
> davydov@davydov-UBUNTU:\/\$ ssh root@192.168.57.10  
root@192.168.57.10's password:  
Last failed login: Sat Sep 23 19:56:11 UTC 2023 from 192.168.57.1 on ssh:notty  
There was 1 failed login attempt since the last successful login.  
[root@pam ~]# sudo date --set "2023-09-25 09:55:30"  
Mon Sep 25 09:55:30 UTC 2023  
[root@pam ~]# date  
Mon Sep 25 09:55:33 UTC 2023  
[root@pam ~]#  

Попробуем выполнить вход:
> davydov@davydov-UBUNTU:\~\/Vagrant23\$ ssh otus@192.168.57.10  
otus@192.168.57.10's password:  
Last failed login: Sun Sep 24 06:42:15 UTC 2023 from 192.168.57.1 on ssh:notty  
There were 2 failed login attempts since the last successful login.  
Last login: Sun Sep 24 06:29:07 2023  
[otus@pam ~]$  
___
