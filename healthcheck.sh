#!/bin/bash

if [ "$BIND_ADDRESS" != "*" ]; then
	nc -z "$BIND_ADDRESS" "$HAPROXY_PORT" || exit 1
else
	nc -z localhost "$HAPROXY_PORT" || exit 1
fi
