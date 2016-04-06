#!/bin/bash

if [[ `curl -s ${CONSUL}:8500/v1/health/state/passing | grep nfs`  ]]
then
  echo "nfs is healthy, mounting uploads directory...."
  mount -t nfs -v -o nolock,vers=3 nfs:/exports /var/www/html/content/uploads
  echo "removing no-uploads.php mu-plugin"
  rm /var/www/html/content/mu-plugins/no-uploads.php
  echo "adding 'upload_files' capability back to default roles"
  # only these roles have 'upload_files' cap by default
  for role in administrator editor author
  do
    if [ "$role" != 'role' ]
    then
      wp --allow-root cap add ${role} upload_files
    fi
  done
else
  echo "nfs is not healthly, umounting uploads directory..."
  umount -f -l /var/www/html/content/uploads
  echo "creating mu-plugin for NFS error in wp-admin"
  echo "<?php
  function nfs_error_notice() {
      ?>
      <div class="error notice">
          <p><?php _e('The NFS container is not present, media uploads have been disabled'); ?></p>
      </div>
      <?php
  }
  add_action( 'admin_notices', 'nfs_error_notice' );" > /var/www/html/content/mu-plugins/no-uploads.php

  echo "removing 'upload_files' capability from all roles..."
  for role in $(wp --allow-root role list --fields=role --format=csv)
  do
    if [ "$role" != 'role' ]
    then
      wp --allow-root cap remove ${role} upload_files
    fi
  done
fi
