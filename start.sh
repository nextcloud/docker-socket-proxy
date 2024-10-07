#!/bin/sh

# SPDX-FileCopyrightText: 2023 Nextcloud GmbH and Nextcloud contributors
# SPDX-License-Identifier: AGPL-3.0-only

if [ ! -f "/haproxy.cfg" ]; then

  echo "Creating HaProxy config.."

  if [ -n "$NC_HAPROXY_PASSWORD_FILE" ] && [ ! -f "$NC_HAPROXY_PASSWORD_FILE" ]; then
    echo "Error: NC_HAPROXY_PASSWORD_FILE is specified but the file does not exist."
    exit 1
  fi

  if [ -n "$NC_HAPROXY_PASSWORD" ] && [ -n "$NC_HAPROXY_PASSWORD_FILE" ]; then
    echo "Error: Only one of NC_HAPROXY_PASSWORD or NC_HAPROXY_PASSWORD_FILE should be specified."
    exit 1
  fi

  if [ -n "$NC_HAPROXY_PASSWORD_FILE" ]; then
    if [ -s "$NC_HAPROXY_PASSWORD_FILE" ]; then
      NC_HAPROXY_PASSWORD=$(mkpasswd -m sha-256 < "$NC_HAPROXY_PASSWORD_FILE")
    else
      echo "Error: NC_HAPROXY_PASSWORD_FILE is specified but is empty."
      exit 1
    fi
  elif [ -n "$NC_HAPROXY_PASSWORD" ]; then
    NC_HAPROXY_PASSWORD=$(echo "$NC_HAPROXY_PASSWORD" | mkpasswd -m sha-256)
  else
    echo "Error: Either NC_HAPROXY_PASSWORD_FILE or NC_HAPROXY_PASSWORD must be set and contain a password."
    exit 1
  fi

  export NC_HAPROXY_PASSWORD

  envsubst < /haproxy.cfg.template > /haproxy.cfg
  envsubst < /haproxy_ex_apps.cfg.template > /haproxy_ex_apps.cfg

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
else
  echo "HaProxy config already present."
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
