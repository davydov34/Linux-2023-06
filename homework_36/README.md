# LESSON 36 - Сетевые пакеты. VLAN'ы. LACP.

## Цель домашнего задания:
Научиться настраивать VLAN и LACP.

## Описание домашнего задания:
в Office1 в тестовой подсети появляется сервера с доп интерфесами и адресами
в internal сети testLAN: 
 - testClient1 - 10.10.10.254
 - testClient2 - 10.10.10.254
 - testServer1- 10.10.10.1 
 - testServer2- 10.10.10.1

Равести вланами:
 - testClient1 <-> testServer1
 - testClient2 <-> testServer2

Между centralRouter и inetRouter "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд, проверить работу c отключением интерфейсов

## Введение:
Иногда требуется разделить сеть на несколько подсетей, для этого отлично подходит технология VLAN`ов.  
**VLAN (Virtual Local Area Network**, виртуальная локальная компьютерная сеть) -  это виртуальные сети, которые работают на втором уровне модели OSI. Протокол VLAN разделяет хосты на подсети, путём добавления тэга к каждоум кадру (Протокол 802.1Q).
Принцип работы VLAN:
Группа устройств в сети VLAN взаимодействует так, будто устройства подключены с помощью одного кабеля…
**Преимущества использования VLAN:**
 - Безопасность
 - Снижение издержек
 - Повышение производительности (уменьшение лишнего трафика)
 - Сокращение количества доменов широковещательной рассылки
 - Повышение производительности ИТ-отдела

Пакеты между VLAN могут передаваться только через маршрутизатор или коммутатор 3-го уровня. 

Если через один порт требуется передавать сразу несколько VLAN`ов, то используются Trunk-порты.

Помимо VLAN иногда требуется объединить несколько линков, это делается для увеличения отказоустойчивости. 
**Агрегирование каналов (англ. link aggregation)** — технологии объединения нескольких параллельных каналов передачи данных в сетях Ethernet в один логический, позволяющие увеличить пропускную способность и повысить надёжность. В различных конкретных реализациях агрегирования используются альтернативные наименования: транкинг портов (англ. port trunking), связывание каналов (link bundling), склейка адаптеров (NIC bonding), сопряжение адаптеров (NIC teaming).

**LACP (англ. link aggregation control protocol)** — открытый стандартный протокол агрегирования каналов, описанный в документах IEEE 802.3ad и IEEE 802.1aq.
Главное преимущество агрегирования каналов в том, что потенциально повышается полоса пропускания: в идеальных условиях полоса может достичь суммы полос пропускания объединённых каналов. Другое преимущество — «горячее» резервирование линий связи: в случае отказа одного из агрегируемых каналов трафик без прерывания сервиса посылается через оставшиеся, а после восстановления отказавшего канала он автоматически включается в работу.

## Схема сети:
Для выполнения домашнего задания развернём стен. Vagrant-файл выглядит следующим образом:
```Ruby

```
Данный Vagrantfile развернёт 7 виртаульных машин:
 - 5 ВМ на CentOS 8 Stream
 - 2 ВМ на Debian 11 

Обратите внимание, что хосты testClient1, testServer1, testClient2 и testServer2 находятся в одной сети (testLAN). 

Для использования Ansible, каждому хосту выделен ip-адрес из подсети 192.168.56.0/24.
По итогу выполнения домашнего задания у нас должна получиться следующая топология сети: 
![img](./img/VLAN_scheme(2).png)

## Предварительная настройка хостов:
Перед настройкой VLAN и LACP рекомендуется установить на хосты следующие утилиты:
 - vim
 - traceroute
 - tcpdump
 - net-tools

## Настройка VLAN на хостах:
### Настройка VLAN на RHEL-based системах:
На хосте **testClient1** требуется создать файл **/etc/sysconfig/network-scripts/ifcfg-vlan1** со следующим параметрами:

