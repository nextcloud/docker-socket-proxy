#!/bin/bash

# SPDX-FileCopyrightText: 2023 Nextcloud GmbH and Nextcloud contributors
# SPDX-License-Identifier: AGPL-3.0-only

if [ "$BIND_ADDRESS" != "*" ]; then
	nc -z "$BIND_ADDRESS" "$HAPROXY_PORT" || exit 1
else
  if ! nc -z "127.0.0.1" "$HAPROXY_PORT" && ! nc -z "::1" "$HAPROXY_PORT"; then
    exit 1
  fi
fi
