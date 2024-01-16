#!/bin/bash

nc -z localhost "$HAPROXY_PORT" || exit 1
