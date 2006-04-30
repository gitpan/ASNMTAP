#!/bin/sh

AMPATH=/opt/asnmtap-3.000.xxx
WWWUSER=apache

chmod 755 $AMPATH
chown -R  asnmtap:asnmtap $AMPATH
chown -R $WWWUSER:asnmtap $AMPATH/applications/tmp
chown -R $WWWUSER:asnmtap $AMPATH/plugins/tmp

cd $AMPATH
chmod 644 *.*
chmod 755 *.sh


cd $AMPATH/applications
chmod 644 *.*
chmod 755 *.pl *.sh

cd $AMPATH/applications/bin/
chmod 644 *.*
chmod 755 *.pl *.sh

cd $AMPATH/applications/custom/
chmod 644 *.*

cd $AMPATH/applications/etc/
chmod 644 *.*

cd $AMPATH/applications/htmlroot/
chmod 644 *.*

cd $AMPATH/applications/htmlroot/cgi-bin
chmod 644 *.*
chmod 755 *.cgi *.php *.pl *.sh 

cd $AMPATH/applications/htmlroot/cgi-bin/admin
chmod 644 *.*
chmod 755 *.pl

cd $AMPATH/applications/htmlroot/cgi-bin/sadmin
chmod 644 *.*
chmod 755 *.pl

cd $AMPATH/applications/htmlroot/cgi-bin/moderator
chmod 644 *.*
chmod 755 *.pl

cd $AMPATH/applications/htmlroot/img
chmod 644 *.*

cd $AMPATH/applications/htmlroot/img/logos
chmod 644 *.*

cd $AMPATH/applications/htmlroot/pdf
chmod 644 *.*

cd $AMPATH/applications/htmlroot/sound
chmod 644 *.*

cd $AMPATH/applications/master
chmod 644 *.*
chmod 755 *.sh

cd $AMPATH/applications/sbin/
chmod 644 *.*
chmod 755 *.pl *.sh

cd $AMPATH/applications/slave
chmod 644 *.*
chmod 755 *.sh

cd $AMPATH/applications/tmp/
chmod 644 *.*

cd $AMPATH/applications/tmp/cgisess
chmod 644 *.*

chmod 775 $AMPATH/applications/tmp/config

cd $AMPATH/applications/tools/
chmod 644 *.*

cd $AMPATH/applications/tools/mysql
chmod 644 *.*

cd $AMPATH/applications/tools/resources
chmod 644 *.*

cd $AMPATH/applications/tools/templates
chmod 644 *.*
chmod 755 *.sh

cd $AMPATH/applications/tools/templates/master
chmod 644 *.*
chmod 755 *.sh

cd $AMPATH/applications/tools/templates/slave
chmod 644 *.*
chmod 755 *.sh


cd $AMPATH/plugins
chmod 644 *.*
chmod 755 *.pl

cd $AMPATH/plugins/dtd
chmod 644 *.*


cd $AMPATH/plugins/nagios
chmod 644 *.*
chmod 755 *.pl

cd $AMPATH/plugins/nagios/templates
chmod 755 *.pl

cd $AMPATH/plugins/nagios/templates/dtd
chmod 644 *.*

cd $AMPATH/plugins/nagios/templates/xml
chmod 644 *.*


cd $AMPATH/plugins/ssl
chmod 644 *.*
chmod 600 *.p12

cd $AMPATH/plugins/ssl/crt
chmod 644 *.*

cd $AMPATH/plugins/ssl/key
chmod 644 *.*


cd $AMPATH/plugins/templates
chmod 644 *.*
chmod 755 *.pl

cd $AMPATH/plugins/templates/dtd
chmod 644 *.*

cd $AMPATH/plugins/templates/ssl
chmod 644 *.*

cd $AMPATH/plugins/templates/ssl/crt
chmod 644 *.*

cd $AMPATH/plugins/templates/ssl/key
chmod 644 *.*

cd $AMPATH/plugins/templates/xml
chmod 644 *.*


cd $AMPATH/plugins/tools
chmod 644 *.*
chmod 755 *.pl


cd $AMPATH/plugins/tmp
chmod 644 *.*

cd $AMPATH/plugins/xml
chmod 644 *.*


cd $AMPATH/results
chmod 644 *.*

