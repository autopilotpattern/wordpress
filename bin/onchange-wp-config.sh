#!/bin/bash
# The WordPress config file
consul-template \
    -once \
    -dedup \
    -consul ${CONSUL}:8500 \
    -template "/var/www/html/wp-config.php.ctmpl:/var/www/html/wp-config.php"
