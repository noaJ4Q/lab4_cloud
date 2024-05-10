#!/bin/bash

# Verify whether the script has enough arguments
if [ "$#" -ne 2 ]; then
	echo "Add the following arguments: $0 <vlan_id_1> <vlan_id_2>"
	exit 1
fi

# Obtener parámetros de entrada
vlan_id_1="$1"
vlan_id_2="$2"

# Crear reglas de iptables para el enrutamiento entre las dos redes VLAN
# sudo iptables -I FORWARD -o ${vlan_id_1} -i ${vlan_id_2} -j ACCEPT
# sudo iptables -I FORWARD -o ${vlan_id_2} -i ${vlan_id_1} -j ACCEPT

echo "Rules to connect VLAN ${vlan_id_1} and VLAN ${vlan_id_2} added"
