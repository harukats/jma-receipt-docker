#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

DB_CONF="
export DBNAME=${ORCA_DB_NAME}\n
export DBUSER=${ORCA_DB_USER}\n
export DBPASS=${ORCA_DB_PASS}\n
export DBHOST=${ORCA_DB_HOST}\n
export DBPORT=${ORCA_DB_PORT}\n
export PGHOST=${ORCA_DB_HOST}\n
export PGUSER=${ORCA_DB_USER}\n
export PGPASS=${ORCA_DB_PASS}\n
export DBENCODING=${ORCA_DB_ENCODING}\n
"
DB_GROUP_INC="
db_group {\n
  type \"PostgreSQL\";\n
  port \"${ORCA_DB_HOST}:${ORCA_DB_PORT}\";\n
  name \"${ORCA_DB_NAME}\";\n
  user \"${ORCA_DB_USER}\";\n
  password \"${ORCA_DB_PASS}\";\n
};\n
"
PGPASS="${ORCA_DB_HOST}:${ORCA_DB_PORT}:*:${ORCA_DB_USER}:${ORCA_DB_PASS}"

if [ $ORCA_DB_HOST != "localhost" ]; then
  # create db.conf (overwrite)
  echo -e $DB_CONF > /etc/jma-receipt/db.conf

  # use db.conf as shell default profile
  cp /etc/jma-receipt/db.conf /etc/profile.d/jma-receipt.sh

  # create dbgroup.inc (overwrite)
  echo -e $DB_GROUP_INC > /etc/jma-receipt/dbgroup.inc

  # create .pgpass file
  echo $PGPASS > /root/.pgpass
  chmod 600 /root/.pgpass \
    && cp -a /root/.pgpass /home/orca/.pgpass \
    && chown orca:orca /home/orca/.pgpass
else
  # use local postgresql
  echo "DBENCODING=${ORCA_DB_ENCODING}" > /etc/jma-receipt/db.conf
  /etc/init.d/postgresql start
fi

# setup ORCA database
dockerize -wait tcp://$ORCA_DB_HOST:$ORCA_DB_PORT -timeout 60s jma-setup

# change orca user password
if [ $ORCA_DB_HOST == "localhost" ]; then
  su - postgres \
    -c "psql -c \"ALTER USER orca WITH LOGIN PASSWORD '${ORCA_DB_PASS}'\""
fi

# update ormaster password if passwd file doesn't exist or require reset
if [ ! -e /etc/jma-receipt/passwd ] || "${ORMASTER_PASS_RESET}"; then
  echo "ormaster:$(md5pass $ORMASTER_PASS):" > /etc/jma-receipt/passwd
  chmod 600 /etc/jma-receipt/passwd && chown orca:orca /etc/jma-receipt/passwd
  su - orca -c /usr/lib/jma-receipt/bin/passwd_force_update.sh
fi

# edit push-exchanger.yml
sed -i -e "s/^\(:api_user:\s*\).*$/\1ormaster/g" \
       -e "s/^\(:api_key:\s*\).*$/\1$ORMASTER_PASS/g" \
  /etc/push-exchanger/push-exchanger.yml

# upgrade program and restore plugins
ACCESS_KEY=$(su - orca -c \
  "psql -At -c \"SELECT access_key_1 FROM tbl_access_key WHERE hospnum = 1\"" \
)

if [ ! -z $ACCESS_KEY ]; then
  su - orca -c "/usr/sbin/jma-receipt" &

  su - orca \
    -c "/usr/lib/jma-receipt/bin/jma-receipt-program-upgrade.sh \
      && /usr/lib/jma-receipt/bin/jma-plugin -c /etc/jma-receipt/jppinfo.list restore"

  kill -9 $(cat /home/orca/monitor.pid)
fi

# start supervisord
supervisord -n
