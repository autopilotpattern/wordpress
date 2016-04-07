#!/bin/bash

/usr/local/bin/onchange-wp-config.sh

consul-template \
    -once \
    -dedup \
    -consul ${CONSUL}:8500 \
    -template "/var/www/html/consul-templates/db-config.php.ctmpl:/var/www/html/content/db-config.php"
