#!/bin/sh

AMPATH=/opt/asnmtap-3.000.xxx
ASNMTAPUSER=asnmtap
WWWUSER=apache                                               # nobody


echo "chown -R $ASNMTAPUSER:$ASNMTAPUSER $AMPATH"
chown -R $ASNMTAPUSER:$ASNMTAPUSER $AMPATH

echo "chown -R $ASNMTAPUSER:$WWWUSER $AMPATH/applications/htmlroot/nav"
chown -R $ASNMTAPUSER:$WWWUSER $AMPATH/applications/htmlroot/nav
echo "chown -R $ASNMTAPUSER:$WWWUSER $AMPATH/applications/htmlroot/pdf"
chown -R $ASNMTAPUSER:$WWWUSER $AMPATH/applications/htmlroot/pdf

echo "chown -R $WWWUSER:$ASNMTAPUSER $AMPATH/applications/tmp"
chown -R $WWWUSER:$ASNMTAPUSER $AMPATH/applications/tmp
echo "chown -R $WWWUSER:$ASNMTAPUSER $AMPATH/plugins/tmp"
chown -R $WWWUSER:$ASNMTAPUSER $AMPATH/plugins/tmp

echo "chmod 775 $AMPATH/applications/tmp/config"
chmod 775 $AMPATH/applications/tmp/config


echo "cd $AMPATH"
cd $AMPATH
chmod 644 *.*
chmod 755 *.sh

echo "cd $AMPATH/applications"
cd $AMPATH/applications
chmod 644 *.*
chmod 755 *.pl *.sh

echo "cd $AMPATH/applications/bin"
cd $AMPATH/applications/bin
chmod 644 *.*
chmod 755 *.pl *.sh

echo "cd $AMPATH/applications/custom"
cd $AMPATH/applications/custom
chmod 644 *.*

echo "cd $AMPATH/applications/etc"
cd $AMPATH/applications/etc
chmod 644 *.*

echo "cd $AMPATH/applications/htmlroot"
cd $AMPATH/applications/htmlroot
chmod 644 *.*
chmod 755 *.js

echo "cd $AMPATH/applications/htmlroot/cgi-bin"
cd $AMPATH/applications/htmlroot/cgi-bin
chmod 644 *.*
chmod 755 *.cgi *.php *.pl *.sh  perf*.png

echo "cd $AMPATH/applications/htmlroot/cgi-bin/admin"
cd $AMPATH/applications/htmlroot/cgi-bin/admin
chmod 644 *.*
chmod 755 *.pl

echo "cd $AMPATH/applications/htmlroot/cgi-bin/sadmin"
cd $AMPATH/applications/htmlroot/cgi-bin/sadmin
chmod 644 *.*
chmod 755 *.pl

echo "cd $AMPATH/applications/htmlroot/cgi-bin/moderator"
cd $AMPATH/applications/htmlroot/cgi-bin/moderator
chmod 644 *.*
chmod 755 *.pl

echo "cd $AMPATH/applications/htmlroot/img"
cd $AMPATH/applications/htmlroot/img
chmod 644 *.*

echo "cd $AMPATH/applications/htmlroot/img/logos"
cd $AMPATH/applications/htmlroot/img/logos
chmod 644 *.*

