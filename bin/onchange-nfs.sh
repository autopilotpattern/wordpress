#!/bin/bash

if [[ `curl -s ${CONSUL}:8500/v1/health/state/passing | grep nfs`  ]]
then
  echo "nfs is healthy, mounting uploads directory...."
  mount -t nfs -v -o nolock,vers=3 nfs:/exports /var/www/html/content/uploads
  echo "removing no-uploads.php mu-plugin"
  rm /var/www/html/content/mu-plugins/no-uploads.php
  # check 'wp core is-installed' here to prevent errors in the log on first run
  # before WP gets installed into the database
  if $(wp --allow-root core is-installed)
  then
    echo "adding 'upload_files' capability back to default roles"
    # only these roles have 'upload_files' cap by default
    for role in administrator editor author
    do
      if [ "$role" != 'role' ]
      then
        wp --allow-root cap add ${role} upload_files
      fi
    done
  fi
else
  echo "nfs is not healthly, umounting uploads directory..."
  umount -f -l /var/www/html/content/uploads
  echo "creating mu-plugin for NFS error in wp-admin"
  cp /var/www/html/inactive_plugins/no-uploads.php /var/www/html/content/mu-plugins/

  echo "removing 'upload_files' capability from all roles..."
  for role in $(wp --allow-root role list --fields=role --format=csv)
  do
    if [ "$role" != 'role' ]
    then
      wp --allow-root cap remove ${role} upload_files
    fi
  done
fi
