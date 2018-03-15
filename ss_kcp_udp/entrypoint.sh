#!/bin/bash
set -ex
MODE=${MODE:-"server"}
PASSWORD=${PASSWORD:-"PASSWORD"}
SERVER_IP=${SERVER_IP:-""}
SS_CRYPT=${SS_CRYPT:-"chacha20"}
SS_PORT=${SS_PORT:-"6655"}
KCP_PORT=${KCP_PORT:-"7766"}
SS_PORT_UDPRELAY=${SS_PORT_UDPRELAY:-"7767"}
KCP_CRYPT=${KCP_CRYPT:-"none"}
KCP_MTU=${KCP_MTU:-"1200"}
KCP_MODE=${KCP_MODE:-"fast2"}
KCP_DSCP=${KCP_DSCP:-"46"}
UDPRAW_PORT=${UDPRAW_PORT:-"8877"}
UDP_CRYPT=${UDP_CRYPT:-"xor"}
UDP_AUTH=${UDP_AUTH:-"simple"}
UDPRAW_PORT_SS_UDPRELAY=${UDPRAW_PORT_SS_UDPRELAY:-"8878"}
SOCKS5_PORT=${SOCKS5_PORT:-"5544"}
UDPRAW_LOG_LEVEL=${UDPRAW_LOG_LEVEL:-"4"}

chain_exists()
{
    [ $# -lt 1 -o $# -gt 2 ] && { 
        echo "Usage: chain_exists <chain_name> [table]" >&2
        return 1
    }
    local chain_name="$1" ; shift
    [ $# -eq 1 ] && local table="--table $1"
    iptables $table -n --list "$chain_name" >/dev/null 2>&1
}
create_chain()
{
    iptables -N udp2raw
    iptables -A udp2raw -j DROP
    iptables -A INPUT -p tcp -m tcp --dport "$UDPRAW_PORT" -j udp2raw
    iptables -A INPUT -p tcp -m tcp --dport "$UDPRAW_PORT_SS_UDPRELAY" -j udp2raw
}
chain_exists udp2raw || create_chain

if [ "$MODE" = "client" ]; then
    udp2raw_amd64 -c -r "$SERVER_IP":"$UDPRAW_PORT" -l "127.0.0.1:$KCP_PORT" --raw-mode faketcp -k "$PASSWORD" --log-level "$UDPRAW_LOG_LEVEL" --cipher-mode "$UDP_CRYPT" --auth-mode "$UDP_AUTH" 2>&1 &
    udp2raw_amd64 -c -r "$SERVER_IP":"$UDPRAW_PORT_SS_UDPRELAY" -l "127.0.0.1:$SS_PORT_UDPRELAY" --raw-mode faketcp -k "$PASSWORD" --log-level "$UDPRAW_LOG_LEVEL" --cipher-mode "$UDP_CRYPT" --auth-mode "$UDP_AUTH" 2>&1 &
    kcpclient -r "127.0.0.1:$KCP_PORT" -l "127.0.0.1:$SS_PORT" --mode "$KCP_MODE" -mtu "$KCP_MTU" --crypt "$KCP_CRYPT" --nocomp --dscp "$KCP_DSCP" 2>&1 &
    ss-local -s 127.0.0.1 -p "$SS_PORT_UDPRELAY" -b 0.0.0.0 -l "$SOCKS5_PORT" -m "$SS_CRYPT" -k "$PASSWORD" --fast-open -U 2>&1 &
    ss-local -s 127.0.0.1 -p "$SS_PORT" -b 0.0.0.0 -l "$SOCKS5_PORT" -m "$SS_CRYPT" -k "$PASSWORD" --fast-open
else
    udp2raw_amd64 -s -l 0.0.0.0:"$UDPRAW_PORT" -r 127.0.0.1:"$KCP_PORT" -k "$PASSWORD" --raw-mode faketcp --log-level "$UDPRAW_LOG_LEVEL" --cipher-mode "$UDP_CRYPT" --auth-mode "$UDP_AUTH" 2>&1 &
    udp2raw_amd64 -s -l 0.0.0.0:"$UDPRAW_PORT_SS_UDPRELAY" -r 127.0.0.1:"$SS_PORT" -k "$PASSWORD" --raw-mode faketcp --log-level "$UDPRAW_LOG_LEVEL" --cipher-mode "$UDP_CRYPT" --auth-mode "$UDP_AUTH" 2>&1 &
    kcpserver -t "127.0.0.1:$SS_PORT" -l "127.0.0.1:$KCP_PORT" --mode "$KCP_MODE" -mtu "$KCP_MTU" --crypt "$KCP_CRYPT" --nocomp --dscp "$KCP_DSCP" 2>&1 &
    ss-server -s 0.0.0.0 -p "$SS_PORT" -m "$SS_CRYPT" -k "$PASSWORD" --fast-open -u
fi