```bash
VLAN=yes
#Тип интерфеса - VLAN
TYPE=Vlan
#Указываем фиическое устройство, через которые будет работь VLAN
PHYSDEV=eth1
#Указываем номер VLAN (VLAN_ID)
VLAN_ID=1
VLAN_NAME_TYPE=DEV_PLUS_VID_NO_PAD
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
#Указываем IP-адрес интерфейса
IPADDR=10.10.10.254
#Указываем префикс (маску) подсети
PREFIX=24
#Указываем имя vlan
NAME=vlan1
#Указываем имя подинтерфейса
DEVICE=eth1.1
ONBOOT=yes
```
На хосте **testServer1** создадим идентичный файл с другим IP-адресом (10.10.10.1).  
После создания файлов нужно перезапустить сеть на обоих хостах:
**systemctl restart NetworkManager**  
Проверим настройку интерфейса, если настройка произведена правильно, то с хоста testClient1 будет проходить ping до хоста testServer1:  
```bash
[root@testClient1 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:74:63:fc brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute eth0
       valid_lft 86395sec preferred_lft 86395sec
    inet6 fe80::5054:ff:fe74:63fc/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:77:df:03 brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet 127.0.0.10/24 brd 127.0.0.255 scope host noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe77:df03/64 scope link 
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:43:88:1b brd ff:ff:ff:ff:ff:ff
    altname enp0s19
    inet 192.168.56.21/24 brd 192.168.56.255 scope global noprefixroute eth2
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe43:881b/64 scope link 
       valid_lft forever preferred_lft forever
**5: eth1.1@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:77:df:03 brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.254/24 brd 10.10.10.255 scope global noprefixroute eth1.1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe77:df03/64 scope link 
       valid_lft forever preferred_lft forever**
```
```bash
[root@testServer1 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:74:63:fc brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute eth0
       valid_lft 86367sec preferred_lft 86367sec
    inet6 fe80::5054:ff:fe74:63fc/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:46:22:b8 brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet 127.0.0.11/24 brd 127.0.0.255 scope host noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe46:22b8/64 scope link 
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:66:61:b6 brd ff:ff:ff:ff:ff:ff
    altname enp0s19
    inet 192.168.56.22/24 brd 192.168.56.255 scope global noprefixroute eth2
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe66:61b6/64 scope link 
       valid_lft forever preferred_lft forever
5: eth1.1@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:46:22:b8 brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.1/24 brd 10.10.10.255 scope global noprefixroute eth1.1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe46:22b8/64 scope link 
       valid_lft forever preferred_lft forever
```
```bash
[root@testClient1 ~]# ping -c 2 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.188 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.226 ms

--- 10.10.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1046ms
rtt min/avg/max/mdev = 0.188/0.207/0.226/0.019 ms
```
```bash
[root@testServer1 ~]# ping -c2 10.10.10.254
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=0.223 ms
64 bytes from 10.10.10.254: icmp_seq=2 ttl=64 time=0.224 ms

--- 10.10.10.254 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1026ms
rtt min/avg/max/mdev = 0.223/0.223/0.224/0.014 ms
```

### Настройка VLAN на Debian-based системах:
На хосте **testClient2** требуется создать файл **/etc/netplan/50-cloud-init.yaml** со следующим параметрами:
```YAML
network:
    version: 2
    ethernets:
        enp0s3:
            dhcp4: true
        eth1: {}
    vlans:
        vlan2:
          id: 2
          link: eth1
          dhcp4: no
          addresses: [10.10.10.254/24]
```
На хосте **testServer2** создадим идентичный файл с другим IP-адресом (10.10.10.1).
После создания файлов нужно перезапустить сеть на обоих хостах: **netplan apply**
После настройки второго VLAN`а ping должен работать между хостами testClient1, testServer1 и между хостами testClient2, testServer2.
```bash
root@testClient2:/etc/netplan# ping -c2 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.199 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.235 ms

--- 10.10.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1026ms
rtt min/avg/max/mdev = 0.199/0.217/0.235/0.018 ms
```

```bash
root@testServer2:/etc/netplan# ping -c2 10.10.10.254
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=0.319 ms
64 bytes from 10.10.10.254: icmp_seq=2 ttl=64 time=0.241 ms

--- 10.10.10.254 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1005ms
rtt min/avg/max/mdev = 0.241/0.280/0.319/0.039 ms
```
*Примечание: до остальных хостов ping работать не будет, так как не настроена маршрутизация.*

## Настройка LACP между хостами inetRouter и centralRouter
Bond интерфейс будет работать через порты eth1 и eth2. 

1) Изначально необходимо на обоих хостах добавить конфигурационные файлы для интерфейсов eth1 и eth2:
```bash
DEVICE=eth1
ONBOOT=yes
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
NM_CONTROLLED=yes
USERCTL=no
```
У интерфейса **ifcfg-eth2** идентичный конфигурационный файл, в котором нужно изменить имя интерфейса. 

2) После настройки интерфейсов eth1 и eth2 нужно настроить bond-интерфейс, для этого создадим файл **/etc/sysconfig/network-scripts/ifcfg-bond0**

```bash
DEVICE=bond0
NAME=bond0
TYPE=Bond
BONDING_MASTER=yes
IPADDR=192.168.255.1
NETMASK=255.255.255.252
ONBOOT=yes
BOOTPROTO=static
BONDING_OPTS="mode=1 miimon=100 fail_over_mac=1"
NM_CONTROLLED=yes
```
После создания данных конфигурационных файлов неоьходимо перзапустить сеть:
**systemctl restart NetworkManager**

На некоторых версиях RHEL/CentOS перезапуск сетевого интерфейса не запустит bond-интерфейс, в этом случае рекомендуется перезапустить хост.

После настройки агрегации портов, необходимо проверить работу bond-интерфейса, для этого, на хосте inetRouter (192.168.255.1) запустим ping до centralRouter (192.168.255.2):
```bash
[vagrant@inetRouter ~]$ ping -c2 192.168.255.2
PING 192.168.255.2 (192.168.255.2) 56(84) bytes of data.
64 bytes from 192.168.255.2: icmp_seq=1 ttl=64 time=0.202 ms
64 bytes from 192.168.255.2: icmp_seq=2 ttl=64 time=0.213 ms

--- 192.168.255.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1011ms
rtt min/avg/max/mdev = 0.202/0.207/0.213/0.015 ms
```
Не отменяя ping подключаемся к хосту centralRouter и выключаем там интерфейс eth1: 
```bash
[vagrant@centralRouter ~]$ sudo ip link set down eth1
```
После данного действия ping не должен пропасть, так как трафик пойдёт по-другому порту.