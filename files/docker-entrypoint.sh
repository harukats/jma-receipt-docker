#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ $ORCA_DB_HOST != "localhost" ]; then
  # create db.conf (overwrite)
  cat << EOF > /etc/jma-receipt/db.conf
export DBNAME="$ORCA_DB_NAME"
export DBUSER="$ORCA_DB_USER"
export DBPASS="$ORCA_DB_PASS"
export DBHOST="$ORCA_DB_HOST"
export DBPORT="$ORCA_DB_PORT"
export PGHOST="$ORCA_DB_HOST"
export PGUSER="$ORCA_DB_USER"
export PGPASS="$ORCA_DB_PASS"
export DBENCODING="$ORCA_DB_ENCODING"
EOF

  # use db.conf as shell default profile
  cp /etc/jma-receipt/db.conf /etc/profile.d/jma-receipt.sh

  # create dbgroup.inc (overwrite)
  cat << EOF > /etc/jma-receipt/dbgroup.inc
db_group {
  type "PostgreSQL";
  port "$ORCA_DB_HOST:$ORCA_DB_PORT";
  name "$ORCA_DB_NAME";
  user "$ORCA_DB_USER";
  password "$ORCA_DB_PASS";
  redirect "log";
};
db_group "log" {
  priority 100;
  type "PostgreSQL";
  port "sub-jma-receipt";
  name "$ORCA_DB_NAME";
  file "/var/lib/jma-receipt/dbredirector/orca.log";
  redirect_port "localhost";
};
EOF

  # create .pgpass file
  cat << EOF > /root/.pgpass
$ORCA_DB_HOST:$ORCA_DB_PORT:*:$ORCA_DB_USER:$ORCA_DB_PASS
EOF
  chmod 600 /root/.pgpass \
    && cp -a /root/.pgpass /home/orca/.pgpass \
    && chown orca:orca /home/orca/.pgpass
else
  echo "DBENCODING=\"$ORCA_DB_ENCODING\"" > /etc/jma-receipt/db.conf
  /etc/init.d/postgresql start
fi

# setup ORCA database
dockerize -wait tcp://$ORCA_DB_HOST:$ORCA_DB_PORT -timeout 60s jma-setup

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
/etc/init.d/jma-receipt start

su - orca \
  -c "/usr/lib/jma-receipt/bin/jma-receipt-program-upgrade.sh \
    && /usr/lib/jma-receipt/bin/jma-plugin -c /etc/jma-receipt/jppinfo.list restore"

/etc/init.d/jma-receipt stop

# start supervisord
supervisord -n
