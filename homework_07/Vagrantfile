# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end

  config.vm.define "repo" do |repo|
    repo.vm.network "public_network"
    repo.vm.hostname = "my-repo"
    repo.vm.provision "shell", path: "postinstall.sh"
  end


end
