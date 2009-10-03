#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2009 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2009/mm/dd, v3.001.000, archive.sh
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

# ----------------------------------------------------------------------------------------------------------

# Central Server ASNMTAP
# cd $AMPATH/applications; /usr/bin/env perl archive.pl -A ArchiveCT -c F -r T -d T

# Distributed Server ASNMTAP
# cd $AMPATH/applications; /usr/bin/env perl archive.pl -A ArchiveCT -c F -r T -d F

# ----------------------------------------------------------------------------------------------------------

# Central Server Apache for user <apache>
# crontab -l
# 0 1 * * * cd /opt/monitoring/asnmtap/applications; /usr/bin/env perl archive.pl -c T -r F -d F > /dev/null

# Distributed Server Apache for user <apache>
# crontab -l
# 0 1 * * * cd /opt/monitoring/asnmtap/applications; /usr/bin/env perl archive.pl -c T -r F -d F > /dev/null

# ----------------------------------------------------------------------------------------------------------
