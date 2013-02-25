#!/bin/bash

IPTABLES="/sbin/iptables"

loopIf=lo
looplan=127.0.0.0/8

PROXY_IP="$1"
PROXY_PORT="$2"

$IPTABLES -P OUTPUT DROP
$IPTABLES -P INPUT  DROP
$IPTABLES -P FORWARD DROP

$IPTABLES -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPTABLES -A INPUT -i ${loopIf} -s ${looplan} -d ${looplan} -j ACCEPT
$IPTABLES -A OUTPUT -o ${loopIf} -s ${looplan} -d ${looplan} -j ACCEPT

$IPTABLES -A INPUT -i eth0 -p tcp -m tcp --dport 22 -j ACCEPT
$IPTABLES -A OUTPUT -o eth0 -p tcp -m tcp -d $PROXY_IP --dport $PROXY_PORT -j ACCEPT

