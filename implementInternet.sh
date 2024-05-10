#!/bin/bash

# Verify whether the script has enough arguments
if [ "$#" -ne 1 ]; then
	echo "Add the following argument: $0 <vlan_id>"
	exit 1
fi

# Obtener parámetro de entrada
vlan_id="$1"

# Añadir reglas de iptables para permitir que la VLAN obtenga acceso a Internet
# sudo iptables -t nat -A POSTROUTING -s 192.168.${vlan_id}.0/24 -o eth0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING ... -j MASQUERADE

echo "Se han añadido las reglas de iptables para permitir que la VLAN ${vlan_id} obtenga acceso a Internet."
