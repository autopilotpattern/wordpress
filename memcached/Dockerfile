FROM debian:jessie

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r memcache && useradd -r -g memcache memcache

RUN apt-get update && apt-get install -y --no-install-recommends \
		libevent-2.0-5 \
	&& rm -rf /var/lib/apt/lists/*

ENV MEMCACHED_VERSION 1.4.25
ENV MEMCACHED_SHA1 7fd0ba9283c61204f196638ecf2e9295688b2314

RUN buildDeps='curl gcc libc6-dev libevent-dev make perl' \
	&& set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& curl -SL "http://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz" -o memcached.tar.gz \
	&& echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/memcached \
	&& tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1 \
	&& rm memcached.tar.gz \
	&& cd /usr/src/memcached \
	&& ./configure \
	&& make \
	&& make install \
	&& cd / && rm -rf /usr/src/memcached \
	&& apt-get purge -y --auto-remove $buildDeps


# install python for entrypoint
RUN apt-get update \
    && apt-get install -y \
		netcat \
    curl

COPY containerbuddy/* /opt/containerbuddy/

# Install Containerbuddy
# Releases at https://github.com/joyent/containerbuddy/releases
ENV CONTAINERBUDDY_VERSION 0.1.1
ENV CONTAINERBUDDY_SHA1 3163e89d4c95b464b174ba31733946ca247e068e
RUN curl --retry 7 -Lso /tmp/containerbuddy.tar.gz "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VERSION}/containerbuddy-${CONTAINERBUDDY_VERSION}.tar.gz" \
    && echo "${CONTAINERBUDDY_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /opt/containerbuddy \
    && rm /tmp/containerbuddy.tar.gz



COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
user memcache
CMD ["/opt/containerbuddy/containerbuddy", \
    "memcached", \
		"-l", \
		"0.0.0.0"]
