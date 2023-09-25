# k8s-install
Установка kubernetes кластера на AltLinux
Описание процесса https://dzen.ru/media/aoanima/altlinux-ustanovka-k8s-probuiu-razvernut-single-node-klaster-6508548944eef961f52d527d
Запустить
```
$ install.sh
```
Скачает все необходимые компоненты, установит их, добавит необходимые измнеения в конфиги. Разрешит разворачивать поды на мастер ноде. Запустит кластер. 
Устанавливаемые пакеты:
* ebtables
* socat
* ethtool
* etcd
* conntrack-tools

* cri-o
* cni-plugins
* crictl
* kubeadm
* kubelet
* kubectl

* kube-apiserver
* kube-controller-manager
* kube-scheduler
* kube-proxy
* pause
* coredns
