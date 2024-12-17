#!/bin/bash

# Konfigurasi Dasar
IPNET="192.168.11.137"   # IP Cisco Switch (nomor absen 11)
SPORT="30002"            # Port untuk Telnet
VLAN_ID=11               # VLAN ID (nomor absen 11)

# Telnet ke Switch Cisco dan Konfigurasi VLAN
{
    sleep 1
    echo "enable"
    sleep 1
    echo "configure terminal"
    sleep 1

    # Konfigurasi VLAN
    echo "vlan $VLAN_ID"
    sleep 1
    echo "name VLAN_$VLAN_ID"
    sleep 1
    echo "exit"
    sleep 1

    # Interface e0/1 sebagai akses VLAN 11
    echo "interface e0/1"
    sleep 1
    echo "switchport mode access"
    sleep 1
    echo "switchport access vlan $VLAN_ID"
    sleep 1
    echo "no shutdown"
    sleep 1
    echo "exit"
    sleep 1

    # Interface e0/0 sebagai trunk untuk VLAN 11
    echo "interface e0/0"
    sleep 1
    echo "switchport trunk encapsulation dot1q"
    sleep 1
    echo "switchport mode trunk"
    sleep 1
    echo "switchport trunk allowed vlan $VLAN_ID"
    sleep 1
    echo "no shutdown"
    sleep 1
    echo "exit"
    sleep 1

    # Verifikasi VLAN di Cisco
    echo "show vlan brief"
    sleep 2
    echo "show running-config"
    sleep 2
    echo "write memory"
    sleep 1
    echo "exit"
} | telnet $IPNET $SPORT

echo "Konfigurasi VLAN di Cisco Switch selesai!"
