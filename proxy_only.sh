#!/bin/bash

IPTABLES="/sbin/iptables"

PROXY_IP="$1"
PROXY_PORT="$2"

echo "Starting firewall : droping all  expect inbound SSH and outbound proxy to $PROXY_IP:$PROXY_PORT"

$IPTABLES -F INPUT
$IPTABLES -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
$IPTABLES -A INPUT -i eth0 -p tcp -s $PROXY_IP --sport $PROXY_PORT -j ACCEPT
$IPTABLES -A INPUT -i eth0 -j DROP

$IPTABLES -F OUTPUT
$IPTABLES -A OUTPUT -o eth0 -p tcp --sport 22 -j ACCEPT
$IPTABLES -A OUTPUT -o eth0 -p tcp -d $PROXY_IP --dport $PROXY_PORT -j ACCEPT
$IPTABLES -A OUTPUT -o eth0 -j DROP

echo "Firewall ready"
