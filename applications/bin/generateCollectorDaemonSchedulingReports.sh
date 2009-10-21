#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2009 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2009/mm/dd, v3.001.001, generateCollectorDaemonSchedulingReports.sh
# ----------------------------------------------------------------------------------------------------------

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

AMPATH=/opt/asnmtap

if [ "$ASNMTAP_PATH" ]; then
  AMPATH=$ASNMTAP_PATH
fi

cd $AMPATH/applications/bin; /usr/bin/env perl generateCollectorDaemonSchedulingReports.pl
