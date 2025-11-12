#!/bin/bash
#
# Setup del Master Node
#

set -euxo pipefail

MASTER_IP="192.168.56.10"
POD_CIDR="10.244.0.0/16"

echo "Inicializando Kubernetes Master..."

# Inicializar cluster con kubeadm
sudo kubeadm init \
  --apiserver-advertise-address=$MASTER_IP \
  --pod-network-cidr=$POD_CIDR \
  --node-name k8s-master

# Configurar kubectl para usuario vagrant
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

# Guardar join command para workers
kubeadm token create --print-join-command > /vagrant/join-command.sh
chmod +x /vagrant/join-command.sh

# Instalar Calico (CNI plugin para networking)
echo "Instalando Calico CNI..."
kubectl --kubeconfig=/home/vagrant/.kube/config apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Instalar Helm
echo "Instalando Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Instalar metrics-server
echo "Instalando metrics-server..."
kubectl --kubeconfig=/home/vagrant/.kube/config apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch para metrics-server (necesario en ambientes locales)
kubectl --kubeconfig=/home/vagrant/.kube/config patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "Master node setup completado"
echo "Workers pueden unirse usando: /vagrant/join-command.sh"