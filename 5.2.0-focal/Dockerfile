FROM ubuntu:focal

LABEL maintainer 'harukats <github.com/harukats>'

# build env
ENV ORCA_DISTRIBUTION=focal52 \
    PG_VERSION=12 \
    DOCKERIZE_VERSION=v0.6.1 \
    DEBIAN_FRONTEND=noninteractive

# set timezone to JST
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# set locale
RUN apt-get update \
    && apt-get install locales \
    && sed -i 's/^# ja_JP/ja_JP/' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=ja_JP.UTF-8

# install pre-require packages and dockerize
RUN apt-get -y install --no-install-recommends \
      sudo wget ca-certificates gnupg supervisor uuid-runtime qpdf gcc cron \
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

# copy supervisor config file and delete pusher.conf
COPY files/jma-receipt_orca52.conf /etc/supervisor/conf.d/jma-receipt.conf
RUN rm -f /etc/supervisor/conf.d/pusher.conf

# copy passwd reset script
COPY files/passwd_force_update.sh /usr/lib/jma-receipt/bin/passwd_force_update.sh
RUN chmod +x /usr/lib/jma-receipt/bin/passwd_force_update.sh

# copy program upgrade script
COPY files/jma-receipt-program-upgrade.sh /usr/lib/jma-receipt/bin/jma-receipt-program-upgrade.sh
RUN chmod +x /usr/lib/jma-receipt/bin/jma-receipt-program-upgrade.sh

# copy start script
COPY files/jma-receipt_orca52.sh /usr/local/bin/jma-receipt.sh
RUN chmod +x /usr/local/bin/jma-receipt.sh

# custom postgresql options
RUN echo "host all all all md5" >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf
RUN echo "listen_addresses = '*'" >> /etc/postgresql/$PG_VERSION/main/postgresql.conf

# create data volume
RUN mkdir -p /data/etc /data/lib /data/log /usr/local/lib/push-exchanger/plugin \
    && mv /etc/jma-receipt /data/etc \
    && mv /var/lib/jma-receipt /data/lib \
    && mv /var/lib/postgresql /data/lib \
    && mv /var/log/jma-receipt /data/log \
    && ln -sf /data/etc/jma-receipt /etc/jma-receipt \
    && ln -sf /data/lib/jma-receipt /var/lib/jma-receipt \
    && ln -sf /data/lib/postgresql /var/lib/postgresql \
    && ln -sf /data/log/jma-receipt /var/log/jma-receipt

# runtime env
ENV LANG=ja_JP.UTF-8 \
    ORMASTER_PASS=ormaster \
    ORMASTER_PASS_RESET=false \
    ORCA_DB_NAME=orca \
    ORCA_DB_USER=orca \
    ORCA_DB_PASS=orca_password \
    ORCA_DB_HOST=localhost \
    ORCA_DB_PORT=5432 \
    ORCA_DB_ENCODING=EUC-JP

# expose
EXPOSE 5432 8000 9400

CMD [ "jma-receipt.sh" ]
