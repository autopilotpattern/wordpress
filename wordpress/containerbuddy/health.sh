#!/bin/bash

/usr/local/bin/wp --allow-root core is-installed \
	&& /usr/local/bin/wp --allow-root option get siteurl \
	&& /usr/bin/curl --fail -s -o /dev/null http://localhost/
