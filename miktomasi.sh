#!/bin/bash
# MIROKTIK
IPNET="192.168.74.137"
MIKROTIK_IP="192.168.200.1"  # IP MikroTik yang baru
MIKROTIK_S="192.168.200.0"
MPORT="30014"

expect << EOF > /dev/null
spawn telnet $IPNET $MPORT
expect "Mikrotik Login:"
send "admin\r"

expect "Password:"
send "\r"

expect ">"
send "n"

expect "new password"
send "123\r"

expect "repeat new password"
send "123\r"

expect ">"

# Menambahkan alamat IP pada interface ether2
send "/ip address add address=192.168.200.1/24 interface=ether2\r"

# Menambahkan DHCP Client pada interface ether1 jika MikroTik terhubung ke internet
send "/ip dhcp-client add interface=ether1 disabled=no\r"

# Menambahkan DHCP Pool untuk distribusi alamat IP pada jaringan 192.168.200.0/24
send "/ip pool add name=dhcp_pool ranges=192.168.200.2-192.168.200.200\r"

# Menambahkan DHCP Server untuk interface ether2
send "/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool\r"

# Menambahkan network untuk DHCP Server MikroTik
send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8\r"

# Mengaktifkan DHCP Server
send "/ip dhcp-server enable dhcp1\r"

# Menambahkan NAT (Masquerading) untuk akses internet dari jaringan lokal
send "/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade\r"

# Menambahkan route untuk jaringan Ubuntu (Jika Ubuntu berada di jaringan 192.168.11.0/24)
send "/ip route add dst-address=192.168.11.0/24 gateway=192.168.200.1\r"

# Mengaktifkan IP forwarding pada MikroTik (Penting untuk routing antar jaringan)
send "/ip settings set ip-forwarding=yes\r"

# Mengaktifkan opsi IP forwarding untuk perangkat yang ada pada jaringan ini
send "/interface ethernet set ether2 arp=proxy-arp\r"

expect eof
EOF
