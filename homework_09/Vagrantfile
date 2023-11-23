# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/stream8"

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end

  config.vm.define "systemd" do |sysd|
    sysd.vm.network "public_network"
    sysd.vm.hostname = "system-d"
    sysd.vm.provision "shell", path: "preinstall.sh"
    sysd.vm.provision 'shell', reboot: true
    sysd.vm.provision "shell", path: "task1.sh"
    sysd.vm.provision "shell", path: "task2.sh"
    sysd.vm.provision "shell", path: "task3.sh"
  end

end
