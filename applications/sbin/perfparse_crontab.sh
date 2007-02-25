#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/02/25, v3.000.013, perfparse_crontab.sh
# ----------------------------------------------------------------------------------------------------------

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

logFilename="/opt/asnmtap/log/perfdata-asnmtap.log"

if [ -e "$logFilename" ]; then
  if [ -e "/usr/local/bin/date" ]; then
    epoch=`/usr/local/bin/date '+%s'`
  elif [ -e "/usr/bin/date" ]; then
    epoch=`/usr/bin/date '+%s'`
  elif [ -e "/bin/date" ]; then
    epoch=`/bin/date '+%s'`
  else
    exit 1;
  fi

  epochFilename="$logFilename-$epoch"

  echo "Filenames: '$logFilename', '$epochFilename'";
  mv $logFilename $epochFilename
  cat $epochFilename | /opt/asnmtap/perfparse/bin/perfparse-log2mysql
  rm $epochFilename
fi

