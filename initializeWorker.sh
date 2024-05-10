#!/bin/bash

# Verify whether the script has enough arguments
if [ "$#" -lt 2 ]; then
	echo "Add the following arguments: $0 <ovs_name> <interface1> [<interface2> ...]"
	exit 1
fi

# Get OVS name and interfaces from arguments
ovs_name="$1"
shift
interfaces=("$@")

# Create OVS
echo "Creating OVS..."
sudo ovs-vsctl add-br "$ovs_name"
echo "Starting OVS..."
sudo ip link set dev ${ovs_name} up

# Connect interfaces to OVS
for interface in "${interfaces[@]}"; do
	echo "Adding interface \"$interface\" to OVS..."
	sudo ovs-vsctl add-port "$ovs_name" "$interface"
done

echo "OVS \"$ovs_name\" has been successfully created and the interfaces has been successfully added."
