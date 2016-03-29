#!/bin/bash

# Refresh all config files in order
#
# This script is typically called once at the container start, but
# it can be called manually if WP config details must be changed

# The database and memcached config files are separate to avoid collisions
# if their backends' onChange handlers are triggered simultaneously
echo "******running onstart script*********"

until [[ `curl -s ${CONSUL}/v1/health/service/mysql-primary?passing` ]]
do
  echo "mysql-primary not healthly...."
  sleep 5
done

/opt/containerbuddy/reload-db.sh
/opt/containerbuddy/memcached.sh

# The WordPress config file
consul-template \
    -once \
    -dedup \
    -consul consul:8500 \
    -template "/var/www/html/wp-config.php.ctmpl:/var/www/html/wp-config.php"

# The WP-CLI config
#consul-template \
#    -once \
#    -dedup \
#    -consul consul:8500 \
#    -template "/var/www/html/wp-cli.yml.ctmpl:/var/www/html/wp-cli.yml"

if $(wp --allow-root core is-installed)
then
  echo "WP is installed"
  # run update-db to ensure the database schema is up to date in case the WP version was upgraded in the Docker image
  wp --allow-root core update-db
else
  echo "WP is NOT installed"
  echo "installing now...."
  wp --allow-root core install --url=$WORDPRESS_URL --title="$WORDPRESS_SITE_TITLE" --admin_user=$WORDPRESS_ADMIN_USER --admin_password=$WORDPRESS_ADMIN_PASSWORD --admin_email=$WORDPRESS_ADMIN_EMAIL --skip-email
  # update siteurl to work with our directory structure
  # wp option update for siteurl REQUIRES http://, need to determine will we handle that here
  # or ask for it in the _env file or test for it above
  wp --allow-root option update siteurl `wp --allow-root option get siteurl`/wordpress
  if [ $WORDPRESS_TEST_DATA ]
  then
    echo "installing WP test content"
    wp --allow-root plugin install wordpress-importer --activate
    curl -OL https://raw.githubusercontent.com/manovotny/wptest/master/wptest.xml
    wp --allow-root import wptest.xml --authors=create
    wp --allow-root plugin uninstall wordpress-importer --deactivate
    rm wptest.xml
  fi
fi

# copy themes from wp install directory to content/themes
# TODO remove this and use wp-cli to set the active theme to our theme from the repo
#cp -r /var/www/html/wordpress/wp-content/themes/* /var/www/html/content/themes/

#exec "$@"
