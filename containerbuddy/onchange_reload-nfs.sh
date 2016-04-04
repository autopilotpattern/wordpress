#!/bin/bash

if [[ `curl -s ${CONSUL}:8500/v1/health/state/passing | grep nfs`  ]]
then
  echo "nfs is healthy, mounting uploads directory...."
  mount -t nfs -v -o nolock,vers=3 nfs:/exports /var/www/html/content/uploads
else
  echo "nfs is not healthly, umounting uploads directory..."
  umount -f -l /var/www/html/content/uploads
fi
