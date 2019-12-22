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

PASSWDFILE=${SYSCONFDIR}/passwd
COB_LIBRARY_PATH="$PATCHLIBDIR":"$ORCALIBDIR":"$PANDALIB"
export COB_LIBRARY_PATH
PWDCSQL="select count(*) from tbl_passwd;"

# tbl_passwdのレコード有無チェック
create_pgpass
PWDC=`psql ${DBCONNOPTION} -At -c "${PWDCSQL}" ${DBNAME}`
RC=$?
if [ $RC -ne 0 ] ;then
  echo "ERROR: tbl_passwd を読めませんでした。"
  exit 1
fi

# passwdファイルからSQL文を作成
TEMP1=$(mktemp)
cp -p ${PASSWDFILE} ${TEMP1}

TEMP2=$(mktemp)
export TEMP1
export TEMP2
trap "rm -f ${TEMP1}; rm -f ${TEMP2}" EXIT

/usr/bin/ruby <<RUBY_END
  fi = open(ENV['TEMP1'])
  fo = open(ENV['TEMP2'], 'w')

  while l = fi.gets
    pwary = l.chomp.split(":")
    fo.puts "INSERT INTO tbl_passwd (userid, password) \
             VALUES ('#{pwary[0]}', '#{pwary[1]}') \
             ON CONFLICT (userid) \
             DO UPDATE SET password = '#{pwary[1]}';"
  end

  fo.close
  fi.close
RUBY_END

${DBSTUB} -dir ${LDDIRECTORY} -bd orcabt ORCBSQL1 \
          -parameter "00,${TEMP2}"
if [ $? -ne 0 ] ; then 
  echo "パスワード設定処理 ... テーブル格納処理でエラーが発生しました。"
  exit 1
else
  echo "パスワード設定処理 ... 終了しました。"
  exit 0
fi
