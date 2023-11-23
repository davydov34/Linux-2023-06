
Vagrant.configure("2") do |config|

  config.vm.box = "davydov34/KS"
  config.vm.box_version = "1"
 
  config.vm.define "ubuntu1804"

  config.vm.box_check_update = false

  config.vm.network "public_network"

  config.ssh.username = 'vagrant'
  config.ssh.password = 'vagrant'
  config.ssh.insert_key = false

  config.vm.provider "virtualbox" do |vb|
     vb.gui = false
     vb.name = "ubuntu1804"
     vb.cpus = "2"
     vb.memory = "1024"
  end

  config.vm.provision "shell", inline: $script

end

$script = <<-SHELL
     sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
     systemctl restart sshd.service
SHELL
