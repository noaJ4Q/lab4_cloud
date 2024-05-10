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

# Create internal interface at OVS with VLAN ID
echo "Creating internal interface \"$network_name\" at OVS..."
sudo ovs-vsctl add-port ${ovs_name} ${network_name} tag=${vlan_id} -- set interface ${network_name} type=internal

# Get first and second network IP
first_ip=$(calculate_network_ip $network_cdir 1)
second_ip=$(calculate_network_ip $network_cdir 2)
mask=$(calculate_network_mask $network_cdir)

# Add firts network IP to internal interface
echo "Adding first IP to internal interface..."
ip addr add ${first_ip}/${mask} dev ${network_name}
ip link set ${network_name} up

# Create DHCP Namespace
echo "Creating DHCP Namespace \"ns-dhcp-vlan-${vlan_id}\"..."
sudo ip netns add ns-dhcp-vlan-${vlan_id}

# Connect DHCP Namespace to OVS with internal interface
echo "Connecting DHCP Namespace to OVS with internal interface..."
sudo ip link set ${network_name} netns ns-dhcp
sudo ip netns exec ns-dhcp ip link set dev lo up
sudo ip netns exec ns-dhcp ip link set dev ${network_name} up

# Add second network IP to DHCP Namespace
echo "Adding second IP to DHCP Namespace..."
sudo ip netns exec ns-dhcp ip address add ${second_ip}/${mask} dev ${network_name}

# Config DHCP at DHCP Namespace
echo "Config DHCP Namespace..."
sudo ip netns exec ns-dhcp dnsmasq --interface=${network_name} \
	--dhcp-range=${dhcp_range} --dhcp-option=3,${first_ip} --dhcp-option=6,8.8.8.8,8.8.4.4

echo "Se ha configurado correctamente el entorno para la red ${network_name} con VLAN ID ${vlan_id}."
