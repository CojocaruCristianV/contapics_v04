#!/bin/sh
set -e

# Replace BACKEND_URL placeholder with actual value
if [ -n "$BACKEND_URL" ]; then
    sed -i "s|BACKEND_URL_PLACEHOLDER|$BACKEND_URL|g" /usr/share/nginx/html/config.js
fi

# Execute original nginx entrypoint
exec nginx -g 'daemon off;'
