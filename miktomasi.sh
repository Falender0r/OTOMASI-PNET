#!/bin/bash
# MIKROTIK Configuration

IPNET="192.168.74.137"
MIKROTIK_IP="192.168.200.11"   # IP MikroTik lama (disesuaikan dengan absen 11)
MIKROTIK_S="192.168.200.0"     # Subnet IP MikroTik
MPORT="30003"                  # Port Telnet

# Konfigurasi MikroTik via Telnet
expect << EOF > /dev/null
spawn telnet $IPNET $MPORT
expect "Mikrotik Login:"
send "admin\r"

expect "Password:"
send "\r"

# Ubah password
expect ">"
send "n\r"
expect "new password"
send "123\r"
expect "retype new password"
send "123\r"

# Menambahkan VLAN 11 pada ether1
expect ">"
send "/interface vlan add name=VLAN11 vlan-id=11 interface=ether1\r"

# Memberikan IP Address pada VLAN11
expect ">"
send "/ip address add address=192.168.11.2/24 interface=VLAN11\r"

# Menambahkan default route menuju Ubuntu Server (gateway)
expect ">"
send "/ip route add dst-address=0.0.0.0/0 gateway=192.168.11.1\r"

# Menambahkan NAT untuk akses internet jika diperlukan
expect ">"
send "/ip firewall nat add chain=srcnat out-interface=ether2 action=masquerade\r"

# Mengatur DNS
expect ">"
send "/ip dns set servers=8.8.8.8,8.8.4.4\r"

# Save konfigurasi
expect ">"
send "/system reboot\r"
expect "Do you want to reboot"
send "y\r"

expect eof
EOF

echo "Konfigurasi MikroTik selesai via Telnet."
