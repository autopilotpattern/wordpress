#!/bin/bash

# Refresh all config files in order
#
# This script is typically called once at the container start, but 
# it can be called manually if WP config details must be changed

# The database and memcached config files are separate to avoid collisions 
# if their backends' onChange handlers are triggered simultaneously
/opt/containerbuddy/reload-db.sh
/opt/containerbuddy/reload-memcached.sh

# The WordPress config file
consul-template \
    -once \
    -dedup \
    -consul consul:8500 \
    -template "/var/www/html/wp-config.php.ctmpl:/var/www/html/wp-config.php"

# The WP-CLI config
consul-template \
    -once \
    -dedup \
    -consul consul:8500 \
    -template "/var/www/html/wp-cli.yml.ctmpl:/var/www/html/wp-cli.yml"