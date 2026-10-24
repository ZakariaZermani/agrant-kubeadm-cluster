# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e
    swapoff -a
  SHELL

  config.vm.provision "shell", path: "kernel-modules-sysctl-networking.sh"
  config.vm.provision "shell", path: "install-containerd.sh"
  config.vm.provision "shell", path: "configure-crictl.sh"
  config.vm.provision "shell", path: "install-kubeadm-kubectl-kubelet.sh"




  config.vm.define "worker1" do |node|
    node.vm.hostname = "worker1"
    node.vm.network "private_network", ip: "192.168.56.11"
  end

  config.vm.define "worker2" do |node|
    node.vm.hostname = "worker2"
    node.vm.network "private_network", ip: "192.168.56.12"
  end

  config.vm.define "control-plane" do |node|
    node.vm.hostname = "control-plane"
    node.vm.network "private_network", ip: "192.168.56.10"

    #
    # Run Ansible from the Vagrant Host
    #
    node.vm.provision "ansible" do |ansible|
      ansible.playbook = "initialize-control-plane.yml"
      ansible.limit = "all"
    end

    node.vm.provision "shell",
      name: "install-cilium",
      path: "cilium_installation.sh"
  end
end