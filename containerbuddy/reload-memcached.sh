#!/bin/bash

consul-template \
    -once \
    -dedup \
    -consul consul:8500 \
    -template "/var/www/html/memcached-config.php.ctmpl:/var/www/html/memcached-config.php"