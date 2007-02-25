#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/02/25, v3.000.013, archive.sh
# ----------------------------------------------------------------------------------------------------------

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

AMPATH=/opt/asnmtap-3.000.xxx/applications

# Central Server
# cd $AMPATH; /usr/local/bin/perl archive.pl -A ArchiveCT -c T -r T -d T

# Distributed Server
# cd $AMPATH; /usr/local/bin/perl archive.pl -A ArchiveCT -c T -r T -d F
