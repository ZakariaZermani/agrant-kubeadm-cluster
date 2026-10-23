#!/usr/bin/env bash
set -euo pipefail

# Tell crictl which runtime socket to talk to
# Without this, crictl guesses -- and often guesses wrong on exam VMs
sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock
# Verify the config was written
cat /etc/crictl.yaml
# Expected output:
# runtime-endpoint: unix:///run/containerd/containerd.sock
# Now crictl runs cleanly -- no warnings, no endpoint guessing
sudo crictl info # JSON dump of runtime details
sudo crictl ps # Running containers (post-bootstrap)
sudo crictl images # Cached images on this node