# LESSON 35 - DNS: настройка и обслуживание

## Цель домашнего задания:
Создать домашнюю сетевую лабораторию. Изучить основы DNS, научиться работать с технологией Split-DNS в Linux-based системах.

## Описание домашнего задания:
1. Взять стенд https://github.com/erlong15/vagrant-bind   
 - добавить еще один сервер client2;
 - завести в зоне dns.lab имена:
    - web1 - смотрит на клиент1;
    - web2  смотрит на клиент2.
- завести еще одну зону newdns.lab;
- завести в ней запись;
    - www - смотрит на обоих клиентов.

2. Настроить split-dns
 - клиент1 - видит обе зоны, но в зоне dns.lab только web1;
- клиент2 видит только dns.lab.

## Введение:
**DNS(Domain Name System, Служба доменных имён)** -  это распределенная система, для получения информации о доменах. DNS используется для сопоставления IP-адресов и доменных имён.  
Сопостовления IP-адресов и DNS-имён бывают двух видов:  
 - Прямое (DNS-bмя в IP-адрес)
 - Обратное (IP-адрес в DNS-имя)

Доменная структура DNS представляет собой древовидную иерархию, состоящую из узлов, зон, доменов, поддоменов и т.д. «Вершиной» доменной структуры является корневая зона. Корневая (root) зона обозначается точкой. Далее следуют домены первого уровня (.com, ,ru, .org и т. д.) и т д.

В DNS встречаются понятия зон и доменов:  
 - **Зона** — это любая часть дерева системы доменных имён, размещаемая как единое целое на некотором DNS-сервере. 
- **Домен** – определенный узел, включающий в себя все подчинённые узлы. 

Давайте разберем основное отличие зоны от домена. Возьмём для примера ресурс otus.ru — это может быть сразу и зона и домен, однако, при использовании зоны otus.ru мы можем сделать отдельную зону mail.otus.ru, которая будет управляться не нами. В случае домена так сделать нельзя...

**FQDN (Fully Qualified Domain Name)** - полностью указанное доменное имя, т.е. от корневого домена. Ключевой идентификатор FQDN - точка в конце имени. Максимальный размер FQDN — 255 байт, с ограничением в 63 байта на каждое имя домена. Пример FQDN: mail.otus.ru.

Вся информация о DNS-ресурсах хранится в ресурсных записях. Записи хранят следующие атрибуты:  
 - **Имя (NAME)** - доменное имя, к которому привязана или которому принадлежит данная ресурсная область, либо IP-адрес. При отсутствии данного поля, запись ресурса наследуется от предыдущей записи. 
 - **TTL** (время жизни в кэше) - после указанного времени запись удаляется, данное поле может не указываться в индивидуальных записях ресурсов, но тогда оно должно быть указано в начале файла зоны и будет наследоваться всеми записями.
 - **Класс (CLASS)** - определяет тип сети (в 99% используется IN - интернет)
 - **Тип (TYPE)** - тип записи, синтаксис и назначение записи
- **Значение (DATA)**  

**Типы рекурсивных записей:**  
 - **А (Address record)** - отображают имя хоста (доменное имя) на адрес IPv4  
 - **AAAA** - отображает доменное имя на адрес IPv6
 - **CNAME** (Canonical name record/псевдоним) - привязка алиаса к существующему доменному имени
 - **MX (mail exchange)** - указывает хосты для отправки почты, адресованной домену. При этом поле NAME указывает домен назначения, а поле DATA приоритет и доменное имя хоста, ответственного за приём почты. Данные вводятся через пробел
 - **NS (name server)** -  указывает на DNS-сервер, обслуживающий данный домен. 
 - **PTR (pointer)** -  Отображает IP-адрес в доменное имя 
 - **SOA (Start of Authority/начальная запись зоны)** - описывает основные начальные настройки зоны. 
 - **SRV (server selection)** — указывает на сервера, обеспечивающие работу тех или иных служб в данном домене (например  Jabber и Active Directory).

Для работы с DNS (как клиенту) в linux используют утилиты **dig, host и nslookup**  
Также в Linux есть следующие реализации DNS-серверов:  
 - bind
 - powerdns (умеет хранить зоны в БД)
 - unbound (реализация bind)
 - dnsmasq 
 - и т д. 

