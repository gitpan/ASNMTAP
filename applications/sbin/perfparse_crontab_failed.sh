#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/10/21, v3.000.015, perfparse_crontab_failed.sh
# ----------------------------------------------------------------------------------------------------------

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

AMPATH=/opt/asnmtap-3.000.xxx

if [ "$ASNMTAP_PATH" ]; then
  AMPATH=$ASNMTAP_PATH
fi

for file in $( find $AMPATH/log/ -name 'perfdata-asnmtap.log-*-failed' ) 
do
  echo "Filename failed: '$file'";
  cat $file | $AMPATH/perfparse/bin/perfparse-log2mysql
  rv="$?"

  if [ ! "$rv" = "0" ]; then
    exec 3<&0
    exec 0<$file

    while read line
    do
      echo $line | $AMPATH/perfparse/bin/perfparse-log2mysql
    done

    exec 0<&3
  fi

  rm $file
done

exit 0

