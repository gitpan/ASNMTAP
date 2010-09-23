#!/bin/sh

if [ ! -z "$1" ]; then
  PERL_AUTOINSTALL=0
  export PERL_AUTOINSTALL
  ASNMTAP_APPLICATIONS=1
  export ASNMTAP_APPLICATIONS
  ASNMTAP_PLUGINS=1
  export ASNMTAP_PLUGINS
  ASNMTAP_UID=705
  export ASNMTAP_UID
  ASNMTAP_GID=705
  export ASNMTAP_GID
  ASNMTAP_PATH=$1/asnmtap
  export ASNMTAP_PATH
  ASNMTAP_PROXY=0.0.0.0
  export ASNMTAP_PROXY

  perl Makefile.PL -n INSTALL_BASE=$1
else
  echo "INSTALL BASE PATH missing"
fi