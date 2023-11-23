# LESOTUS17
## 1. Запуск nginx на нестандартном порту тремя разными способами...

- 1.1.1 Проверяем состояние firewalld:
> [vagrant@selinux ~]$ systemctl status firewalld.service  
> ● firewalld.service - firewalld - dynamic firewall daemon  
>    Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)  
>     Active: inactive (dead)  
>       Docs: man:firewalld(1)  

- 1.1.2 Проверяем конфигурацию Nginx:
> [root@selinux ~]# nginx -t  
> nginx: the configuration file /etc/nginx/nginx.conf syntax is ok  
> nginx: configuration file /etc/nginx/nginx.conf test is successful

- 1.1.3 Проверяем режиv работы SELinux:
> [root@selinux ~]# getenforce  
> Enforcing

- 1.1.4 Анализируем лог audit.log при помощи audit2why:
> [root@selinux ~]# cat /var/log/audit/audit.log  | audit2why  
> type=AVC msg=audit(1694284351.294:881): avc:  denied  { name_bind } for  pid=3035 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0  
>  
> 	Was caused by:  
> 	The boolean nis_enabled was set incorrectly.  
> 	Description:  
> 	Allow nis to enabled  
>  
> 	Allow access by executing:  
> 	**#setsebool -P nis_enabled 1**

- 1.1.5 Включаем параметр nis_enabled и пробуем запустить сервис:
> [root@selinux ~]# setsebool -P nis_enabled on  
> [root@selinux ~]# systemctl start nginx  
> [root@selinux ~]# systemctl status nginx.service  
> ● nginx.service - The nginx HTTP and reverse proxy server  
>    Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)  
>    Active: active (running) since Sat 2023-09-09 18:57:03 UTC; 9s ago  
  Process: 3284 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)  
>   Process: 3282 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)  
>   Process: 3281 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)  
> >  Main PID: 3286 (nginx)  
>   
> CGroup: /system.slice/nginx.service  
>            ├─3286 nginx: master process /usr/sbin/nginx  
>            └─3288 nginx: worker process  
>  
> Sep 09 18:57:03 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...  
> Sep 09 18:57:03 selinux nginx[3282]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok  
> Sep 09 18:57:03 selinux nginx[3282]: nginx: configuration file /etc/nginx/nginx.conf test is successful  
> Sep 09 18:57:03 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.  

- Nginx успешно запущен. Возвращаем nis_enabled в состояние off и переходим ко второму способу.

- 1.2 Запуск NGINX посредством добавления нестандартного порта в уже имеющиеся типы:
- 1.2.1 Ищем порты, сопоставленные с http:
> [root@selinux ~]# semanage port -l | grep http  
> http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010  
> http_cache_port_t              udp      3130  
> http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000  
> pegasus_http_port_t            tcp      5988  
> pegasus_https_port_t           tcp      5989  

- 1.2.2 Добавляем порт 4881 к типу http_port_t:
> [root@selinux ~]# semanage port -a -t http_port_t -p tcp 4881  
> [root@selinux ~]# semanage port -l | grep http  
> http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010  
> http_cache_port_t              udp      3130  
> http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000  
> pegasus_http_port_t            tcp      5988  
> pegasus_https_port_t           tcp      5989

- 1.2.3 Выполняем запуск NGINX:
> [root@selinux ~]# systemctl start nginx  
> [root@selinux ~]# systemctl status nginx  
> ● nginx.service - The nginx HTTP and reverse proxy server  
>    Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)  
   Active: active (running) since Sat 2023-09-09 19:12:08 UTC; 5s ago  
>   Process: 3603 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)  
>   Process: 3601 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)  
>   Process: 3600 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)  
>  Main PID: 3605 (nginx)  
>    CGroup: /system.slice/nginx.service  
>            ├─3605 nginx: master process /usr/sbin/nginx  
>            └─3607 nginx: worker process  
>  
> Sep 09 19:12:08 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...  
> Sep 09 19:12:08 selinux nginx[3601]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok  
> Sep 09 19:12:08 selinux nginx[3601]: nginx: configuration file /etc/nginx/nginx.conf test is successful  
> Sep 09 19:12:08 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.


- NGINX запущен, страница открывается - удаляем порт из http_port_t, останавливаем сервис и переходим к третьему методу.

