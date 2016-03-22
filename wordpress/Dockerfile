FROM php:5.6-apache

RUN a2enmod rewrite

# install the PHP extensions we need, and other packages
RUN apt-get update \
    && apt-get install -y \
        less \
        libpng12-dev \
        libjpeg-dev \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd mysqli opcache

# install libmemcache and the php lib
RUN apt-get update && apt-get install -y libmemcached-dev \
    && pecl install memcached \
    && docker-php-ext-enable memcached

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# install python for entrypoint
RUN apt-get update \
    && apt-get install -y \
    python \
    python-dev \
    gcc \
    curl

# get Python drivers MySQL, Consul, and Manta
RUN curl -Ls -o /opt/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python /opt/get-pip.py && \
    pip install \
        python-Consul==0.4.7

COPY /bin/docker-entrypoint.py /entrypoint.py

# The Containerbuddy helper/glue scripts for this specific app
COPY containerbuddy /opt/containerbuddy

# Install Containerbuddy
# Releases at https://github.com/joyent/containerbuddy/releases
ENV CONTAINERBUDDY_VERSION 0.1.1
ENV CONTAINERBUDDY_SHA1 3163e89d4c95b464b174ba31733946ca247e068e
RUN curl --retry 7 -Lso /tmp/containerbuddy.tar.gz "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VERSION}/containerbuddy-${CONTAINERBUDDY_VERSION}.tar.gz" \
    && echo "${CONTAINERBUDDY_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /opt/containerbuddy \
    && rm /tmp/containerbuddy.tar.gz

COPY containerbuddy/* /opt/containerbuddy/

# Install Consul template
# Releases at https://releases.hashicorp.com/consul-template/
ENV CONSUL_TEMPLATE_VERSION 0.12.2
ENV CONSUL_TEMPLATE_SHA1 a8780f365bf5bfad47272e4682636084a7475ce74b336cdca87c48a06dd8a193
RUN curl --retry 7 -Lso /tmp/consul-template.zip "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_TEMPLATE_SHA1}  /tmp/consul-template.zip" | sha256sum -c \
    && unzip /tmp/consul-template.zip -d /usr/local/bin \
    && rm /tmp/consul-template.zip

# copy the WordPress skeleton from this repo into the container
# this includes any themes and/or plugins we've added to the content/themes and content/plugins, etc, directories.
COPY /var/www/html /var/www/html

# Make the WP uploads directory writeable by the web server
RUN chown -R www-data:www-data /var/www/html/content/uploads

# install wp-cli, http://wp-cli.org
ENV WP_CLI_CONFIG_PATH /var/www/html/wp-cli.yml
RUN curl -Ls -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info --allow-root

ENV WORDPRESS_VERSION=${WORDPRESS_VERSION:-4.4.2}

RUN echo "********** WORDPRESS_VERSION = ${WORDPRESS_VERSION} ************"

# install WordPress via wp-cli
RUN wp --allow-root core download --version=${WORDPRESS_VERSION}

# install WordPress
# Releases at https://wordpress.org/download/release-archive/
#ENV WORDPRESS_VERSION 4.4.1
#ENV WORDPRESS_VERSION
#ENV WORDPRESS_SHA1 89bcc67a33aecb691e879c818d7e2299701f30e7
## echo "$(curl -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz.sha1) *wordpress.tar.gz" | sha1sum -c -
# upstream tarballs include ./wordpress/ so this gives us /var/www/html/wordpress
#RUN curl -o wordpress.sha1 -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz.sha1 \
#     && curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
#     && echo "`cat wordpress.sha1` *wordpress.tar.gz" | sha1sum -c - \
#    && tar -xzf wordpress.tar.gz -C /var/www/html \
#    && rm wordpress.tar.gz

# install HyperDB, https://wordpress.org/plugins/hyperdb
# Releases at https://wordpress.org/plugins/hyperdb/developers/ , though no SHA1 fingerprints are published
#ENV HYPERDB_VERSION 1.1
#RUN curl -Ls -o /var/www/html/hyperdb.zip https://downloads.wordpress.org/plugin/hyperdb.${HYPERDB_VERSION}.zip \
#    && unzip hyperdb.zip \
#    && chown -R www-data:www-data /var/www/html/hyperdb \
#    && mv hyperdb/db.php /var/www/html/content/. \
#    && rm -rf /var/www/html/hyperdb.zip /var/www/html/hyperdb \
#    && touch /var/www/html/wordpress/db-config.php \
#    && ln -s /var/www/html/wordpress/db-config.php /var/www/html/.


# install ztollman's object-cache.php and batcache's advanced-cache.php for memcached caching
# question. does this belong here in the Dockerfile or in /content in our repo?
RUN curl -Ls -o /var/www/html/content/object-cache.php https://raw.githubusercontent.com/tollmanz/wordpress-pecl-memcached-object-cache/master/object-cache.php
RUN curl -Ls -o /var/www/html/content/advanced-cache.php https://raw.githubusercontent.com/Automattic/batcache/master/advanced-cache.php

RUN chown -R www-data:www-data /var/www/html/tools

# testing apache error logs stdout
RUN ln -sf /proc/self/fd/1 /var/log/apache2/error.log

# the volume is defined after we install everything
#VOLUME /var/www/html

# grr, ENTRYPOINT resets CMD now
#ENTRYPOINT ["/entrypoint.py"]
CMD ["/opt/containerbuddy/containerbuddy", \
    "apache2-foreground"]
