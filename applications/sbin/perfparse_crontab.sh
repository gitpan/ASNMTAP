#!/bin/ksh
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/xx/xx, v3.000.012, perfparse_crontab.sh
# ----------------------------------------------------------------------------------------------------------

# export PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/etc:/usr/ccs/bin:/usr/bin:/opt/csw/bin:/usr/ucb:/usr/local/mysql/bin:${PATH}

# if [ -d /opt/asnmtap/cpan-shared/lib/perl5 ]; then
#   PERL5LIB=${PERL5LIB:+$PERL5LIB:}/opt/asnmtap/cpan-shared/lib/perl5
#   MANPATH=${MANPATH:+$MANPATH:}/opt/asnmtap/cpan-shared/share/man
#   export PERL5LIB MANPATH
# fi

# export LD_LIBRARY_PATH=/opt/asnmtap/ssl/lib:/usr/local/lib/mysql:/usr/local/lib:/usr/lib:${LD_LIBRARY_PATH}

umask 022

epoch=`/usr/local/bin/date '+%s'` 
epochFilename="/opt/asnmtap/log/perfdata-asnmtap.log-$epoch"

echo "$epochFilename";

mv /opt/asnmtap/log/perfdata-asnmtap.log $epochFilename
touch /opt/asnmtap/log/perfdata-asnmtap.log
/usr/local/bin/cat $epochFilename | /opt/asnmtap/perfparse/bin/perfparse-log2mysql
rm $epochFilename
