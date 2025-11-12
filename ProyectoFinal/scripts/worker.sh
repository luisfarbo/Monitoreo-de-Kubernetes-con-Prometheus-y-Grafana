#!/bin/bash
#
# Setup de Worker Nodes
#

set -euxo pipefail

echo "Esperando a que el master genere join command..."

# Esperar hasta que el archivo exista
while [ ! -f /vagrant/join-command.sh ]; do
  sleep 5
done

echo "Join command encontrado, uniéndose al cluster..."

# Unirse al cluster
sudo bash /vagrant/join-command.sh

echo "Worker node unido al cluster exitosamente"