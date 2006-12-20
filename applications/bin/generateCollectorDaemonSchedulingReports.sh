#!/bin/sh

# if [ -d /opt/asnmtap/cpan-shared/lib/perl5 ]; then
#   PERL5LIB=${PERL5LIB:+$PERL5LIB:}/opt/asnmtap/cpan-shared/lib/perl5
#   MANPATH=${MANPATH:+$MANPATH:}/opt/asnmtap/cpan-shared/share/man
#   export PERL5LIB MANPATH
# fi

# export LD_LIBRARY_PATH=/opt/asnmtap/ssl/lib:/usr/local/lib/mysql:/usr/local/lib:/usr/lib:${LD_LIBRARY_PATH}

AMPATH=/opt/asnmtap-3.000.xxx/applications/bin

cd $AMPATH; /usr/local/bin/perl generateCollectorDaemonSchedulingReports.pl