**Split DNS (split-horizon или split-brain)** — это конфигурация, позволяющая отдавать разные записи зон DNS в зависимости от подсети источника запроса. Данную функцию можно реализовать как с помощью одного DNS-сервера, так и с помощью нескольких DNS-серверов… 

## 1. Работа со стендом и настройка DNS:
Скачаем себе стенд https://github.com/erlong15/vagrant-bind, перейдём в скаченный каталог.

Модифицируем файл Vagrantfile и внесём следующие изменения:
 - Параметр **ansible.sudo = "true"** рекомендуется замененить на **ansible.become = "true"**, так как **ansible.sudo** скоро перестанет использоваться…
 - Добавлено описание виртуальной машины **client2**. 
В результате получаем следующее содержание файла:
```Ruby
Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provision "ansible" do |ansible|
    ansible.verbose = "vvv"
    ansible.playbook = "provisioning/playbook.yml"
    ansible.become = "true"
  end

  config.vm.provider "virtualbox" do |v|
	  v.memory = 256
  end

  config.vm.define "ns01" do |ns01|
    ns01.vm.network "private_network", ip: "192.168.50.10", virtualbox__intnet: "dns"
    ns01.vm.hostname = "ns01"
  end

  config.vm.define "ns02" do |ns02|
    ns02.vm.network "private_network", ip: "192.168.50.11", virtualbox__intnet: "dns"
    ns02.vm.hostname = "ns02"
  end

  config.vm.define "client" do |client|
    client.vm.network "private_network", ip: "192.168.50.15", virtualbox__intnet: "dns"
    client.vm.hostname = "client"
  end

  config.vm.define "client2" do |client|
    client.vm.network "private_network", ip: "192.168.50.16", virtualbox__intnet: "dns"
    client.vm.hostname = "client2"
  end

end
```

Далее подробно разберём приложенные файлы:
 - **playbook.yml** — это Ansible-playbook, в котором содержатся инструкции по настройке нашего стенда
 - **client-motd** — файл, содержимое которого будет появляться перед пользователем, который подключился по SSH
 - **named.ddns.lab** и **named.dns.lab** — файлы описания зон ddns.lab и dns.lab соответсвенно
 - **master-named.conf** и **slave-named.conf** — конфигурационные файлы, в которых хранятся настройки DNS-сервера
 - **client-resolv.conf** и **servers-resolv.conf** — файлы, в которых содержатся IP-адреса DNS-серверов

Рассмотрим содержимое **playbook.yml**:
```YAML
---
- hosts: all
  become: yes
  tasks:
#Установка пакетов bind, bind-utils и ntp
  - name: install packages
    yum: name={{ item }} state=latest 
    with_items:
      - bind
      - bind-utils
      - ntp
#Копирование файла named.zonetransfer.key на хосты с правами 0644
#Владелец файла — root, група файла — named
  - name: copy transferkey to all servers and the client
    copy: src=named.zonetransfer.key dest=/etc/named.zonetransfer.key owner=root group=named mode=0644

#Настройка хоста ns01
- hosts: ns01
  become: yes
  tasks:
#Копирование конфигурации DNS-сервера
  - name: copy named.conf
    copy: src=master-named.conf dest=/etc/named.conf owner=root group=named mode=0640

#Копирование файлов с настроками зоны. 
#Будут скопированы все файлы, в имя которых начинается на «named.d»
  - name: copy zones
    copy: src={{ item }} dest=/etc/named/ owner=root group=named mode=0660
    with_fileglob:
      - named.d*

#Копирование файла resolv.conf
  - name: copy resolv.conf to the servers
    copy: src=servers-resolv.conf dest=/etc/resolv.conf owner=root group=root mode=0644

#Изменение прав каталога /etc/named
#Права 670, владелец — root, группа — named  
  - name: set /etc/named permissions
    file: path=/etc/named owner=root group=named mode=0670

#Перезапуск службы Named и добавление её в автозагрузку
  - name: ensure named is running and enabled
    service: name=named state=restarted enabled=yes

- hosts: ns02
  become: yes
  tasks:
  - name: copy named.conf
    copy: src=slave-named.conf dest=/etc/named.conf owner=root group=named mode=0640

  - name: copy resolv.conf to the servers
    copy: src=servers-resolv.conf dest=/etc/resolv.conf owner=root group=root mode=0644

  - name: set /etc/named permissions
    file: path=/etc/named owner=root group=named mode=0670

  - name: ensure named is running and enabled
    service: name=named state=restarted enabled=yes
    
- hosts: client
  become: yes
  tasks:
  - name: copy resolv.conf to the client
    copy: src=client-resolv.conf dest=/etc/resolv.conf owner=root group=root mode=0644

#Копирование конфигруационного файла rndc
  - name: copy rndc conf file
    copy: src=rndc.conf dest=/home/vagrant/rndc.conf owner=vagrant group=vagrant mode=0644
#Настройка сообщения при входе на сервер
  - name: copy motd to the client
    copy: src=client-motd dest=/etc/motd owner=root group=root mode=0644
```
### Добавление второго клиента в конфигурацию:
Так как мы добавили ещё одну виртуальную машину (client2), нам потребуется её настроить. Так как настройки будут совпадать с ВМ client, то мы можем просто добавить хост в модуль по настройке клиента:
```YAML
- hosts: client,client2
...
```

