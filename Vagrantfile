# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  N = 2
  # Configuration du primary avec pgbackrest
  (1..N).each do |ipfs_cpt|
    config.vm.define "ipfs_#{ipfs_cpt}" do |ipfs|
      ipfs.ssh.insert_key = false
      #postgres_server.vm.box = "debian/bullseye64"
      ipfs.vm.box = "centos/7"
      ipfs.vm.hostname = "ipfs#{ipfs_cpt}"
      ipfs.vm.network :private_network, ip: "192.168.60.1#{ipfs_cpt}"
      ipfs.vm.provider "virtualbox" do |v|
        v.cpus = 2
        v.memory = 1024
      end
    end
  end


  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "provisionning/install_ipfs.yml"
    ansible.compatibility_mode = '2.0'
    ansible.inventory_path = "provisionning/inventory"
  end

end # Vagrant.configure("2") do |config|
