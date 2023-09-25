#/bin/bash
CNI_PLUGINS_VERSION="v1.3.0"
CRICTL_VERSION="v1.28.0"
ARCH="amd64"
DEST="/opt/cni/bin"
DOWNLOAD_DIR="/usr/local/bin"
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
RELEASE_VERSION="v0.15.1"