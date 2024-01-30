#!/bin/bash

if [ "$BIND_ADDRESS" != "*" ]; then
	nc -z "$BIND_ADDRESS" "$HAPROXY_PORT" || exit 1
else
	nc -z "127.0.0.1" "$HAPROXY_PORT" || exit 1
fi
