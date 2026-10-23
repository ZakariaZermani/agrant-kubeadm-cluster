#!/usr/bin/env bash
set -euo pipefail

# Load required kernel modules (runtime)
sudo modprobe overlay # Required for container image layers (containerd)
sudo modprobe br_netfilter # Allows iptables to see bridged traffic
# Persist modules across reboots
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
# Configure sysctl networking parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1 # Enable packet forwarding between interfaces
net.bridge.bridge-nf-call-iptables = 1 # Ensure bridged traffic hits iptables
# net.bridge.bridge-nf-call-ip6tables = 1 # Optional (IPv6 environments)
EOF
# Apply sysctl settings immediately
sudo sysctl --system
# Quick verification
lsmod | grep -E 'overlay|br_netfilter' # Modules loaded
sysctl net.ipv4.ip_forward # Should return = 1