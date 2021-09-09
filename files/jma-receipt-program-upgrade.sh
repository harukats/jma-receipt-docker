#!/bin/bash

JMARECEIPT_ENV="/etc/jma-receipt/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

if [ `whoami` != "${ORCAUSER}" ]; then
  echo "${ORCAUSER}ユーザーで実行してください。"
  exit 1
fi

HOSPID=$(psql -At -c "SELECT kanritbl FROM tbl_syskanri WHERE kanricd = '1001' AND hospnum = 1" | nkf -w | sed -e 's/^.*\(JPN[0-9]*\).*$/\1/')
ACCESS_KEY=$(psql -At -c "SELECT access_key_1 FROM tbl_access_key WHERE hospnum = 1")

COB_LIBRARY_PATH="$PATCHLIBDIR":"$ORCALIBDIR":"$PANDALIB"
export COB_LIBRARY_PATH
$DBSTUB -dir $LDDIRECTORY -bd orcabt ORCBJOB -parameter "JBS0000001PRGMNT,01"

PATH=$SITESCRIPTSDIR/allways:$PATCHSCRIPTSDIR/allways:$SCRIPTSDIR/allways:$PATH
program_upgrade_online.sh "update" "01" "" "$HOSPID" "$ACCESS_KEY"

exit $?
