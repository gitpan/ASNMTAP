#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/10/21, v3.000.015, archive.sh
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
# cd $AMPATH/applications; /usr/local/bin/perl archive.pl -A ArchiveCT -c F -r T -d T

# Central Server Apache
# cd $AMPATH/applications; /usr/local/bin/perl archive.pl -c T -r F -d F

# Distributed Server ASNMTAP
# cd $AMPATH/applications; /usr/local/bin/perl archive.pl -A ArchiveCT -c T -r T -d F
