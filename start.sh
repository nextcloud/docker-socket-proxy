#!/bin/sh

sed -i "s|NC_PASSWORD_PLACEHOLDER|$NC_HAPROXY_PASSWORD|" /haproxy.cfg

if [ -f "/certs/cert.pem" ]; then
    sed -i "s|BIND_ADDRESS_PLACEHOLDER|bind $BIND_ADDRESS:$HAPROXY_PORT v4v6 ssl crt /certs/cert.pem|" /haproxy.cfg
    sed -i "s|BIND_ADDRESS_PLACEHOLDER|bind $BIND_ADDRESS:23000-23999 v4v6 ssl crt /certs/cert.pem|" /haproxy_ex_apps.cfg
    sed -i "s|EX_APPS_NET_FOR_HTTPS_PLACEHOLDER|$EX_APPS_NET_FOR_HTTPS|" /haproxy_ex_apps.cfg
    # Chmod certs to be accessible by haproxy
    chmod 644 /certs/cert.pem
else
    sed -i "s|BIND_ADDRESS_PLACEHOLDER|bind $BIND_ADDRESS:$HAPROXY_PORT v4v6|" /haproxy.cfg
fi

echo "HaProxy config:"

if [ -f "/certs/cert.pem" ]; then
  cat /haproxy.cfg
  cat /haproxy_ex_apps.cfg
  haproxy -f /haproxy.cfg -f /haproxy_ex_apps.cfg -db
else
  cat /haproxy.cfg
  haproxy -f /haproxy.cfg -db
fi
