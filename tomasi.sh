#!/bin/bash

# Kode warna
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# Menampilkan Nama dengan Figlet
echo -e "${GREEN}"
figlet "OTOMASI FARIS FARASDAK"
echo -e "${RESET}"

# Variabel Konfigurasi
VLAN_INTERFACE="eth1.11"
VLAN_ID=11
IP_ROUTER="192.168.11.1"
IP_RANGE_START="192.168.11.10"
IP_RANGE_END="192.168.11.100"
NETMASK="255.255.255.0"
DNS="8.8.8.8, 8.8.4.4"
DHCP_CONF="/etc/dhcp/dhcpd.conf"
DEFAULT_DHCP="/etc/default/isc-dhcp-server"

echo -e "${YELLOW}Mengatur VLAN Interface...${RESET}"
# Konfigurasi VLAN
ip link add link eth1 name $VLAN_INTERFACE type vlan id $VLAN_ID
ip addr add $IP_ROUTER/24 dev $VLAN_INTERFACE
ip link set dev $VLAN_INTERFACE up

# Instal DHCP Server
echo -e "${YELLOW}Menginstal DHCP Server...${RESET}"
apt update && apt install -y isc-dhcp-server

# Konfigurasi DHCP Server
echo -e "${YELLOW}Mengatur konfigurasi DHCP...${RESET}"
cat <<EOF > $DHCP_CONF
subnet 192.168.11.0 netmask $NETMASK {
    range $IP_RANGE_START $IP_RANGE_END;
    option routers $IP_ROUTER;
    option domain-name-servers $DNS;
}
EOF

echo -e "${YELLOW}Mengatur interface DHCP...${RESET}"
echo "INTERFACESv4=\"$VLAN_INTERFACE\"" > $DEFAULT_DHCP

# Restart DHCP Server
systemctl restart isc-dhcp-server
systemctl enable isc-dhcp-server

# Aktifkan IP Forwarding
echo -e "${YELLOW}Mengaktifkan IP Forwarding...${RESET}"
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

echo -e "${GREEN}Konfigurasi VLAN 11 dan DHCP selesai.${RESET}"
