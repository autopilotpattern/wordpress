FROM php:5.6-apache

RUN a2enmod rewrite

# Install the PHP extensions we need, and other packages
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        jq \
        less \
        libjpeg-dev \
        libmemcached-dev \
        libpng12-dev \
        nfs-common \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    # Memcached 2.2.0 is the latest for PHP < 7
    # see https://pecl.php.net/package/memcached
    && pecl install memcached-2.2.0 \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd mysqli opcache \
    && docker-php-ext-enable memcached \
    # Set recommended PHP.ini settings
    # See https://secure.php.net/manual/en/opcache.installation.php
    && { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# The our helper/glue scripts and configuration for this specific app
COPY bin /usr/local/bin
COPY etc /etc

# Add Containerpilot and its configuration
# Releases at https://github.com/joyent/containerpilot/releases
ENV CONTAINERPILOT_VER 2.7.3
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN set -ex \
    && export CONTAINERPILOT_CHECKSUM=2511fdfed9c6826481a9048e8d34158e1d7728bf \
    && curl --retry 7 --fail -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# Install Consul
# Releases at https://releases.hashicorp.com/consul
RUN set -ex \
    && export CONSUL_VERSION=0.7.5 \
    && export CONSUL_CHECKSUM=40ce7175535551882ecdff21fdd276cef6eaab96be8a8260e0599fadb6f1f5b8 \
    && curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir /config

# Install Consul template
# Releases at https://releases.hashicorp.com/consul-template/
RUN set -ex \
    && export CONSUL_TEMPLATE_VERSION=0.18.3 \
    && export CONSUL_TEMPLATE_CHECKSUM=caf6018d7489d97d6cc2a1ac5f1cbd574c6db4cd61ed04b22b8db7b4bde64542 \
    && curl --retry 7 --fail -Lso /tmp/consul-template.zip "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_TEMPLATE_CHECKSUM}  /tmp/consul-template.zip" | sha256sum -c \
    && unzip /tmp/consul-template.zip -d /usr/local/bin \
    && rm /tmp/consul-template.zip

# Install wp-cli, http://wp-cli.org
ENV WP_CLI_CONFIG_PATH /var/www/html/wp-cli.yml
RUN set -ex \
    && curl --retry 7 --fail -Ls -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info --allow-root

# Copy the WordPress skeleton from this repo into the container
# This includes any themes and/or plugins we've added to the content/themes and content/plugins directories.
COPY /var/www/html /var/www/html
RUN chown -R www-data:www-data /var/www/html/*

# Install WordPress via wp-cli & move the default themes to our content dir
# Releases at https://core.svn.wordpress.org/tags/ and https://wordpress.org/news/category/releases/
ENV WORDPRESS_VERSION 4.7.5
RUN set -ex \
    && wp --allow-root core download --version=${WORDPRESS_VERSION} \
    && mv /var/www/html/wordpress/wp-content/themes/* /var/www/html/content/themes/

# Install HyperDB, https://wordpress.org/plugins/hyperdb
# Releases at https://wordpress.org/plugins/hyperdb/developers/ , though no SHA1 fingerprints are published
RUN set -ex \
    && export HYPERDB_VERSION=1.1 \
    && curl --retry 7 --fail -Ls -o /var/www/html/hyperdb.zip https://downloads.wordpress.org/plugin/hyperdb.${HYPERDB_VERSION}.zip \
    && unzip hyperdb.zip \
    && chown -R www-data:www-data /var/www/html/hyperdb \
    && mv hyperdb/db.php /var/www/html/content/. \
    && rm -rf /var/www/html/hyperdb.zip /var/www/html/hyperdb \
    && touch /var/www/html/content/db-config.php

# Install ztollman's object-cache.php or object caching to memcached
RUN set -ex \
    && curl --retry 7 --fail -Ls -o /var/www/html/content/object-cache.php https://raw.githubusercontent.com/tollmanz/wordpress-pecl-memcached-object-cache/master/object-cache.php

# The volume is defined after we install everything
VOLUME /var/www/html

CMD ["/usr/local/bin/containerpilot", \
    "apache2-foreground"]
