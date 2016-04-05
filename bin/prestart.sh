#!/bin/bash

# Refresh all config files in order
#
# This script is typically called once at the container start, but
# it can be called manually if WP config details must be changed

# The database and memcached config files are separate to avoid collisions
# if their backends' onChange handlers are triggered simultaneously
echo "******running preStart script*********"

until [[ `curl -s ${CONSUL}:8500/v1/health/state/passing | grep mysql-primary`  ]]
do
  echo "mysql-primary not healthly...."
  sleep 5
done

until [[ `curl -s ${CONSUL}:8500/v1/health/state/passing | grep nfs`  ]]
do
  echo "no healthly nfs server avaliable yet...."
  sleep 5
done

echo "mysql-primary and nfs are now healthly, moving on..."

/usr/local/bin/onchange-db.sh
/usr/local/bin/onchange-memcached.sh
/usr/local/bin/onchange-nfs.sh

# The WordPress config file
/usr/local/bin/onchange-wp-config.sh

if $(wp --allow-root core is-installed)
then
  echo "WP is installed"
  # run update-db to ensure the database schema is up to date in case the WP version was upgraded in the Docker image
  wp --allow-root core update-db
else
  echo "WP is NOT installed"
  echo "installing now...."
  # TODO: check WORDPRESS_URL to ensure it has http:// or https:// at the beginning, if not put it in
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
