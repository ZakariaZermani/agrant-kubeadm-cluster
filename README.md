# Kubernetes Cluster with Vagrant and kubeadm

## Introduction

This repository automates the creation of a small Kubernetes cluster using Vagrant, VirtualBox, kubeadm, and Ansible. It provisions one control-plane VM and two worker VMs, configures containerd and the Kubernetes components, bootstraps the cluster, joins the workers, and installs Cilium for pod networking.

The repository is intended as a repeatable, hands-on lab for learning and practicing how a kubeadm-based Kubernetes cluster is assembled and operated. It can also be used to test Kubernetes configuration and basic cluster administration in isolated local VMs. It is a learning and development environment, not a production-ready cluster setup.

## Cluster overview

The cluster consists of three Ubuntu VMs:

| VM | Role | Private IP |
| --- | --- | --- |
| `control-plane` | Kubernetes control plane | `192.168.56.10` |
| `worker1` | Worker node | `192.168.56.11` |
| `worker2` | Worker node | `192.168.56.12` |

The VMs are prepared with containerd, kubelet, kubeadm, and kubectl. Ansible then initializes the control plane, joins both workers to the cluster, and installs Cilium as the CNI.

## Prerequisites

The host machine needs:

- [Vagrant](https://developer.hashicorp.com/vagrant/install)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) as the Vagrant provider
- Ansible, with `ansible-playbook` available in `PATH`
- Internet access from the host and VMs to download packages, container images, and Cilium

The VMs use the `bento/ubuntu-24.04` box. Vagrant downloads it on the first start if it is not already available.

## Project files

- `Vagrantfile` – VM definitions and provisioners
- `init.yaml` – kubeadm configuration; Vagrant makes it available inside the VMs at `/vagrant/init.yaml`
- `initialize-control-plane.yml` – initializes the control plane, generates a fresh worker join command, and joins the workers
- `kernel-modules-sysctl-networking.sh` – loads required kernel modules and configures networking parameters
- `install-containerd.sh` – installs and configures containerd and crictl
- `configure-crictl.sh` – configures the CRI endpoint for crictl
- `install-kubeadm-kubectl-kubelet.sh` – installs Kubernetes tools
- `cilium_installation.sh` – installs the Cilium CLI and Cilium

The shell scripts are executable and run on the VMs as Vagrant provisioners.

## Start the cluster

Run this from the project directory:

```bash
vagrant up
```

The worker VMs are defined before the control plane in the `Vagrantfile`. A full `vagrant up` therefore starts `worker1` and `worker2` first, followed by the control plane. Vagrant then runs Ansible and installs Cilium from the control-plane VM.

Ansible needs all three VMs to be running. If the VMs already exist but are stopped, start them in order:

```bash
vagrant up worker1
vagrant up worker2
vagrant up control-plane
```

## Check status and access the VMs

Show VM status:

```bash
vagrant status
```

Connect to the control-plane VM:

```bash
vagrant ssh control-plane
```

The Ansible playbook creates `/home/vagrant/.kube/config` on the control plane. Use it there to inspect the cluster:

```bash
vagrant ssh control-plane -c 'kubectl get nodes -o wide'
vagrant ssh control-plane -c 'kubectl get pods -A'
vagrant ssh control-plane -c 'cilium status'
```

All three nodes should report `Ready`, and Cilium should report `Cilium: OK`.

## Control the cluster from another machine

The kubeconfig on the control plane contains credentials and connection details for the Kubernetes API. Copy it to the client machine with `scp`, then point `kubectl` at that file.

Run these commands on the client machine from the project directory, while the VMs are running:

```bash
mkdir -p ~/.kube/configs
scp -i .vagrant/machines/control-plane/virtualbox/private_key \
  vagrant@192.168.56.10:~/.kube/config \
  ~/.kube/configs/vagrant-cluster-admin.conf
chmod 600 ~/.kube/configs/vagrant-cluster-admin.conf
kubectl --kubeconfig ~/.kube/configs/vagrant-cluster-admin.conf get nodes
```

What each command does:

- `mkdir -p` creates the local destination directory if it does not already exist.
- `scp -i ...` uses Vagrant's private SSH key to securely copy `/home/vagrant/.kube/config` from the control-plane VM.
- `chmod 600` restricts access to the copied kubeconfig to its owner.
- `kubectl --kubeconfig ...` tells kubectl to use this specific configuration file instead of the default `~/.kube/config`.

The kubeconfig grants administrator access to the cluster. Keep it private and do not commit or share it. The client machine must also be able to reach `192.168.56.10` over the Vagrant private network.

The kubeconfig uses the API endpoint `zk.lab:6443`. The client machine must resolve `zk.lab` to `192.168.56.10` for kubectl to connect. Add this entry to the client machine's hosts file if it does not already resolve:

```text
192.168.56.10 zk.lab
```

On macOS and Linux, the hosts file is `/etc/hosts`.

## Re-run provisioners

All three VMs must be running before Ansible can connect to the workers. To run only the Ansible provisioner:

```bash
vagrant provision control-plane --provision-with ansible
```

To run only the Cilium provisioner:

```bash
vagrant provision control-plane --provision-with install-cilium
```

## Stop and destroy the cluster

Stop the VMs:

```bash
vagrant halt
```

**Warning:** The following command destroys the VMs and their local cluster data:

```bash
vagrant destroy
```
