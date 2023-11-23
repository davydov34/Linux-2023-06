# -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  :server => {
        :box_name => "generic/ubuntu2204",
        :vm_name => "server",
        :net => [  ["192.168.56.10"],  ]
  },

  :client => {
        :box_name => "generic/ubuntu2204",
        :vm_name => "client",
        :net => [  ["192.168.56.20"],  ]
  }
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

    config.vm.define boxname do |box|
   
      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxconfig[:vm_name]

      box.vm.provider "virtualbox" do |v|
        v.memory = 768
        v.cpus = 1
       end

       if boxconfig[:vm_name] == "client"
        box.vm.provision "ansible" do |ansible|
         ansible.playbook = "ansible/playbook.yml"
         ansible.inventory_path = "ansible/hosts"
         ansible.host_key_checking = "false"
         ansible.limit = "all"
        end
       end

      boxconfig[:net].each do |ipconf|
        box.vm.network("private_network", ip: ipconf[0])
      end

    end
  end
end