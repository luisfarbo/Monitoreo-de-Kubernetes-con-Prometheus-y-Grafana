#!/bin/bash
#
# Setup del Load Balancer (HAProxy)
#

set -euxo pipefail

# Instalar HAProxy
sudo apt-get update
sudo apt-get install -y haproxy

# Configurar HAProxy
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

# Frontend para la aplicación
frontend app_frontend
    bind *:80
    default_backend app_backend

# Backend para los workers
backend app_backend
    balance roundrobin
    server worker1 192.168.56.21:30080 check
    server worker2 192.168.56.22:30080 check

# Frontend para Kubernetes API
frontend k8s_api_frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend k8s_api_backend

# Backend para el master API
backend k8s_api_backend
    mode tcp
    balance roundrobin
    server master 192.168.56.10:6443 check

# Stats para monitoreo del LB
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats auth admin:password
EOF

# Reiniciar HAProxy
sudo systemctl restart haproxy
sudo systemctl enable haproxy

echo "Load Balancer configurado exitosamente"
echo "Stats disponible en: http://192.168.56.100:8404/stats"