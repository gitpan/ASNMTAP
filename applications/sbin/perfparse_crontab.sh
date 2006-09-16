#!/bin/sh

epoch=`/usr/local/bin/date '+%s'`
epochFilename="/opt/asnmtap/log/perfdata-asnmtap.log-$epoch"
 
echo "$epochFilename";

mv /opt/asnmtap/log/perfdata-asnmtap.log $epochFilename
cat $epochFilename | /opt/asnmtap/perfparse/bin/perfparse-log2mysql 
rm $epochFilename
