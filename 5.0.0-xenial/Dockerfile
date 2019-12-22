FROM ubuntu:xenial

LABEL maintainer 'harukats <github.com/harukats>'

# env
ENV ORMASTER_PASS=ormaster \
    ORMASTER_PASS_RESET=false \
    ORCA_DB_NAME=orca \
    ORCA_DB_USER=orca \
    ORCA_DB_PASS="" \
    ORCA_DB_HOST=localhost \
    ORCA_DB_PORT=5432 \
    ORCA_DB_ENCODING=EUC-JP \
    ORCA_VERSION=5.0 \
    ORCA_DISTRIBUTION=xenial50 \
    DOCKERIZE_VERSION=v0.6.1 \
    DEBIAN_FRONTEND=noninteractive

# set timezone to JST
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# install sudo, wget, ca-certificates, gnupg, supervisor and dockerize
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
      sudo wget ca-certificates gnupg supervisor uuid-runtime \
    && apt-get -y dist-upgrade \
    && wget -q \
      https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz -O - \
      | tar -xz -C /usr/local/bin

# add ORCA repository and install ORCA
RUN wget -q https://ftp.orca.med.or.jp/pub/ubuntu/archive.key -O - \
      | apt-key add - \
    && wget -q -O /etc/apt/sources.list.d/jma-receipt-$ORCA_DISTRIBUTION.list \
      https://ftp.orca.med.or.jp/pub/ubuntu/jma-receipt-$ORCA_DISTRIBUTION.list \
    && apt-get update \
    && apt-get -y install --no-install-recommends jma-receipt jma-receipt-pusher push-exchanger

# install patch for updating ORCA-center server
RUN wget http://ftp.orca.med.or.jp/pub/etc/install_modules_for_ftp.tgz -O - | tar xvzf - -C /tmp \
    && sudo -u orca bash -c 'cd /tmp/install_modules_for_ftp; ./install_modules.sh' \
    && rm -rf /tmp/install_modules_for_ftp

# copy supervisor config file and delete pusher.conf
COPY files/jma-receipt.conf /etc/supervisor/conf.d/jma-receipt.conf
RUN rm -f /etc/supervisor/conf.d/pusher.conf

# copy passwd reset script
COPY files/passwd_force_update.sh /usr/lib/jma-receipt/bin/passwd_force_update.sh
RUN chmod +x /usr/lib/jma-receipt/bin/passwd_force_update.sh

# copy docker-entrypoint script
COPY files/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# create data volume
RUN mkdir -p /data/etc /data/lib /data/log /usr/local/lib/push-exchanger/plugin \
    && mv /etc/jma-receipt /data/etc \
    && mv /var/lib/jma-receipt /data/lib \
    && mv /var/log/jma-receipt /data/log \
    && ln -sf /data/etc/jma-receipt /etc/jma-receipt \
    && ln -sf /data/lib/jma-receipt /var/lib/jma-receipt \
    && ln -sf /data/log/jma-receipt /var/log/jma-receipt

VOLUME [ "/data" ]

# expose
EXPOSE 8000

CMD [ "docker-entrypoint.sh" ]