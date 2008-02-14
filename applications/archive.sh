#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2008 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2008/02/13, v3.000.016, archive.sh
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

# Central Server ASNMTAP
# cd $AMPATH/applications; /usr/bin/env perl archive.pl -A ArchiveCT -c F -r T -d T

# Central Server Apache
# cd $AMPATH/applications; /usr/bin/env perl archive.pl -c T -r F -d F

# Distributed Server ASNMTAP
# cd $AMPATH/applications; /usr/bin/env perl archive.pl -A ArchiveCT -c T -r T -d F