### Изменение конфигурации NTP:
Для нормальной работы DNS-серверов, на них должно быть настроено одинаковое время. Для того, чтобы на всех серверах было одинаковое время, нам потребуется настроить NTP. Я планирую использовать **ntpd**, поэтому, вносим в наш playbook следующие изменения:
```YAML
  # Останавливаем и убирем из автозапуска chronyd
  - name: Stop and Disable chronyd
    ansible.builtin.service:
      name: chronyd
      state: stopped
      enabled: false
  # Запускаем и добавляем в автозапуск ntpd
  - name: Start and Enable ntpd
    ansible.builtin.service:
      name: ntpd
      state: started
      enabled: true
```

### Проверка прослушиваемого адреса и портов:
Перед выполнением следующих заданий, нужно обратить внимание, на каком адресе и порту работают наши DNS-сервера. Посмотрим, что занчится в файле конфигурации настройки DNS-сервера:
Для ns01:
```bash
[root@ns01 ~]# cat /etc/named.conf 
options {

    // network 
	listen-on port 53 { 192.168.50.10; };
	listen-on-v6 port 53 { ::1; };
```
Для ns02:
```bash
[root@ns02 ~]# cat /etc/named.conf 
options {

    // network 
	listen-on port 53 { 192.168.50.11; };
	listen-on-v6 port 53 { ::1; };
```
Исходя из данной информации, нам нужно подкорректировать файл /etc/resolv.conf для DNS-серверов: на хосте ns01 указать nameserver 192.168.50.10, а на хосте ns02 — 192.168.50.11.

В Ansible для этого можно воспользоваться шаблоном с Jinja. Изменим имя файла servers-resolv.conf на servers-resolv.conf.j2 и укажем там следующие условия:
```YAML
domain dns.lab
search dns.lab
#Если имя сервера ns02, то указываем nameserver 192.168.50.11
{% if ansible_hostname == 'ns02' %}
nameserver 192.168.50.11
{% endif %}
#Если имя сервера ns01, то указываем nameserver 192.168.50.10
{% if ansible_hostname == 'ns01' %}
nameserver 192.168.50.10
{% endif %} 
```
После внесение изменений в файл, внесём измения в ansible-playbook:
Используем вместо модуля **copy** модуль **template**:
```YAML
  # Копируем resolv.conf на сервер
  - name: copy resolv.conf to the servers
    ansible.builtin.template:
      src: servers-resolv.conf.j2
      dest: /etc/resolv.conf
      owner: root
      group: root
      mode: 0644
```

