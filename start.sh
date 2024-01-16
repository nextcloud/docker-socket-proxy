#!/bin/sh

set -x
HAPROXYFILE="$(sed "s|NC_PASSWORD_PLACEHOLDER|$NC_HAPROXY_PASSWORD|" /haproxy.cfg)"
echo "$HAPROXYFILE" > /haproxy.cfg
HAPROXYFILE="$(sed "s|HAPROXY_PORT_PLACEHOLDER|$HAPROXY_PORT|" /haproxy.cfg)"
echo "$HAPROXYFILE" > /haproxy.cfg

if [ -f "/certs/cert.pem" ]; then
    HAPROXYFILE="$(sed "s|BIND_PLACEHOLDER|bind :::$HAPROXY_PORT ssl crt /certs/cert.pem |" /haproxy.cfg)"
    echo "$HAPROXYFILE" > /haproxy.cfg
    # Chmod certs to be accessible by haproxy
    chmod 644 /certs/cert.pem
else
    HAPROXYFILE="$(sed "s|BIND_PLACEHOLDER|bind :::$HAPROXY_PORT v4v6|" /haproxy.cfg)"
    echo "$HAPROXYFILE" > /haproxy.cfg
fi

set +x

haproxy -f /haproxy.cfg -db
