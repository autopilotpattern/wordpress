#!/bin/bash

consul-template \
    -once \
    -dedup \
    -consul ${CONSUL}:8500 \
    -template "/var/www/html/db-config.php.ctmpl:/var/www/html/wordpress/db-config.php"
