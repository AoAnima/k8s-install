
CNI_PLUGINS_VERSION="v1.3.0"
CRICTL_VERSION="v1.28.0"
ARCH="amd64"
DEST="/opt/cni/bin"
DOWNLOAD_DIR="/usr/local/bin"
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
RELEASE_VERSION="v0.15.1"
source "./info.sh"

лог "Проверим и установим нужные пакеты"
statusRpm=$(rpm -qa ebtables socat ethtool etcd conntrack-tools | wc -l)
if [[ "$statusRpm"  =~ .*"0".*  ]] ; then
    sudo mkdir -p "$DOWNLOAD_DIR"
    sudo mkdir -p "$DEST"
    sudo apt-get update && sudo apt-get install -y ebtables socat ethtool etcd conntrack-tools 
fi
if [[ ! -d "/var/run/crio" ]]; then
    sudo mkdir /var/run/crio
    sudo mkdir /var/log/crio
fi



CRIOVER=$(crio version)
if [[ "$CRIOVER"  =~ .*"1.28.1".*  ]] ; then  
    инфо "CRI-O Установлен: 1.28.1"
else 
    ошибка "CRI-O Не Установлен"
    лог "Установим CRI-O"
    wget "https://storage.googleapis.com/cri-o/artifacts/cri-o.amd64.v1.28.1.tar.gz"  | sudo tar -C "./" -xz   
    cd ./cri-o && sudo ./install
fi

if [[ $(ls -l "$DEST" | wc -l) < 0   ]] ; then
    лог "Установим сетевой плагин cni-plugins"
    curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" | sudo tar -C "$DEST" -xz
fi

if [[ ! $(crictl -v)  =~ .*"v1.28.0".*  ]] ; then
    лог "Установим crictl"
    curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz
else
    инфо "crictl установлен"
fi


if [[ ! $(kubeadm version -o=short) =~ .*"v1.28.2".*  ]] ; then
    лог  "установим kubeadm,kubelet"
    cd $DOWNLOAD_DIR
    sudo curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet} 
    sudo chmod +x {kubeadm,kubelet}
    sudo curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
    sudo mkdir -p /etc/systemd/system/kubelet.service.d

    sudo curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

else 
    инфо "kubeadm,kubelet установлен"
fi

if [[ ! $(kubectl version) =~ .*"v1.28.2".*  ]] ; then
    лог "устпановим kubectl"
    sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    sudo chmod +x /usr/local/bin/kubectl
    sudo chmod +x /usr/bin/kubectl

else
    инфо "kubectl установлен"
fi


if [[ ! $(sudo sysctl net.bridge.bridge-nf-call-iptables)  =~ .*"1".*  ]] ; then
    лог "Конфигурируем сеть"
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
    sudo systemctl daemon-reload
else
    инфо "Сеть конфигурирована"
fi






CRIOSTATUS=$(systemctl is-active crio)
if [[ "$CRIOSTATUS"  =~ .*"active".*  ]] ; then
    инфо "CRI-O зпущен!"
else
    лог "Запускаем службы cri-o"
    sudo systemctl enable crio --now
fi


function checkSystemPods(){
    requiredPods=(
        pod/registry
        pod/coredns
        pod/etcd
        pod/kube-apiserver
        pod/kube-controller-manager
        pod/kube-proxy
        pod/kube-scheduler
    )

    runningPods=$(kubectl get pods -A -o=name)
    count=0
    for pod in $runningPods; do
        for reqPod in "${requiredPods[@]}"; do      
            if [[ "$pod" =~ .*"$reqPod".* ]]; then
                echo "под $pod запущен $reqPod"
                ((count++))
            fi    
        done   
    done
    if [[ "$count" -ge "${#requiredPods[@]}" ]]; then
        инфо "Все системные поды установленны"
    else
        лог "Установим системные контейнеры, может долго висеть."
        sudo kubeadm config images pull
    fi
}

checkSystemPods


function ПроверитьСтатусНоды(){
   
    nodeRoles=;(kubectl describe "$(kubectl get node -o name)" | grep -E 'Taints:' | awk -F 'Taints:' '{print $2}' | tr -d ' ')
    if [[ "$nodeRoles" = "node-role.kubernetes.io/control-plane:NoSchedule"  ]] ; then
     лог "разрешить разворачивать Pods на мастер ноде"
         kubectl taint nodes --all node-role.kubernetes.io/control-plane-
    #    node/test-maksimchuk.mfsk.int untainted
    else
        инфо "Нода имеет корректный taints"
    fi

 }

ПроверитьСтатусНоды


if [[ ! $(kubectl get nodes -l node-role.kubernetes.io/control-plane) =~ .*"Ready".* ]]; then
    лог "Инициализируем k8s"
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    # Your Kubernetes control-plane has initialized successfully!
    лог "Применим сетевой драйвер"
    sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

    mkdir -p $HOME/.kube
    echo "y" | sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
else
    инфо "Мастер нода инициализирвана"
fi



function СоздатьПодРеестра() {
    registryStatus=$(kubectl apply -f ../registry/registry.yaml)
    if [[ "$registryStatus"  =~ .*"created".* || "$registryStatus"  =~ .*"unchanged".* || "$registryStatus"  =~ .*"configured".* ]] ; then
        инфо "под реестр создан, "
        лог "получим имя присвоенное поду"
        registryName=$(kubectl get pods -l app=registry -o custom-columns=:metadata.name --no-headers)
        лог "Имя пода: $registryName"
        registry=$(kubectl get pod "$registryName" -o jsonpath='{.status.phase}')
        лог "Статус  пода: $registry"
        if [[ "$registry"  =~ .*"Running".*  ]] ; then
            инфо "под реестр запущен! пробуем подключиться и получить каталог образов"
            catalog=$(curl -X GET http://localhost:30000/v2/_catalog)
  
            if [[ "$catalog"  =~ .*'{"repositories":[]}'.*  ]] ; then
                лог "Репозиторий работает"
                инфо -e "Настройка завершена"

                echo -e "\033[44m  \033[33m Необходимо установить систему сборки контейнеров, рекоменддуется kaniko: для этого нужно либо собрать из исходников, либо скачать бинарный файл, либо использовать контейнер для k8s. \033[0m"

                echo -e "\033[42m \033[30m В контексте текущего репозитория kaniko уже скомпилирован и должен находится в папку /kaniko, проверим и попытаемся установить \033[0m"
            else
                ошибка "Не удаётся подключиться к реестру"
            fi

        else
            ошибка "под реестр не запущен"
        fi
        
    else
        ошибка "под реестр не создан"
    fi
}

# kubectl describe -f ../registry/volumes.yaml |  grep -oE 'Status:\s.*|Name:\s.*' | awk 'BEGIN { FS=": *"; ORS="\n" } { if ($1 == "Name") name=$2; else if ($1 == "Status") print name,"=", $2 
# }'
function ПроверитьТома() {
 volumeStatus=$(kubectl apply -f ../registry/volumes.yaml)
if [[ "$volumeStatus"  =~ .*"created".* || "$volumeStatus"  =~ .*"unchanged".* || "$volumeStatus"  =~ .*"configured".* ]] ; then
    инфо "volumes созданы"
    лог "Создадим под реестра"
    СоздатьПодРеестра
else
    ошибка "volumes не созданы, проверь логи. $volumeStatus"
    exit 1
fi
}

ПроверитьТома


function УстановитьKaniko (){

if [[ -d "../kaniko" ]]; then

    sudo install -o root -g root -m 0777 ../kaniko/build /usr/local/bin/build
    инфо "Kaniko успешно установлен"

fi
    
}
 УстановитьKaniko