- 1.3 Разрешаем работу на порту 4881 с помощью формирования и установки модуля SELinux.
- 1.3.1 Пытаемся запустить сервис ещё раз и смотрим логи:
> [root@selinux ~]# grep nginx /var/log/audit/audit.log  
> type=AVC msg=audit(1694287338.793:1001): avc:  denied  { name_bind } for  pid=3788 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0   
> type=SYSCALL msg=audit(1694287338.793:1001): arch=c000003e syscall=49 success=no exit=-13 a0=7 a1=55d8f36d88c8 a2=1c a3=7ffee3a20934 items=0 ppid=1 pid=3788 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)  
> type=SERVICE_START msg=audit(1694287338.793:1002): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'  

- 1.3.2 С помощью утилиты audit2allow создаем модуль, разрешающий работу по порту 4881:
> root@selinux ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx  
> ******************** IMPORTANT ***********************  
> To make this policy package active, execute:  
>  
> semodule -i nginx.pp

- 1.3.3 Выполняем команду и запускаем NGINX
> [root@selinux ~]# semodule -i nginx.pp  
> [root@selinux ~]# systemctl start nginx  
> [root@selinux ~]# systemctl status nginx.service  
> ● nginx.service - The nginx HTTP and reverse proxy server  
>    Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)  
>    Active: active (running) since Sat 2023-09-09 19:31:36 UTC; 10s ago  
>   Process: 3954 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)  
>   Process: 3952 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)  
>   Process: 3951 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)  
>  Main PID: 3956 (nginx)  
>    CGroup: /system.slice/nginx.service  
>            ├─3956 nginx: master process /usr/sbin/nginx  
>            └─3958 nginx: worker process  
>  
> Sep 09 19:31:36 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...  
> Sep 09 19:31:36 selinux nginx[3952]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok  
> Sep 09 19:31:36 selinux nginx[3952]: nginx: configuration file /etc/nginx/nginx.conf test is successful  
> Sep 09 19:31:36 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.

- Сервис успешно запустился. Найдёт добавленный нами модуль среди множества остальных:
> [root@selinux ~]# semodule -l | grep nginx  
> nginx	1.0

- И удаляем его из системы:
> [root@selinux ~]# semodule -r nginx
> libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).

## 2. Обеспечение работоспособности при вклюенном SELinux.

