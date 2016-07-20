# a minimal Nginx container including containerbuddy and a simple virtulhost config
FROM autopilotpattern/nginx:latest

# Build-time metadata as defined at http://label-schema.org
# with added usage described in https://microbadger.com/#/labels
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/nginx/Dockerfile" \
    org.label-schema.name="Autopilot Pattern Nginx for WordPress" \
    org.label-schema.url="https://github.com/autopilotpattern/wordpress" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/autopilotpattern/wordpress"

# Add our configuration files
COPY etc /etc
