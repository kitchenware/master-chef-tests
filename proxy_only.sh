#!/bin/bash

IPTABLES="/sbin/iptables"

PROXY_IP="$1"
PROXY_PORT="$2"

echo "Starting firewall : dropping outbound traffic except proxy to $PROXY_IP:$PROXY_PORT"

$IPTABLES -F INPUT
$IPTABLES -A INPUT -i eth0 -j ACCEPT

$IPTABLES -F OUTPUT
# do not blast current SSH connection
$IPTABLES -A OUTPUT -o eth0 -p tcp --sport 22 -j ACCEPT
$IPTABLES -A OUTPUT -o eth0 -p tcp -d $PROXY_IP --dport $PROXY_PORT -j ACCEPT
$IPTABLES -A OUTPUT -o eth0 -m state --state ESTABLISHED -j ACCEPT
$IPTABLES -A OUTPUT -o eth0 -j DROP

echo "Firewall ready"
