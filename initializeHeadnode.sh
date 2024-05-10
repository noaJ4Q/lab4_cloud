#!/bin/bash

# Verify whether the script has enough arguments
if [ "$#" -lt 2 ]; then
	echo "Add the following arguments: $0 <ovs_name> <interface> [<interface2> ...]"
	exit 1
fi

# Get OVS name and interfaces from arguments
ovs_name="$1"
shift
interfaces=("$@")

# Create OVS
echo "Creating OVS..."
sudo ovs-vsctl add-br "$ovs_name"

# Connect interfaces to OVS
for interface in "${interfaces[@]}"; do
	echo "Adding interface \"$interface\" to OVS..."
	sudo ovs-vsctl add-port "$ovs_name" "$interface"
done

# Start OVS
echo "Starting OVS..."
sudo ip link set dev ${ovs_name} up

# Enable IPv4 Forwarding
echo "Enabling IPv4 Forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null

# Change default action from FORWARD chain to DROP
echo "Changing default action in iptables..."
sudo iptables -P FORWARD DROP

echo "OVS \"$ovs_name\" has been successfully created and the interfaces has been successfully added."
