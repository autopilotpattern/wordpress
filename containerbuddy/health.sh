#!/bin/bash

/usr/local/bin/wp --allow-root is-installed \
	&& /usr/local/bin/wp --allow-root option get site url \
	&& /usr/bin/curl --fail -s -o /dev/null http://localhost/