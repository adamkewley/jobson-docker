FROM ubuntu:16.04

RUN apt update && apt install -y \
    nginx \
    openjdk-8-jre \
    supervisor

# Install UI assets + reverse proxy
COPY target/jobson-ui /usr/share/nginx/html
COPY default.conf /etc/nginx/conf.d/default.conf

# Install jobson binary onto PATH
COPY target/jobson-server /usr/local/bin

# Setup server acct. + workspace area (home dir)
RUN groupadd -r jobson && useradd --no-log-init -r -g jobson jobson
RUN mkdir -p /home/jobson && chown jobson:jobson /home/jobson
USER jobson
RUN  cd /home/jobson && jobson new --demo  # so a blank img boot shows *something*
USER root

EXPOSE 80

COPY supervisord.conf /etc/supervisord.conf
CMD ["supervisord", "--configuration", "/etc/supervisord.conf", "--nodaemon"]
