#!/bin/bash

SERVICE_NAME=${SERVICE_NAME:-nginx}
CONSUL=${CONSUL:-consul}

# Render Nginx configuration template using values from Consul,
# but do not reload because Nginx has't started yet
preStart() {
    getConfig
    consul-template \
        -once \
        -consul ${CONSUL}:8500 \
        -template "/tmp/nginx.ctmpl:/etc/nginx/nginx.conf"
}

# Render Nginx configuration template using values from Consul,
# then gracefully reload Nginx
onChange() {
    getConfig
    consul-template \
        -once \
        -consul ${CONSUL}:8500 \
        -template "/tmp/nginx.ctmpl:/etc/nginx/nginx.conf:nginx -s reload"
}

getConfig() {
    if [ -z "${NGINX_CONF}" ]; then
        # fetch latest Nginx configuration template from Consul k/v
        curl -s --fail ${CONSUL}:8500/v1/kv/${SERVICE_NAME}/template?raw > /tmp/nginx.ctmpl
    else
        # dump the ${NGINX_CONF} environment variable as a file
        # the quotes are important here to preserve newlines!
        cat "${NGINX_CONF}" > /tmp/nginx.ctmpl
    fi
}

help() {
    echo "Usage: ./reload.sh preStart  => first-run configuration for Nginx"
    echo "       ./reload.sh onChange  => [default] update Nginx config on upstream changes"
}

until
    cmd=$1
    if [ -z "$cmd" ]; then
        onChange
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    onChange
    exit
done
