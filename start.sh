#!/bin/sh

sed -i "s|NC_PASSWORD_PLACEHOLDER|$NC_HAPROXY_PASSWORD|" /haproxy.cfg
sed -i "s|TIMEOUT_CONNECT|$TIMEOUT_CONNECT|" /haproxy.cfg
sed -i "s|TIMEOUT_CLIENT|$TIMEOUT_CLIENT|" /haproxy.cfg
sed -i "s|TIMEOUT_SERVER|$TIMEOUT_SERVER|" /haproxy.cfg

if [ -f "/certs/cert.pem" ]; then
    EX_APPS_COUNT_PADDED=$(printf "%03d" "$EX_APPS_COUNT")
    sed -i "s|BIND_ADDRESS_PLACEHOLDER|bind $BIND_ADDRESS:$HAPROXY_PORT v4v6 ssl crt /certs/cert.pem|" /haproxy.cfg
    sed -i "s|BIND_ADDRESS_PLACEHOLDER|bind $BIND_ADDRESS:23000-23$EX_APPS_COUNT_PADDED v4v6 ssl crt /certs/cert.pem|" /haproxy_ex_apps.cfg
    sed -i "s|EX_APPS_NET_PLACEHOLDER|$EX_APPS_NET|" /haproxy_ex_apps.cfg
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
echo "HaProxy quit unexpectedly"
exit 1
