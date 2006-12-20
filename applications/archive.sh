#!/bin/sh

if [ -d /opt/asnmtap/cpan-shared/lib/perl5 ]; then
  PERL5LIB=${PERL5LIB:+$PERL5LIB:}/opt/asnmtap/cpan-shared/lib/perl5
  MANPATH=${MANPATH:+$MANPATH:}/opt/asnmtap/cpan-shared/share/man
  export PERL5LIB MANPATH
fi

AMPATH=/opt/asnmtap-3.000.xxx/applications

# Central Server
# cd $AMPATH; /usr/local/bin/perl archive.pl -A ArchiveCT -c T -r T -d T

# Distributed Server
# cd $AMPATH; /usr/local/bin/perl archive.pl -A ArchiveCT -c T -r T -d F
