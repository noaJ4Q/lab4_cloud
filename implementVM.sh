#!/bin/bash

# Verificar si se proporcionan suficientes argumentos
if [ "$#" -ne 4 ]; then
	echo "Add the following arguments: $0 <vm_name> <ovs_name> <vlan_id> <vnc_port>"
	exit 1
fi

# Obtener parámetros de entrada
vm_name="$1"
ovs_name="$2"
vlan_id="$3"
vnc_port="$4"

# Crear una interfaz TAP para la VM
echo "Creating TAP interface..."
tap_interface="$vm_name"-tap
sudo ip tuntap add mode tap ${tap_interface}

# Create VM
echo "Creating VM..."
qemu-system-x86_64 \
	-enable-kvm \
	-vnc 0.0.0.0:${vnc_port} \
	-netdev tap,id=${tap_interface},ifname=${tap_interface},script=no,downscript=no \
	-device e1000,netdev=${tap_interface},mac=20:20:32:48:00:0${vnc_port} \
	-daemonize \
	-snapshot \
	cirros-0.5.1-x86_64-disk.img

# Connect TAP interface to OVS
echo "Connecting TAP interface to OVS..."
sudo ovs-vsctl add-port ${ovs_name} ${tap_interface} tag=${vlan_id}

# Start TAP interface
echo "Start TAP interface..."
sudo ip link set dev ${tap_interface} up

echo "VM \"$vm_name\" has been successfully created and connected to OVS \"$ovs_name\"."
