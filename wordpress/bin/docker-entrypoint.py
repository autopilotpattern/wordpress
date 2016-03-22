#!/usr/bin/env python

import consul as pyconsul
import time
import os
import subprocess
import sys
import logging
import requests
import json

# setup logging
logging.basicConfig(format='%(asctime)s %(levelname)s %(name)s %(message)s',
                    stream=sys.stdout,
                    level=logging.getLevelName(
                        os.environ.get('LOG_LEVEL', 'DEBUG')))
requests_logger = logging.getLogger('requests')
requests_logger.setLevel(logging.WARN)

log = logging.getLogger('triton-wordpress')

consul = pyconsul.Consul(host=os.environ.get('CONSUL_HOST', 'consul'))


def wait_for_consul():
    result = None
    while result is None:
        try:
            result = consul.health.service('consul', passing=True)
        except:
            log.info("waiting for consul to be healthly")
            time.sleep(5)
            pass
        else:
            log.info("consul service is healthly, moving on....")

def wait_for_mysql():
    while True:
        try:
            result = consul.health.checks('mysql-primary')[1][0]['Status']
        except:
            print("mysql-primary not up yet, sleeping 5....")
        else:
            if result == "passing":
                print("mysql-primary status is: {}, continuing....".format(result))
                break
            print("mysql-primary status is: {}, sleeping 5....".format(result))
        time.sleep(5)

def render_consul_template(command):
    # trying to call consule-template via subprocess.call always resulted in a "file not found" error for the .ctmpl file
    # falling back to calling shell scripts for each template
    log.info("rendering consul template using {}".format(command))
    #command = "consul-template -once -dedup -consul consul:8500 -template '{}':'{}'".format(template, renderedFile)
    subprocess.call(command)

def on_start():

    wait_for_consul()
    wait_for_mysql()

    render_consul_template("/opt/containerbuddy/wp-config.sh")

    # get list of WP version from api
    versions = json.loads(requests.get('https://api.wordpress.org/core/stable-check/1.0/').text)
    # get wp version from env, if it doesn't exist use latest from above api call result
    WORDPRESS_VERSION = os.environ.get("WORDPRESS_VERSION", sorted(versions.keys())[-1])
    WORDPRESS_URL = os.environ.get("WORDPRESS_URL", "www.example.com")
    WORDPRESS_SITE_TITLE = os.environ.get("WORDPRESS_SITE_TITLE", "test site")
    WORDPRESS_ADMIN_EMAIL = os.environ.get("WORDPRESS_ADMIN_EMAIL", "test@test.com")
    WORDPRESS_ADMIN_USER = os.environ.get("WORDPRESS_ADMIN_USER", "admin")
    # what to do when no password is set in _env?
    WORDPRESS_ADMIN_PASSWORD = os.environ.get("WORDPRESS_ADMIN_PASSWORD", "")
    WORDPRESS_TEST_DATA = os.environ.get("WORDPRESS_TEST_DATA", False)
'''
    if WORDPRESS_VERSION in versions.keys():
        log.info("valid wordpress version requested")
    else:
        log.critical("invalid wordpress version requested!")
        log.critical("check https://api.wordpress.org/core/stable-check/1.0/ for valid releases")
        raise SystemExit(0)

    # is wordpress downloaded?
    if not os.path.isdir('wordpress'):
        log.info("no wordpress install found!")
        log.info("downloading...")
        subprocess.call("wp --allow-root core download --version={}".format(WORDPRESS_VERSION).split(), shell=False)
        # TODO fix site title so it can accept spaces
        subprocess.call("wp --allow-root core install --url={} --title='{}' --admin_user={} --admin_password={} --admin_email={} --skip-email"
                        .format(WORDPRESS_URL, WORDPRESS_SITE_TITLE, WORDPRESS_ADMIN_USER, WORDPRESS_ADMIN_PASSWORD, WORDPRESS_ADMIN_EMAIL).split())
        # update siteurl to work with our directory structure
        # wp option update for siteurl REQUIRES http://, need to determine will we handle that here
        # or ask for it in the _env file or test for it above
        command = "wp --allow-root option update siteurl http://{}/wordpress".format(WORDPRESS_URL)
        subprocess.call(command.split())
    else:
        log.info('wordpress is installed, continuing on_start')

    # did the env file request a WP upgrade?
    currentVersion = subprocess.check_output("wp --allow-root core version".split())
    if WORDPRESS_VERSION > currentVersion:
        log.info("WP upgrade requested via _env from {} to {}".format(currentVersion, WORDPRESS_VERSION))
        # requested version from env is higher than current version, the upgrade
        try:
            subprocess.call("wp --allow-root core upgrade --version=".format(WORDPRESS_VERSION).split())
            log.info("upgrade complete, upgrading database")
            subprocess.call("wp --allow-root core update-db".split())
            # will need to accomodate all sites if we switch to allowing multisite
        except:
            "upgrade requested but failed"

    # install test content?
    if WORDPRESS_TEST_DATA:
        subprocess.call("wp --allow-root plugin install wordpress-importer --activate".split())
        subprocess.call("curl -OL https://raw.githubusercontent.com/manovotny/wptest/master/wptest.xml".split())
        subprocess.call("wp --allow-root import wptest.xml --authors=create".split())
        subprocess.call("wp --allow-root plugin uninstall wordpress-importer --deactivate".split())
        os.remove("wptest.xml")
'''

def health():
    pass

if __name__ == '__main__':

    if len(sys.argv) > 1:
        try:
            locals()[sys.argv[1]]()
        except KeyError:
            log.error('Invalid command %s', sys.argv[1])
            sys.exit(1)
    else:
        # default behavior will be to start mysqld, running the
        # initialization if required
        on_start()