### Добавление имён в зону dns.lab:
Проверим, что зона dns.lab уже существует на DNS-серверах:
Фрагмент файла /etc/named.conf на сервере ns01:
```c
// lab's zone
zone "dns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.dns.lab";
};
```
Фрагмент файла /etc/named.conf на сервере ns02:
```c
// lab's zone
zone "dns.lab" {
    type slave;
    masters { 192.168.50.10; };
    file "/etc/named/named.dns.lab";
};
```
Также на хосте ns01 мы видим файл /etc/named/named.dns.lab с настройкой зоны:
```bash
[root@ns01 ~]# cat /etc/named/named.dns.lab
$TTL 3600
$ORIGIN dns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201407 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11
[root@ns01 ~]# 
```
Именно в этот файл нам потребуется добавить имена. Допишем в конец файла следующие строки:
> ;Web  
> web1            IN      A       192.168.50.15  
> web2            IN      A       192.168.50.16  

Если изменения внесены вручную, то для применения настроек нужно:
 - Перезапустить службу named: systemctl restart named  
 - Изменить значение Serial (добавить +1 к числу 2711201407), изменение значения serial укажет slave-серверам на то, что были внесены изменения и что им надо обновить свои файлы с зонами.
После внесения изменений, выполним проверку с клиента:
```bash
[root@client ~]# dig @192.168.50.10 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.15 <<>> @192.168.50.10 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 47236
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	A

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns01.dns.lab.
dns.lab.		3600	IN	NS	ns02.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10
ns02.dns.lab.		3600	IN	A	192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Fri Nov 24 17:41:22 UTC 2023
;; MSG SIZE  rcvd: 127

[root@client ~]# 
```
```bash
[root@client ~]# dig @192.168.50.10 web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.15 <<>> @192.168.50.10 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49581
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	A

;; ANSWER SECTION:
web2.dns.lab.		3600	IN	A	192.168.50.16

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10
ns02.dns.lab.		3600	IN	A	192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Fri Nov 24 17:42:05 UTC 2023
;; MSG SIZE  rcvd: 127

[root@client ~]# 
```
В примерах мы обратились к разным DNS-серверам с разными запросами.
### Добавление имён в зону dns.lab c помощью Ansible:
В существующем Ansible-playbook менять ничего не потребуется. Нам потребуется добавить стоки с новыми именами в файл named.dns.lab и снова запустить Ansible. 

Модули, которые внесут данные изменения (переписаны в YAML формате):
```YAML
#Настройка хоста ns01
- hosts: ns01
  become: yes
  tasks:
#Копирование конфигурации DNS-сервера
  - name: copy named.conf
    copy: 
      src: master-named.conf
      dest: /etc/named.conf 
      owner: root 
      group: named
      mode: 0640

#Копирование файлов с настроками зоны. 
#Будут скопированы все файлы, в имя которых начинается на «named.d»
  - name: copy zones
    copy: 
      src: "{{ item }}" 
      dest: /etc/named/
      owner: root
      group: named
      mode: 0660
    with_items:
      - named.ddns.lab
      - named.dns.lab
      - named.dns.lab.client
      - named.dns.lab.rev
      - named.newdns.lab

#Перезапуск службы Named и добавление её в автозагрузку
  - name: ensure named is running and enabled
    service: 
      name: named
      state: restarted
      enabled: yes
```
### Создание новой зоны и добавление в неё записей:
Для того, чтобы прописать на DNS-серверах новую зону нам потребуется:  
-  На хосте **ns01** добавить зону в файл **/etc/named.conf**:
```c
// lab's newdns zone
zone "newdns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    allow-update { key "zonetransfer.key"; };
    file "/etc/named/named.newdns.lab";
};
```
 - На хосте **ns02** также добавить зону и указать с какого сервера запрашивать информацию об этой зоне (фрагмент файла **/etc/named.conf)**:
```c
// lab's newdns zone
zone "newdns.lab" {
    type slave;
    masters { 192.168.50.10; };
    file "/etc/named/named.newdns.lab";
};
```
 - На хосте ns01 создадим файл **/etc/named/named.newdns.lab**:
```bash
$TTL 3600
$ORIGIN newdns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201007 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

;WWW
www             IN      A       192.168.50.15
www             IN      A       192.168.50.16
```
В конце этого файла добавим записи www. У файла должны быть права 660, владелец — root, группа — named. 
После внесения данных изменений, изменяем значение serial (добавлем +1 к значению 2711201007) и перезапускаем named: systemctl restart named.

