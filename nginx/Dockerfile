# a minimal Nginx container including Containerbuddy and a simple virtulhost config
FROM gliderlabs/alpine:3.3

# install nginx and tooling we need
RUN apk update && apk add \
    nginx \
    curl \
    unzip \
    bash \
    && rm -rf /var/cache/apk/*

# we use consul-template to re-write our Nginx virtualhost config
RUN curl -Lo /tmp/consul_template_0.11.0_linux_amd64.zip https://github.com/hashicorp/consul-template/releases/download/v0.11.0/consul_template_0.11.0_linux_amd64.zip && \
    unzip /tmp/consul_template_0.11.0_linux_amd64.zip && \
    mv consul-template /bin

# get Containerbuddy release
RUN export CB=containerbuddy-0.1.1 &&\
   curl -Lo /tmp/${CB}.tar.gz \
   https://github.com/joyent/containerbuddy/releases/download/0.1.1/${CB}.tar.gz && \
   tar -xz -f /tmp/${CB}.tar.gz && \
   mv /containerbuddy /bin/

# add Containerbuddy configuration and onChange handler
COPY containerbuddy.json /etc/containerbuddy/

# add Nginx virtualhost configuration
COPY nginx.conf /etc/nginx/nginx.conf

# add Nginx virtualhost template that we'll overwrite
COPY nginx.conf.ctmpl /etc/containerbuddy/

EXPOSE 80