- 2.1 Пытаемся внести изменения в зону DNS:
> [vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key  
> server 192.168.50.10  
> zone ddns.lab  
> update add www.ddns.lab. 60 A 192.168.50.15  
> send  
> update failed: SERVFAIL
 
- 2.2 Выполняем анализ лога утилитой audit2why:
> [root@client ~]# cat /var/log/audit/audit.log | audit2why  
> [root@client ~]#

В журнале клиентской машины ошибок нет... Выполняем ту же операцию на стороне сервера...
- 2.3 Анализируем лог на сервере:
> Last login: Sun Sep 10 08:23:05 2023 from 10.0.2.2  
> [vagrant@ns01 ~]$ sudo -i  
> [root@ns01 ~]# cat /var/log/audit/audit.log | audit2  
> audit2allow  audit2why  
> [root@ns01 ~]# cat /var/log/audit/audit.log | audit2why  
> type=AVC msg=audit(1694333762.168:759): avc:  denied  { create } for  pid=703 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" >scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0  
>  
>    Was caused by:  
>            Missing type enforcement (TE) allow rule.  
>  
>   		    You can use audit2allow to generate a loadable module to allow this access.  

- 2.4 Посмотрим на контекст безопасности в каталоге /etc/named/:
> [root@ns01 ~]# ls -alZ /etc/named  
> drw-rwx---. root named system_u:object_r:etc_t:s0       .  
> drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..  
> drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic  
> -rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev  
> -rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab  
> -rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1  
> -rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab

Видим контекст безопасности etc_t.
- 2.5 Смотрим, в каком каталоге должны лежать файлы:
> [root@ns01 ~]# semanage fcontext -l | grep named | head -n 2  
> /etc/rndc.*                                        regular file       system_u:object_r:named_conf_t:s0  
> /var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0 

- 2.6 Меняем тип контекста безопасности для /etc/named на named_zone_t:
> [root@ns01 ~]# chcon -R -t named_zone_t /etc/named  
> [root@ns01 ~]# ls -alZ /etc/named  
> drw-rwx---. root named system_u:object_r:named_zone_t:s0 .  
> drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..  
> drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic  
> -rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev  
> -rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab  
> -rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1  
> -rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab

- 2.7 Переходим на клиента и пробуем внести изменения:
> [root@client ~]# nsupdate -k /etc/named.zonetransfer.key  
> server 192.168.50.10  
> zone ddns.lab  
> update add www.ddns.lab. 60 A 192.168.50.15  
> send  
> quit

2.8 Выполняем запрос к DNS серверу:
> [root@client ~]# dig @192.168.50.10 www.ddns.lab  
>  
> ; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.14 <<>> @192.168.50.10 www.ddns.lab  
> ; (1 server found)  
> ;; global options: +cmd  
> ;; Got answer:  
> ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 44310  
> ;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2  
>  
> ;; OPT PSEUDOSECTION:  
> ; EDNS: version: 0, flags:; udp: 4096  
> ;; QUESTION SECTION:  
;www.ddns.lab.			IN	A  
>  
> ;; ANSWER SECTION:  
> www.ddns.lab.		60	IN	A	192.168.50.15  
>  
> ;; AUTHORITY SECTION:  
> ddns.lab.		3600	IN	NS	ns01.dns.lab.  
>  
> ;; ADDITIONAL SECTION:  
> ns01.dns.lab.		3600	IN	A	192.168.50.10  
>   
> ;; Query time: 0 msec  
> ;; SERVER: 192.168.50.10#53(192.168.50.10)  
> ;; WHEN: Sun Sep 10 08:56:27 UTC 2023  
> ;; MSG SIZE  rcvd: 96  

- 2.9 Перезагружаем хосты, чтобы убедиться в том, что настройки сохранились после перезапуска системы:
> Last login: Sun Sep 10 08:23:23 2023 from 10.0.2.2  
> [vagrant@ns01 ~]$ uptime  
>  09:04:38 up 3 min,  1 user,  load average: 0.00, 0.00, 0.00

>[vagrant@client ~]$ uptime  
> 09:05:35 up 4 min,  1 user,  load average: 0.00, 0.00, 0.00  
>[vagrant@client ~]$ dig @192.168.50.10 www.ddns.lab  
>  
>; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.14 <<>> @192.168.50.10 www.ddns.lab  
>; (1 server found)  
>;; global options: +cmd  
>;; Got answer:  
>;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 43940  
>;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2  
>  
>;; OPT PSEUDOSECTION:  
>; EDNS: version: 0, flags:; udp: 4096  
>;; QUESTION SECTION:  
>;www.ddns.lab.			IN	A  
>  
>;; ANSWER SECTION:  
>www.ddns.lab.		60	IN	A	192.168.50.15  
>  
>;; AUTHORITY SECTION:  
>ddns.lab.		3600	IN	NS	ns01.dns.lab.  
>  
>;; ADDITIONAL SECTION:  
>ns01.dns.lab.		3600	IN	A	192.168.50.10  
>  
>;; Query time: 1 msec  
>;; SERVER: 192.168.50.10#53(192.168.50.10)  
>;; WHEN: Sun Sep 10 09:06:04 UTC 2023  
>;; MSG SIZE  rcvd: 96  

Запрос выполнен успешно. 
- 2.10 Откатываем внесенные изменения:
> [vagrant@ns01 ~]$ sudo -i  
> [root@ns01 ~]# restorecon -v -R /etc/named  
> restorecon reset /etc/named context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0  
> restorecon reset /etc/named/named.dns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0  
> restorecon reset /etc/named/named.dns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0  
> restorecon reset /etc/named/dynamic context unconfined_u:object_r:named_zone_t:s0->unconfined_u:object_r:etc_t:s0  
> restorecon reset /etc/named/dynamic/named.ddns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0  
> restorecon reset /etc/named/dynamic/named.ddns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0  
> restorecon reset /etc/named/dynamic/named.ddns.lab.view1.jnl context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0  
> restorecon reset /etc/named/named.newdns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0  
> restorecon reset /etc/named/named.50.168.192.rev context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