### Создание новой зоны и добавление в неё записей с помощью Ansible:
Для создания зоны и добавления в неё записей, добавляем зону в файл /etc/named.conf на хостах ns01 и ns02, а также создаем файл named.newdns.lab, который далее отправим на сервер ns01.

Добавим в модуль copy наш файл named.newdns.lab:
```YAML
- name: copy zones
    copy: src={{ item }} dest=/etc/named/ owner=root group=named mode=0660
    with_fileglob:
      - named.d*
      - named.newdns.lab
```
Соответственно файл  named.newdns.lab будет скопирован на хост ns01 по адресу /etc/named/named.newdns.lab

Остальную часть playbook можно оставить без изменений.

## 2. Настройка Split-DNS
У нас уже есть прописанные зоны **dns.lab** и **newdns.lab**. Однако по заданию client1  должен видеть запись web1.dns.lab и не видеть запись web2.dns.lab. Client2 может видеть обе записи из домена dns.lab, но не должен видеть записи домена newdns.lab Осуществить данные настройки нам поможет технология Split-DNS.  

Для настройки Split-DNS нужно:  
1) Создать дополнительный файл зоны dns.lab, в котором будет прописана только одна запись: vim /etc/named/named.dns.lab.client:
```bash
$TTL 3600
$ORIGIN dns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201407 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

;Web
web1            IN      A       192.168.50.15
```
Имя файла может отличаться от указанной зоны. У файла должны быть права 660, владелец — root, группа — named.  

2) Внести изменения в файл /etc/named.conf на хостах ns01 и ns02

Прежде всего нужно сделать access листы для хостов client и client2. Сначала сгенерируем ключи для хостов client и client2, для этого на хосте ns01 запустим утилиту tsig-keygen (ключ может генериться 5 минут и более):
```bash
[root@ns01 ~]# tsig-keygen 
key "tsig-key" {
	algorithm hmac-sha256;
	secret "GKZv/tGeS+yfCM1NYj9TawI9rBzgQlflASTxOlwTG+8=";
};
[root@ns01 ~]# tsig-keygen 
key "tsig-key" {
	algorithm hmac-sha256;
	secret "whtiqn/vvaHV1JHGvw4DApT5HgOpyZl6NQ+yHFpbtD8=";
};
[root@ns01 ~]# 
```
После генерации, мы увидим ключ (secret) и алгоритм с помощью которого он был сгенерирован. Оба этих параметра нам потребуются в access листе. 
Если нам потребуется, использовать другой алгоритм, то мы можем его указать как аргумент к команде, например:  tsig-keygen -a hmac-md5

Всего нам потребуется 2 таких ключа. После их генерации добавим блок с access листами в конец файла /etc/named.conf
```bash
key "client-key" {
	algorithm hmac-sha256;
	secret "GKZv/tGeS+yfCM1NYj9TawI9rBzgQlflASTxOlwTG+8=";
};

key "client2-key" {
	algorithm hmac-sha256;
	secret "whtiqn/vvaHV1JHGvw4DApT5HgOpyZl6NQ+yHFpbtD8=";
};

acl client { !key client2-key; key client-key; 192.168.50.15; };
acl client2 { !key client-key; key client2-key; 192.168.50.16; };
```
В данном блоке access листов мы выделяем 2 блока:  
 - client имеет адрес 192.168.50.15, использует client-key и не использует client2-key;  
 - client2 имеет адрес 192ю168.50.16, использует clinet2-key и не использует client-key.  

Описание ключей и access листов будет одинаковое для master и slave сервера.

Далее нужно создать файл с настройками зоны dns.lab для client, для этого на мастер сервере создаём файл /etc/named/named.dns.lab.client и добавляем в него следующее содержимое:
```bash
$TTL 3600
$ORIGIN dns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201407 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

;Web
web1            IN      A       192.168.50.15
```
Это почти скопированный файл зоны dns.lab, в конце которого удалена строка с записью web2. Имя зоны надо оставить такой же — **dns.lab**

