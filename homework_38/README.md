# LESSON 37 - LDAP: Централизованная авторизация и аутентификация
## Цель домашнего задания:
Научиться настраивать LDAP-сервер и подключать к нему LDAP-клиентов

## Описание домашнего задания:
1. Установить FreeIPA
2. Написать Ansible-playbook для конфигурации клиента

## Введение:
**LDAP (Lightweight Directory Access Protocol — легковесный протокол доступа к каталогам)** —  это протокол для хранения и получения данных из каталога с иерархической структурой.
LDAP не является протоколом аутентификации или авторизации 

С увеличением числа серверов затрудняется управление пользователями на этих сервере. LDAP решает задачу централизованного управления доступом. 
С помощью LDAP можно синхронизировать:
 - UID пользователей
 - Группы (GID)
 - Домашние каталоги
 - Общие настройки для хостов 
 - и т. д. 

LDAP работает на следующих портах: 
 - 389/TCP — без TLS/SSL
 - 636/TCP — с TLS/SSL

**Основные компоненты LDAP:**

![img](./img/LDAP_components.png#center)
 - **Атрибуты** — пара «ключ-значение». Пример атрибута: mail: admin@example.com
 - **Записи (entry)** — набор атрибутов под именем, используемый для описания чего-либо

 > *Пример записи:*  
 > *dn: sn=Ivanov, ou=people, dc=digitalocean,dc=com*  
 > *objectclass: person*  
 > *sn: Ivanov*  
 > *cn: Ivan Ivanov*  
 - **Data Information Tree (DIT)** — организационная структура, где каждая запись имеет ровно одну родительскую запись и под ней может находиться любое количество дочерних записей. Запись верхнего уровня — исключение

 На основе LDAP построенно много решений, например: Microsoft Active Directory, OpenLDAP, FreeIPA и т.д.

В данной лабораторной работе будет рассмотрена установка и настройка FreeIPA. FreeIPA — это готовое решение, включающее в себе:
 - Сервер LDAP на базе Novell 389 DS c предустановленными схемами
 - Сервер Kerberos
 - Предустановленный BIND с хранилищем зон в LDAP
 - Web-консоль управления

## Конфигурация виртуальных машин:
Создадим Vagrantfile, в котором будут указаны параметры наших ВМ:
```Ruby
Vagrant.configure("2") do |config|
    # Указываем ОС, версию, количество ядер и ОЗУ
    config.vm.box = "centos/stream8"
    config.vm.box_version = "20230710.0"
 
    config.vm.provider :virtualbox do |v|
      v.memory = 2048
      v.cpus = 1
    end
  
    # Указываем имена хостов и их IP-адреса
    boxes = [
      { :name => "ipa.otus.lan",
        :ip => "192.168.57.10",
      },
      { :name => "client1.otus.lan",
        :ip => "192.168.57.11",
      },
      { :name => "client2.otus.lan",
        :ip => "192.168.57.12",
      }
    ]
    # Цикл запуска виртуальных машин
    boxes.each do |opts|
      config.vm.define opts[:name] do |config|
        config.vm.hostname = opts[:name]
        config.vm.network "private_network", ip: opts[:ip]
      end
    end
  end
```
После создания Vagrantfile, запустим виртуальные машины командой vagrant up. Будут созданы 3 виртуальных машины с ОС CentOS 8 Stream. Каждая ВМ будет иметь по 2ГБ ОЗУ и по одному ядру CPU.

## 1. Установка FreeIPA сервера

Для начала нам необходимо настроить FreeIPA-сервер. Подключимся к нему по SSH с помощью команды: vagrant ssh ipa.otus.lan и перейдём в root-пользователя: sudo -i.
Начнём настройку FreeIPA-сервера: 
 - Установим часовой пояс: **timedatectl set-timezone Europe/Moscow**
 - Установим утилиту chrony: **yum install -y chrony**
 - Запустим **chrony** и добавим его в автозагрузку: **systemctl enable chronyd —now**
 - Выключим Firewall: **systemctl stop firewalld**
 - Отключим автозапуск Firewalld: **systemctl disable firewalld**
 - Остановим Selinux: **setenforce 0*
 - Поменяем в файле **/etc/selinux/config**, параметр Selinux на **disabled**


 - Для дальнейшей настройки FreeIPA нам потребуется, чтобы DNS-сервер хранил запись о нашем LDAP-сервере. В рамках данной лабораторной работы мы не будем настраивать отдельный DNS-сервер и просто добавим запись в файл /etc/hosts
vi /etc/hosts:
```
127.0.0.1 localhost localhost.localdomain 
127.0.1.1 ipa.otus.lan ipa
192.168.57.10 ipa.otus.lan ipa
```
 - Установим модуль DL1: yum install -y @idm:DL1
 - Установим FreeIPA-сервер: yum install -y ipa-server
 - Запустим скрипт установки:ip ipa-server-install:
```
Do you want to configure integrated DNS (BIND)? [no]: no
Server host name [ipa.otus.lan]: <Нажимем Enter>
Please confirm the domain name [otus.lan]: <Нажимем Enter>
Please provide a realm name [OTUS.LAN]: <Нажимем Enter>
Directory Manager password: <Указываем пароль минимум 8 символов>
Password (confirm): <Дублируем указанный пароль>
IPA admin password: <Указываем пароль минимум 8 символов>
Password (confirm): <Дублируем указанный пароль>
NetBIOS domain name [OTUS]: <Нажимем Enter>
Do you want to configure chrony with NTP server or pool address? [no]: no
The IPA Master Server will be configured with:
Hostname:       ipa.otus.lan
IP address(es): 192.168.57.10
Domain name:    otus.lan
Realm name:     OTUS.LAN

The CA will be configured with:
Subject DN:   CN=Certificate Authority,O=OTUS.LAN
Subject base: O=OTUS.LAN
Chaining:     self-signed
Проверяем параметры, если всё устраивает, то нажимаем yes
Continue to configure the system with these values? [no]: yes
```
Если мастер успешно выполнит настройку FreeIPA то в конце мы получим сообщение: 
*The ipa-server-install command was successful*

Gри вводе параметров установки мы вводили 2 пароля:
 - **Directory Manager password** — это пароль администратора сервера каталогов, У этого пользователя есть полный доступ к каталогу.
 - **IPA admin password** — пароль от пользователя FreeIPA admin

После успешной установки FreeIPA, проверим, что сервер Kerberos может выдать нам билет:

```bash
[root@ipa ~]# kinit admin
Password for admin@OTUS.LAN: 
[root@ipa ~]# klist 
Ticket cache: KCM:0
Default principal: admin@OTUS.LAN

Valid starting     Expires            Service principal
11/25/23 18:18:38  11/26/23 17:26:11  krbtgt/OTUS.LAN@OTUS.LAN
```
Для удаление полученного билета воспользуемся командой: **kdestroy**  
Мы можем зайти в Web-интерфейс нашего FreeIPA-сервера, для этого на нашей хостой машине нужно прописать следующую строку в файле Hosts:
**192.168.57.10 ipa.otus.lan**

После добавления DNS-записи откроем c нашей хост-машины веб-страницу:
![img](./img/freeIPA_browser.png#center)

Откроется окно управления FreeIPA-сервером. В имени пользователя укажем admin, в пароле укажем наш IPA admin password и нажмём войти. 
![img](./img/freeIPA_auth.png#center)

Откроется веб-консоль упрвления FreeIPA. Данные во FreeIPA можно вносить как через веб-консоль, так и средствами коммандной строки.

На этом установка и настройка FreeIPA-сервера завершена.

## 2. Ansible playbook для конфигурации клиента:
Настройка клиента похожа на настройку сервера. На хосте также нужно:
 - Настроить синхронизацию времени и часовой пояс;
 - Настроить (или выключить) firewall;
 - Настроить (или выключить) SElinux;
 - В файле hosts должна быть указана запись с FreeIPA-сервером и хостом.

 Хостов, которые требуется добавить к серверу может быть много, для упращения нашей работы выполним настройки с помощью Ansible.
 Файо hosts будет иметь следующий вид:
 ```
[clients]
client1.otus.lan ansible_host=192.168.57.11 ansible_user=vagrant ansible_ssh_private_key_file=./.vagrant/machines/client1.otus.lan/virtualbox/private_key
client2.otus.lan ansible_host=192.168.57.12 ansible_user=vagrant ansible_ssh_private_key_file=./.vagrant/machines/client2.otus.lan/virtualbox/private_key
 ```

 Создаём плейбук для настройки клиентов:
 ```YAML
 - name: Base set up
  hosts: all
  #Выполнять действия от root-пользователя
  become: yes
  tasks:
  #Установка текстового редактора Vim и chrony
  - name: install softs on CentOS
    yum:
      name:
        - vim
        - chrony
      state: present
      update_cache: true

  #Отключение firewalld и удаление его из автозагрузки
  - name: disable firewalld
    service:
      name: firewalld
      state: stopped
      enabled: false
  
  #Отключение SElinux из автозагрузки
  #Будет применено после перезагрузки
  - name: disable SElinux
    selinux:
      state: disabled
  
  #Отключение SElinux до перезагрузки
  - name: disable SElinux now
    shell: setenforce 0

  #Установка временной зоны Европа/Москва    
  - name: Set up timezone
    timezone:
      name: "Europe/Moscow"

  #Запуск службы Chrony, добавление её в автозагрузку
  - name: enable chrony
    service:
      name: chronyd
      state: restarted
      enabled: true
  
  #Копирование файла /etc/hosts c правами root:root 0644
  - name: change /etc/hosts
    template:
      src: hosts.j2
      dest: /etc/hosts
      owner: root
      group: root
      mode: 0644

  
  #Установка клиента Freeipa
  - name: install module ipa-client
    yum:
      name:
        - freeipa-client
      state: present
      update_cache: true
  
  #Запуск скрипта добавления хоста к серверу
  - name: add host to ipa-server
    shell: echo -e "yes\nyes" | ipa-client-install --mkhomedir --domain=OTUS.LAN --server=ipa.otus.lan --no-ntp -p admin -w otus2023
 ```
Файл hosts для клиентов выглядит следующим образом:
```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.57.10 ipa.otus.lan ipa
```
Почти все модули нам уже знакомы, давайте подробнее остановимся на последней команде echo *-e "yes\nyes" | ipa-client-install --mkhomedir --domain=OTUS.LAN --server=ipa.otus.lan --no-ntp -p admin -w otus2023*

При добавлении хоста к домену мы можем просто ввести команду **ipa-client-install** и следовать мастеру подключения к FreeIPA-серверу (как было в первом пункте).

Однако команда позволяет нам сразу задать требуемые нам параметры:  
**--domain** — имя домена;  
**--server** — имя FreeIPA-сервера;  
**--no-ntp** — не настраивать дополнительно ntp (мы уже настроили chrony);  
**-p** — имя админа домена;  
**-w** — пароль администратора домена (IPA password);  
**--mkhomedir** — создать директории пользователей при их первом логине.  

Если мы сразу укажем все параметры, то можем добавить эту команду в Ansible и автоматизировать процесс добавления хостов в домен. 

Альтернативным вариантом мы можем найти на GitHub отдельные модули по подключениею хостов к FreeIPA-сервер. 

После подключения хостов к FreeIPA-сервер нужно проверить, что мы можем получить билет от Kerberos сервера: *kinit admin**
Если подключение выполнено правильно, то мы сможем получить билет, после ввода пароля. 
Проверим работу LDAP, для этого на сервере FreeIPA создадим пользователя и попробуем залогиниться к клиенту:
1. Авторизируемся на сервере: kinit admin;
2. Создадим пользователя otus-user:
```
[root@ipa ~]# ipa user-add otus-user --first=Otus --last=User --password
Password: 
Enter Password again to verify: 
----------------------
Added user "otus-user"
----------------------
  User login: otus-user
  First name: Otus
  Last name: User
  Full name: Otus User
  Display name: Otus User
  Initials: OU
  Home directory: /home/otus-user
  GECOS: Otus User
  Login shell: /bin/sh
  Principal name: otus-user@OTUS.LAN
  Principal alias: otus-user@OTUS.LAN
  User password expiration: 20231125170550Z
  Email address: otus-user@otus.lan
  UID: 1780000003
  GID: 1780000003
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True
```
3. На хосте client1 или client2 выполним команду **kinit otus-user**:
```
davydov@davydov-UBUNTU:~/Vagrant38$ vagrant ssh client2.otus.lan
Last login: Sat Nov 25 19:45:09 2023 from 192.168.57.1
[vagrant@client2 ~]$ kinit otus-user
Password for otus-user@OTUS.LAN: 
Password expired.  You must change it now.
Enter new password: 
Enter it again: 
[vagrant@client2 ~]$ 
```
Система запросит пароль и попросит ввести новый пароль. 

На этом процесс добавления хостов к FreeIPA-серверу завершен.