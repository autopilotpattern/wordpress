#!/bin/bash

set -e

echo " running entrypoint script"

echo "sleeping to wait on consul"
sleep 30


if [ -e wp-config.php ]; then
  cat wp-config.php
fi

exec "$@"