echo "cd $AMPATH/applications/htmlroot/nav"
cd $AMPATH/applications/htmlroot/nav
chmod 644 *.*
chmod 644 */*.*
chmod 644 */*/*.*

echo "cd $AMPATH/applications/htmlroot/pdf"
cd $AMPATH/applications/htmlroot/pdf
chmod 644 *.*

echo "cd $AMPATH/applications/htmlroot/sound"
cd $AMPATH/applications/htmlroot/sound
chmod 644 *.*

echo "cd $AMPATH/applications/master"
cd $AMPATH/applications/master
chmod 644 *.*
chmod 755 *.sh

echo "cd $AMPATH/applications/sbin/"
cd $AMPATH/applications/sbin/
chmod 644 *.*
chmod 755 *.pl *.sh

echo "cd $AMPATH/applications/slave"
cd $AMPATH/applications/slave
chmod 644 *.*
chmod 755 *.sh

echo "cd $AMPATH/applications/tmp/"
cd $AMPATH/applications/tmp/
chmod 644 *.*

echo "cd $AMPATH/applications/tmp/cgisess"
cd $AMPATH/applications/tmp/cgisess
chmod 644 *.*

echo "cd $AMPATH/applications/tmp/config"
cd $AMPATH/applications/tmp/config
chmod 775 *.*

echo "cd $AMPATH/applications/tools/"
cd $AMPATH/applications/tools/
chmod 644 *.*

echo "cd $AMPATH/applications/tools/mysql"
cd $AMPATH/applications/tools/mysql
chmod 644 *.*
chmod 755 *.sh

echo "cd $AMPATH/applications/tools/resources"
cd $AMPATH/applications/tools/resources
chmod 644 *.*
chmod 755 *.js

echo "cd $AMPATH/applications/tools/templates"
cd $AMPATH/applications/tools/templates
chmod 644 *.*
chmod 755 *.sh

echo "cd $AMPATH/applications/tools/templates/master"
cd $AMPATH/applications/tools/templates/master
chmod 644 *.*
chmod 755 *.sh

echo "cd $AMPATH/applications/tools/templates/slave"
cd $AMPATH/applications/tools/templates/slave
chmod 644 *.*
chmod 755 *.sh


echo "cd $AMPATH/log"
cd $AMPATH/log
chmod 644 *.*


echo "cd $AMPATH/pid"
cd $AMPATH/pid
chmod 644 *.*


echo "cd $AMPATH/plugins"
cd $AMPATH/plugins
chmod 644 *.*
chmod 755 *.pl

echo "cd $AMPATH/plugins/dtd"
cd $AMPATH/plugins/dtd
chmod 644 *.*

echo "cd $AMPATH/plugins/nagios"
cd $AMPATH/plugins/nagios
chmod 644 *.*
chmod 755 *.pl

echo "cd $AMPATH/plugins/nagios/templates"
cd $AMPATH/plugins/nagios/templates
chmod 644 *.*
chmod 755 *.pl

echo "cd $AMPATH/plugins/nagios/templates/dtd"
cd $AMPATH/plugins/nagios/templates/dtd
chmod 644 *.*

echo "cd $AMPATH/plugins/nagios/templates/xml"
cd $AMPATH/plugins/nagios/templates/xml
chmod 644 *.*

echo "cd $AMPATH/plugins/ssl"
cd $AMPATH/plugins/ssl
chmod 644 *.*
chmod 600 *.p12

echo "cd $AMPATH/plugins/ssl/crt"
cd $AMPATH/plugins/ssl/crt
chmod 644 *.*

echo "cd $AMPATH/plugins/ssl/key"
cd $AMPATH/plugins/ssl/key
chmod 644 *.*

echo "cd $AMPATH/plugins/templates"
cd $AMPATH/plugins/templates
chmod 644 *.*
chmod 755 *.pl

echo "cd $AMPATH/plugins/templates/dtd"
cd $AMPATH/plugins/templates/dtd
chmod 644 *.*

echo "cd $AMPATH/plugins/templates/ssl"
cd $AMPATH/plugins/templates/ssl
chmod 644 *.*

echo "cd $AMPATH/plugins/templates/ssl/crt"
cd $AMPATH/plugins/templates/ssl/crt
chmod 644 *.*

echo "cd $AMPATH/plugins/templates/ssl/key"
cd $AMPATH/plugins/templates/ssl/key
chmod 644 *.*

echo "cd $AMPATH/plugins/templates/xml"
cd $AMPATH/plugins/templates/xml
chmod 644 *.*

echo "cd $AMPATH/plugins/tools"
cd $AMPATH/plugins/tools
chmod 644 *.*
chmod 755 *.pl

echo "cd $AMPATH/plugins/tmp"
cd $AMPATH/plugins/tmp
chmod 644 *.*

echo "cd $AMPATH/plugins/xml"
cd $AMPATH/plugins/xml
chmod 644 *.*


echo "cd $AMPATH/results"
cd $AMPATH/results
chmod 644 *.*

