#/bin/bash
CNI_PLUGINS_VERSION="v1.3.0"
CRICTL_VERSION="v1.28.0"
ARCH="amd64"
DEST="/opt/cni/bin"
DOWNLOAD_DIR="/usr/local/bin"
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
RELEASE_VERSION="v0.15.1"

sudo mkdir -p "$DOWNLOAD_DIR"
sudo mkdir -p "$DEST"
sudo apt-get update && sudo apt-get install -y ebtables socat ethtool etcd conntrack-tools 

sudo mkdir /var/run/crio
sudo mkdir /var/log/crio

wget "https://storage.googleapis.com/cri-o/artifacts/cri-o.amd64.v1.28.1.tar.gz"  | sudo tar -C "./" -xz
ls -l
cd ./cri-o && sudo ./install

CRIOVER=$(crio version)
if [[ "$CRIOVER"  =~ .*"1.28.1".*  ]] ; then  
    echo "CRI-O Установлен: 1.28.1"
else 
    echo "$?"
    echo "CRIOVER = $CRIOVER"
    echo "CRI-O Не Установлен"
    exit 1
fi

echo "Установим сетевой плагин cni-plugins"
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" | sudo tar -C "$DEST" -xz

echo "Установим crictl"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz




echo  "установим kubeadm,kubelet"
cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet} 
sudo chmod +x {kubeadm,kubelet}

sudo curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service

sudo mkdir -p /etc/systemd/system/kubelet.service.d

sudo curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "устпановим kubectl"
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "Конфигурируем сеть"
# sudo install -o root -g root -m 0755 cri-o /usr/local/bin/

cat <<EOF | sudo tee /etc/sysctl.d/98-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo sysctl net.bridge.bridge-nf-call-ip6tables=1
sudo modprobe overlay
sudo modprobe br_netfilter
sudo sysctl --system
echo "Запускаем службы cri-o"
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl status crio
CRIOSTATUS=$(systemctl is-active crio)
if [[ "$CRIOSTATUS"  =~ .*"active".*  ]] ; then
    echo "CRI-O зпущен!"
fi

echo "Установим системные контейнеры"
sudo kubeadm config images pull

echo "разрешить разворачивать Pods на мастер ноде"
sudo kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "Инициализируем k8s"
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
echo "Применим сетевой драйвер"
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

