#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# � Copyright 2003-2009 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2009/04/19, v3.000.020, holidayBundleSetDowntimes.sh
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

cd $AMPATH/applications/bin; /usr/bin/env perl holidayBundleSetDowntimes.pl