Теперь можно внести правки в **/etc/named.conf**

Технология Split-DNS реализуется с помощью описания представлений (view), для каждого отдельного acl. В каждое представление (view) добавляются только те зоны, которые разрешено видеть хостам, адреса которых указаны в access листе.

Все ранее описанные зоны должны быть перенесены в модули view. Вне view зон быть недолжно, зона any должна всегда находиться в самом низу. 

После применения всех вышеуказанных правил на хосте ns01 мы получим следующее содержимое файла /etc/named.conf
```bash
options {

    // network
	listen-on port 53 { 192.168.50.10; };
        listen-on-v6 port 53 { ::1; };

    // data
	directory	"/var/named";
        dump-file	"/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";

    // server
	recursion yes;
        allow-query     { any; };
    allow-transfer { any; };

    // dnssec
	dnssec-enable yes;
        dnssec-validation yes;

    // others
	bindkeys-file "/etc/named.iscdlv.key";
        managed-keys-directory "/var/named/dynamic";
        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
	channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// RNDC Control for client
key "rndc-key" {
    algorithm hmac-md5;
    secret "GrtiE9kz16GK+OKKU/qJvQ==";
};
controls {
	inet 192.168.50.10 allow { 192.168.50.15; } keys { "rndc-key"; };
};

key "client-key" {
        algorithm hmac-sha256;
        secret "GKZv/tGeS+yfCM1NYj9TawI9rBzgQlflASTxOlwTG+8=";
};

key "client2-key" {
        algorithm hmac-sha256;
        secret "whtiqn/vvaHV1JHGvw4DApT5HgOpyZl6NQ+yHFpbtD8=";
};

// ZONE TRANSFER WITH TSIG
include "/etc/named.zonetransfer.key";
server 192.168.50.11 {
    keys { "zonetransfer.key"; };
};

acl client { !key client2-key; key client-key; 192.168.50.15; };
acl client2 { !key client-key; key client2-key; 192.168.50.16; };

view "client" {
  match-clients { client; };

  zone "dns.lab" {
        type master;
        file "/etc/named/named.dns.lab.client";
        also-notify { 192.168.50.11 key client-key; };
        };

// newdns.lab zone
zone "newdns.lab" {
        type master;
        file "/etc/named/named.newdns.lab";
        also-notify { 192.168.50.11 key client-key; };
        };
};

view "client2" {
        match-clients { client2; };
        // dns.lab zone
        zone "dns.lab" {
        type master;
        file "/etc/named/named.dns.lab";
        also-notify { 192.168.50.11 key client2-key; };
        };
// dns.lab zone reverse
        zone "50.168.192.in-addr.arpa" {
        type master;
        file "/etc/named/named.dns.lab.rev";
        also-notify { 192.168.50.11 key client2-key; };
  };
};

view "default" {
        match-clients { any; };
// root zone
zone "." IN {
	type hint;
        file "named.ca";
  };

// zones like localhost
include "/etc/named.rfc1912.zones";
// root's DNSKEY
include "/etc/named.root.key";

// lab's zone
zone "dns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.dns.lab";
  };

// lab's zone reverse
zone "50.168.192.in-addr.arpa" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.dns.lab.rev";
  };

// lab's ddns zone
zone "ddns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    allow-update { key "zonetransfer.key"; };
    file "/etc/named/named.ddns.lab";
  };

// lab's newdns zone
zone "newdns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.newdns.lab";
  };

};
```
Далее внесем изменения в файл /etc/named.conf на сервере ns02. Файл будет похож на файл, лежащий на ns01, только в настройках будет указание забирать информацию с сервера ns01:
```bash
options {

    // network
	listen-on port 53 { 192.168.50.11; };
        listen-on-v6 port 53 { ::1; };

    // data
	directory	"/var/named";
        dump-file	"/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";

    // server
	recursion yes;
        allow-query     { any; };
    allow-transfer { any; };

    // dnssec
	dnssec-enable yes;
        dnssec-validation yes;

    // others
	bindkeys-file "/etc/named.iscdlv.key";
        managed-keys-directory "/var/named/dynamic";
        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
	channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// RNDC Control for client
key "rndc-key" {
    algorithm hmac-md5;
    secret "GrtiE9kz16GK+OKKU/qJvQ==";
};
controls {
	inet 192.168.50.11 allow { 192.168.50.15; } keys { "rndc-key"; };
};
// lab's ddns zone
zone "ddns.lab" {
    type slave;
    masters { 192.168.50.10; };
};

// newdns.lab zone
zone "newdns.lab" {
    type slave;
    masters { 192.168.50.10; };
};

};

key "client-key" {
        algorithm hmac-sha256;
        secret "GKZv/tGeS+yfCM1NYj9TawI9rBzgQlflASTxOlwTG+8=";
};

key "client2-key" {
        algorithm hmac-sha256;
        secret "whtiqn/vvaHV1JHGvw4DApT5HgOpyZl6NQ+yHFpbtD8=";
};

// ZONE TRANSFER WITH TSIG
include "/etc/named.zonetransfer.key";
server 192.168.50.10 {
    keys { "zonetransfer.key"; };
};

acl client { !key client2-key; key client-key; 192.168.50.15; };
acl client2 { !key client-key; key client2-key; 192.168.50.16; };

view "client" {
        match-clients { client; };
        allow-query { any; };

        zone "dns.lab" {
        type slave;
        masters { 192.168.50.10 key client-key; };
};

// newdns.lab zone
zone "newdns.lab" {
        type slave;
        masters { 192.168.50.10 key client-key; };
  };
};

view "client2" {
        match-clients { client2; };
        // dns.lab zone
        zone "dns.lab" {
        type slave;
        masters { 192.168.50.10 key client2-key; };
        };
// dns.lab zone reverse
        zone "50.168.192.in-addr.arpa" {
        type slave;
        masters { 192.168.50.10 key client2-key; };
  };
};

view "default" {
        match-clients { any; };

// root zone
zone "." IN {
	type hint;
        file "named.ca";
};

// zones like localhost
include "/etc/named.rfc1912.zones";
// root's DNSKEY
include "/etc/named.root.key";

// lab's zone
zone "dns.lab" {
    type slave;
    masters { 192.168.50.10; };
};

// lab's zone reverse
zone "50.168.192.in-addr.arpa" {
    type slave;
    masters { 192.168.50.10; };
};

// lab's ddns zone
zone "ddns.lab" {
    type slave;
    masters { 192.168.50.10; };
};

// newdns.lab zone
zone "newdns.lab" {
    type slave;
    masters { 192.168.50.10; };
};

};
```
После внесения данных изменений можно перезапустить (по очереди) службу named на серверах ns01 и ns02.
Далее, нужно будет проверить работу Split-DNS с хостов client и client2. Для проверки можно использовать утилиту ping:
Проверка на client:
```bash
[vagrant@client ~]$ ping -c2 www.newdns.lab
PING www.newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.010 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.030 ms

--- www.newdns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.010/0.020/0.030/0.010 ms
[vagrant@client ~]$ ping -c2 web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.010 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.023 ms

--- web1.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 0.010/0.016/0.023/0.007 ms
[vagrant@client ~]$ ping -c2 web2.dns.lab
ping: web2.dns.lab: Name or service not known
[vagrant@client ~]$ 
```
На хосте мы видим, что client видит обе зоны (dns.lab и newdns.lab), однако
информацию о хосте web2.dns.lab он получить не может.

Проверка на client2:
```bash
[vagrant@client2 ~]$ ping -c2 www.newdns.lab
ping: www.newdns.lab: Name or service not known
[vagrant@client2 ~]$ ping -c2 web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=1 ttl=64 time=0.222 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=2 ttl=64 time=0.380 ms

--- web1.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 0.222/0.301/0.380/0.079 ms
[vagrant@client2 ~]$ ping -c2 web2.dns.lab
PING web2.dns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.010 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.026 ms

--- web2.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.010/0.018/0.026/0.008 ms
[vagrant@client2 ~]$ 
```
Тут мы понимаем, что client2 видит всю зону dns.lab и не видит зону
newdns.lab.