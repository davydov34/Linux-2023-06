# LESOTUS1
#ОБНОВЛЕНИЕ ЯДРА

#!/bin/bash -eux
#Освежаем пакеты перед обновлением ядра  
sudo apt update  
sudo apt upgrade -y  

#Создаем директорию для под загрузку нового ядра  
sudo mkdir /usr/src/kernel5_4 && cd /usr/src/kernel5_4  

#Скачиваем доступные пакеты нового ядра соотвествующей архитектуры  
sudo wget "https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.246/amd64/linux-headers-5.4.246-0504246-generic_5.4.246-0504246.202306090538_amd64.deb"  
sudo wget "https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.246/amd64/linux-headers-5.4.246-0504246_5.4.246-0504246.202306090538_all.deb"  
sudo wget "https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.246/amd64/linux-image-unsigned-5.4.246-0504246-generic_5.4.246-0504246.202306090538_amd64.deb"  
sudo wget "https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.246/amd64/linux-modules-5.4.246-0504246-generic_5.4.246-0504246.202306090538_amd64.deb"  

#Для наглядности, перед обновлчем сохраняем номер версии старого ядра  
sudo uname -sr > old_kernel.txt  

#Через менеджер пакетов устанавливаем компоненты нового ядра  
sudo dpkg -i *.deb  

#После перезагрузки получаем ядро в системе версии 5.4.246 от 2023-06-09  
