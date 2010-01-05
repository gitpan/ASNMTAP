#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2010 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2010/01/05, v3.001.002, importDataThroughCatalog.sh
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

cd $AMPATH/applications/bin; /usr/bin/env perl importDataThroughCatalog.pl "$@"
