
#!/usr/bin/env bash
set -euo pipefail

# Install the Cilium CLI
CILIUM_CLI_VERSION=$(curl -fsSL https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}


# Install Cilium
cilium install \
  --kubeconfig /home/vagrant/.kube/config \
  --version 1.20.3 \
  --set k8sServiceHost=192.168.56.10 \
  --set k8sServicePort=6443 \
  --wait
cilium status \
  --kubeconfig /home/vagrant/.kube/config \
  --wait \
  --wait-duration 10m
