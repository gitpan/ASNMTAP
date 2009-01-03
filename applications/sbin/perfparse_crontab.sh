#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# � Copyright 2003-2009 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2009/mm/dd, v3.000.019, perfparse_crontab.sh
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

PERFPARSEPATH=/opt/asnmtap-3.000.xxx/perfparse

logFilename="$AMPATH/log/perfdata-asnmtap.log"

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
  epochFilenameFailed="$epochFilename-failed"

  echo "Filenames: '$logFilename', '$epochFilename', '$epochFilenameFailed'"
  mv $logFilename $epochFilename
  cat $epochFilename | $PERFPARSEPATH/bin/perfparse-log2mysql
  rv="$?"

  if [ "$rv" = "0" ]; then
    rm $epochFilename
  else
    mv $epochFilename $epochFilenameFailed
  fi
fi

exit $rv
