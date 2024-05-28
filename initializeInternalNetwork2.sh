#!/bin/bash

# Function to calculate network IPs
calculate_network_ip() {
	local ip_cidr="$1"
	local direccion_red
	local mascara
	local partes_ip
	local offset="$2"

	# Dividir la IP y la máscara de red
	IFS="/" read -r direccion_red mascara <<<"$ip_cidr"

	# Dividir la dirección IP en partes
	IFS="." read -r -a partes_ip <<<"$direccion_red"

	# Calcular la dirección de red sumando el offset al último octeto
	local primer_octeto=$((partes_ip[0]))
	local segundo_octeto=$((partes_ip[1]))
	local tercer_octeto=$((partes_ip[2]))
	local cuarto_octeto=$((partes_ip[3]))
	((cuarto_octeto += offset))

	echo "$primer_octeto.$segundo_octeto.$tercer_octeto.$cuarto_octeto"
}

calculate_network_mask() {
	local ip_cidr="$1"
	local mascara_red

	# Dividir la cadena en la barra ("/")
	IFS="/" read -r -a partes <<<"$ip_cidr"

	# Extraer la máscara de red de las partes
	mascara_red="${partes[1]}"

	echo "$mascara_red"
}

# Verify whether the script has enough argument
if [ "$#" -ne 4 ]; then
	echo "Add the following arguments: $0 <network_name> <vlan_id> <network_cdir> <dhcp_range>"
	exit 1
fi

ovs_name="br-int"

# Get parameters from input
network_name="$1"
vlan_id="$2"
network_cdir="$3"
dhcp_range="$4"

# Creating parameters
mask=$(calculate_network_mask $network_cdir)
first_ip="$(calculate_network_ip $network_cdir 1)"
second_ip="$(calculate_network_ip $network_cdir 2)"
dhcp_name="ns-dhcp-vlan${vlan_id}"
veth_name="veth-vlan${vlan_id}"

# Create veth to connect Namespace with OVS
echo "Creating veth interfaces..."
sudo ip link add ${veth_name}-0 type veth peer name ${veth_name}-1

# Create DHCP Namespace
echo "Creating DHCP Namespace \"${dhcp_name}\"..."
sudo ip netns add ${dhcp_name}

# Connect veth to OVS
echo "Conneting veth to OVS..."
sudo ovs-vsctl add-port ${ovs_name} ${veth_name}-0 tag=${vlan_id}

# Connect veth to Namespace
echo "Connecting veth to DHCP Namespace..."
sudo ip link set ${veth_name}-1 netns ${dhcp_name}

# Turn on interfaces
echo "Turning on interfaces..."
ip link set dev ${veth_name}-0 up
sudo ip netns exec ${dhcp_name} ip link set dev lo up
sudo ip netns exec ${dhcp_name} ip link set dev ${veth_name}-1 up

# Add firts IP to veth0 interface
echo "Adding first IP veth-OVS interface..."
ip addr add ${first_ip}/${mask} dev ${veth_name}-0

# Add second IP to DHCP Namespace interface
echo "Adding second IP to Namespace-veth interface..."
sudo ip netns exec ${dhcp_name} ip address add ${second_ip}/${mask} dev ${veth_name}-1

# Config DHCP at DHCP Namespace
echo "Config DHCP Namespace..."
sudo ip netns exec ${dhcp_name} dnsmasq --interface=${veth_name}-1 \
	--dhcp-range=${dhcp_range} --dhcp-option=3,${first_ip} --dhcp-option=6,8.8.8.8,8.8.4.4

echo "Se ha configurado correctamente el entorno para la red ${network_name} con VLAN ID ${vlan_id}."
