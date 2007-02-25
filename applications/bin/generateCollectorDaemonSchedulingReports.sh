#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/02/25, v3.000.013, generateCollectorDaemonSchedulingReports.sh
# ----------------------------------------------------------------------------------------------------------

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

AMPATH=/opt/asnmtap-3.000.xxx/applications/bin

cd $AMPATH; /usr/local/bin/perl generateCollectorDaemonSchedulingReports.pl
