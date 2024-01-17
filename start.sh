#!/bin/sh

set -x
HAPROXYFILE="$(sed "s|NC_PASSWORD_PLACEHOLDER|$NC_HAPROXY_PASSWORD|" /haproxy.cfg)"
HAPROXYFILE="$(echo "$HAPROXYFILE" | sed "s|HAPROXY_PORT_PLACEHOLDER|$HAPROXY_PORT|")"

if [ -f "/certs/cert.pem" ]; then
    HAPROXYFILE="$(echo "$HAPROXYFILE" | sed "s|BIND_DOCKER_PLACEHOLDER|bind *:$HAPROXY_PORT v4v6 ssl crt /certs/cert.pem|")"
    sed -i "s|EX_APPS_NET_PLACEHOLDER|$EX_APPS_NET|" /haproxy_ex_apps.cfg
    # Chmod certs to be accessible by haproxy
    chmod 644 /certs/cert.pem
else
    HAPROXYFILE="$(echo "$HAPROXYFILE" | sed "s|BIND_DOCKER_PLACEHOLDER|bind *:$HAPROXY_PORT v4v6|")"
fi
echo "$HAPROXYFILE" > /haproxy.cfg

set +x

if [ -f "/certs/cert.pem" ]; then
  haproxy -f /haproxy.cfg -f /haproxy_ex_apps.cfg -db
else
  haproxy -f /haproxy.cfg -db
fi
