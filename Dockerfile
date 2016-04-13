FROM php:5.6-apache

RUN a2enmod rewrite

# install the PHP extensions we need, and other packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        less \
        libpng12-dev \
        libjpeg-dev \
        unzip \
        curl \
        nfs-common \
        libmemcached-dev \
        vim \
    && rm -rf /var/lib/apt/lists/* \
    && pecl install memcached \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd mysqli opcache \
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


# The our helper/glue scripts and configuration for this specific app
COPY bin /usr/local/bin
COPY etc /etc

# Add Containerbuddy and its configuration
ENV CONTAINERBUDDY_VER 1.3.0
ENV CONTAINERBUDDY file:///etc/containerbuddy.json

RUN export CONTAINERBUDDY_CHECKSUM=c25d3af30a822f7178b671007dcd013998d9fae1 \
    && curl -Lso /tmp/containerbuddy.tar.gz \
         "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VER}/containerbuddy-${CONTAINERBUDDY_VER}.tar.gz" \
    && echo "${CONTAINERBUDDY_CHECKSUM}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /usr/local/bin \
    && rm /tmp/containerbuddy.tar.gz

# Install Consul template
# Releases at https://releases.hashicorp.com/consul-template/
ENV CONSUL_TEMPLATE_VERSION 0.14.0
ENV CONSUL_TEMPLATE_SHA1 7c70ea5f230a70c809333e75fdcff2f6f1e838f29cfb872e1420a63cdf7f3a78
RUN curl --retry 7 -Lso /tmp/consul-template.zip "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_TEMPLATE_SHA1}  /tmp/consul-template.zip" | sha256sum -c \
    && unzip /tmp/consul-template.zip -d /usr/local/bin \
    && rm /tmp/consul-template.zip

# install wp-cli, http://wp-cli.org
ENV WP_CLI_CONFIG_PATH /var/www/html/wp-cli.yml
RUN curl -Ls -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info --allow-root

# copy the WordPress skeleton from this repo into the container
# this includes any themes and/or plugins we've added to the content/themes and content/plugins, etc, directories.
COPY /var/www/html /var/www/html


ENV WORDPRESS_VERSION 4.4.2
# install WordPress via wp-cli & copy the default themes to our content dir
RUN wp --allow-root core download --version=${WORDPRESS_VERSION} \
    && mv /var/www/html/wordpress/wp-content/themes/* /var/www/html/content/themes/


# install HyperDB, https://wordpress.org/plugins/hyperdb
# Releases at https://wordpress.org/plugins/hyperdb/developers/ , though no SHA1 fingerprints are published
ENV HYPERDB_VERSION 1.1
RUN curl -Ls -o /var/www/html/hyperdb.zip https://downloads.wordpress.org/plugin/hyperdb.${HYPERDB_VERSION}.zip \
    && unzip hyperdb.zip \
    && chown -R www-data:www-data /var/www/html/hyperdb \
    && mv hyperdb/db.php /var/www/html/content/. \
    && rm -rf /var/www/html/hyperdb.zip /var/www/html/hyperdb \
    && touch /var/www/html/content/db-config.php

# install ztollman's object-cache.php or object caching to memcached
RUN curl -Ls -o /var/www/html/content/object-cache.php https://raw.githubusercontent.com/tollmanz/wordpress-pecl-memcached-object-cache/master/object-cache.php


# the volume is defined after we install everything
VOLUME /var/www/html

CMD ["/usr/local/bin/containerbuddy", \
    "apache2-foreground"]
