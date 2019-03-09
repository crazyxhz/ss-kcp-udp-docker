#!/bin/bash
set -ex
MODE=${MODE:-"server"}
PASSWORD=${PASSWORD:-"PASSWORD"}
SERVER_IP=${SERVER_IP:-""}
SS_CRYPT=${SS_CRYPT:-"chacha20"}
SS_PORT=${SS_PORT:-"6655"}
HTTP_PORT=${HTTP_PORT:-"1987"}
SOCKS5_PORT=${SOCKS5_PORT:-"5544"}


if [ "$MODE" = "client" ]; then
    polipo -c /polipo.conf socksParentProxy=0.0.0.0:"$SOCKS5_PORT" proxyPort="$HTTP_PORT"
    ss-local -s "$SERVER_IP" -p "$SS_PORT" -b 0.0.0.0 -l "$SOCKS5_PORT" -m "$SS_CRYPT" -k "$PASSWORD"
else
    ss-server -s 0.0.0.0 -p "$SS_PORT" -m "$SS_CRYPT" -k "$PASSWORD" -u
fi

/bin/bash