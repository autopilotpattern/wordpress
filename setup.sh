#!/usr/bin/env bash

# run this script to setup your envrionment to start the project
# add the public and private keys you used in your MANTA setup to
# manta.id_rsa dn manta.id_rsa.pub or edit this script

unset MANTA_PRIVATE_KEY
#unset MANTA_KEY_ID
unset NGINX_CONF
unset NGINX_CONTAINERBUDDY

MANTA_PRIVATE_KEY=`cat manta.id_rsa`
#MANTA_KEY_ID=`ssh-keygen -lf manta.id_rsa.pub | awk -F ' ' '{print $2}'`
NGINX_CONF=`cat nginx.conf.ctmpl`
NGINX_CONTAINERBUDDY=`cat nginx_containerbuddy.json`
