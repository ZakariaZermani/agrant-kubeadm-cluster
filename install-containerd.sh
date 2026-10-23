#!/usr/bin/env bash
set -euo pipefail

# Install containerd (Ubuntu example)
sudo apt-get update
sudo apt-get install -y containerd
# Generate default configuration
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
# Align cgroup driver -- #1 CAUSE OF kubeadm init FAILURES
# SystemdCgroup = true MUST match kubelet's driver (systemd on modern Linux)
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml
# Restart containerd to apply config
sudo systemctl restart containerd
sudo systemctl enable containerd
# Install crictl from the upstream cri-tools release
CRICTL_VERSION="v1.32.0"
CRICTL_ARCH="$(dpkg --print-architecture)"
CRICTL_TMP="$(mktemp -d)"
trap 'rm -rf "$CRICTL_TMP"' EXIT
sudo apt-get install -y curl
curl -fsSL \
  "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${CRICTL_ARCH}.tar.gz" \
  -o "${CRICTL_TMP}/crictl.tar.gz"
tar -xzf "${CRICTL_TMP}/crictl.tar.gz" -C "${CRICTL_TMP}" crictl
sudo install -m 0755 "${CRICTL_TMP}/crictl" /usr/local/bin/crictl
# Configure crictl to use containerd's CRI socket
sudo tee /etc/crictl.yaml >/dev/null <<'EOF'
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
# Verify container runtime + CRI endpoint
systemctl status containerd # Service should be active (running)
sudo crictl info # Confirms CRI is working and shows runtime details