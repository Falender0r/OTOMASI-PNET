#!/bin/bash

# Kode warna untuk umpan balik
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# Variabel Konfigurasi
VLAN_INTERFACE="eth1.11"          # Ganti VLAN menjadi eth1.11
VLAN_ID=11                        # Ganti VLAN ID menjadi 11
IP_ADDR="$IP_Router$IP_Pref"      # IP address untuk interface VLAN di Ubuntu

# Destinasi folder
DHCP_CONF="/etc/dhcp/dhcpd.conf"
NETPLAN_CONF="/etc/netplan/01-netcfg.yaml"
DDHCP_CONF="/etc/default/isc-dhcp-server"
SYSCTL_CONF="/etc/sysctl.conf"

# IP PNETLAB
IPNET="192.168.74.137"
# IP default perangkat
IPU="192.168.11.1"
IPROUTE_ADD="192.168.200.1/24"

# MikroTik
MIKROTIK_IP="192.168.200.1"
MIKROTIK_S="192.168.200.0"
MPORT="30014"

# Cisco
SPORT="30013"

# Konfigurasi IP Yang Anda Inginkan
IP_A="11"
IP_B="200"
IP_C="2"
IP_BC="255.255.255.0"
IP_Subnet="192.168.$IP_A.0"
IP_Router="192.168.$IP_A.1"
IP_Range="192.168.$IP_A.$IP_C 192.168.$IP_A.$IP_B"
IP_DNS="8.8.8.8, 8.8.4.4"
IP_Pref="/24"

# FIX DHCP
IP_FIX="192.168.11.10"
IP_MAC="00:50:79:66:68:03"

# Fungsi untuk memeriksa status exit
check_status() {
    local custom_message="$1"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Terjadi kesalahan ketika ${custom_message}!${RESET}"
        exit 1
        sleep 3
    else
        echo -e "${GREEN}✅ Perintah ${custom_message} berhasil dijalankan!${RESET}"
        sleep 3
    fi
}

check_akhir() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Terjadi kesalahan pada OTOMASI, Cobalah Lagi!${RESET}"
        exit 1
    else
        echo -e "${GREEN}✅ OTOMASI Telah Berhasil Dilakukan!${RESET}"
    fi
}

set -e

# Menampilkan pesan awal
clear
cat << EOF

   ___ _____ ___  __  __   _   ___ ___  
  / _ \_   _/ _ \|  \/  | /_\ / __|_ _| 
 | (_) || || (_) | |\/| |/ _ \\__ \| |  
  \___/ |_| \___/|_|  |_/_/ \_\___/___| 
   ___ _   ___ ___ ___
  | __/_\ | _ \_ _/ __|
  | _/ _ \|   /| |\__ \
  |_/_/ \_\_|_\___|___/

EOF
sleep 5
echo "Inisialisasi awal ..."

# Menambahkan repositori Kartolo
echo "Menambahkan repositori Kartolo..."
cat <<EOF | sudo tee /etc/apt/sources.list > /dev/null
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF
check_status "Menambahkan Repositori"

# Update dan instal paket yang diperlukan
echo "Mengupdate daftar paket dan menginstal paket yang diperlukan..."
sudo apt-get update -y > /dev/null
check_status "Update Repositori"

sudo apt-get install -y isc-dhcp-server expect > /dev/null
check_status "Menginstall Package Yang Diperlukan"

# Konfigurasi Pada Netplan
echo "Mengonfigurasi Netplan..."
cat <<EOF | sudo tee $NETPLAN_CONF > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1:
      dhcp4: no
  vlans:
     eth1.11:
       id: 11
       link: eth1
       addresses: [$IP_Router$IP_Pref]
EOF
check_status "Konfigurasi Netplan"

# Terapkan konfigurasi Netplan
echo "Menerapkan konfigurasi Netplan..."
sudo netplan apply
check_status "Menerapkan Netplan"

# Konfigurasi DHCP SERVER
echo "Menerapkan konfigurasi isc-dhcp-server..."
cat <<EOL | sudo tee $DHCP_CONF > /dev/null
subnet $IP_Subnet netmask $IP_BC {
    range $IP_Range;
    option routers $IP_Router;
    option subnet-mask $IP_BC;
    option domain-name-servers $IP_DNS;
    default-lease-time 600;
    max-lease-time 7200;
}

host fantasia {
    hardware ethernet $IP_MAC;
    fixed-address $IP_FIX;
}
EOL
echo "INTERFACESv4=\"$VLAN_INTERFACE\"" | sudo tee $DDHCP_CONF > /dev/null
check_status "Konfigurasi isc-dhcp-service"

# Mengaktifkan IP forwarding dan inisialisasi IPTables
echo "Mengaktifkan IP forwarding dan mengonfigurasi IPTables..."
sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null
echo "net.ipv4.ip_forward=1" | sudo tee -a $SYSCTL_CONF > /dev/null
check_status "IP Forwarding"

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE > /dev/null
sudo iptables -A OUTPUT -p tcp --dport $SPORT -j ACCEPT > /dev/null
sudo iptables -A OUTPUT -p tcp --dport $MPORT -j ACCEPT > /dev/null
check_status "Konfigurasi Firewall"

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent > /dev/null
sudo netfilter-persistent save > /dev/null
check_status "Instalisasi iptables-Persistent"

# Konfigurasi Cisco dan Mikrotik
echo "Melakukan Konfigurasi Untuk Cisco..."
./ciscotomasi.sh
check_status "Konfigurasi Cisco"

echo "Melakukan Konfigurasi Untuk Mikrotik..."
./miktomasi.sh
check_status "Konfigurasi Mikrotik"

# Routing Ubuntu dan Mikrotik
echo "Melakukan Routing Ubuntu Ke Mikrotik..."
sudo ip route add 192.168.200.0/24 via 192.168.11.2
check_status "Routing Ubuntu dan Mikrotik"

# Restart DHCP Server
echo "Restart DHCP Server..."
sudo systemctl restart isc-dhcp-server
check_status "Restart isc-dhcp-server"

# Akhir
check_akhir
clear
