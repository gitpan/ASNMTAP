#! /usr/bin/perl -w -I ..
#
# ... Tests via check_xml.pl
#
# $Id: check_xml.t, v 1.0 2006/02/01 Alex Peeters Exp $
#

use strict;
use Test;
use ASNMTAP::Asnmtap::Plugins::NPTest;

use vars qw($tests);
BEGIN {$tests = 23; plan tests => $tests}

my $t;
my $prefix = '../plugins/nagios/templates';
my $plugin = 'check_xml.pl';

if ( -x "$prefix/$plugin" ) {
  $t += checkCmd( "$prefix/$plugin -V", 3, "/$plugin/");
  $t += checkCmd( "$prefix/$plugin -h", 3);
  $t += checkCmd( "$prefix/$plugin", 3, '/Missing XML file/');
  $t += checkCmd( "$prefix/$plugin -F $prefix/xml/doNotExist", 3, '/Missing hostname/');
  $t += checkCmd( "$prefix/$plugin -F $prefix/xml/doNotExist -H hostname", 3, '/Missing service/');
  $t += checkCmd( "$prefix/$plugin -F $prefix/xml/doNotExist -H hostname -s service ", 3, '/Missing interval/');
  $t += checkCmd( "$prefix/$plugin -F $prefix/xml/doNotExist -H hostname -s service -i interval", 3, '/Missing environment/');
  $t += checkCmd( "$prefix/$plugin -F $prefix/xml/doNotExist -H hostname -s service -i interval -e P ", 3, '/UNKNOWN - Check Nagios by XML: The XML file \'[//\w]+\' doesn\'t exist|/');
  $t += checkCmd( "$prefix/$plugin -F $prefix/xml/nagios-1.0.xml -H hostname -s service -e P -i interval", 3, '/ERROR: Content Error: - Host: Host Name ... ne hostname - Service: Service Name ... ne service - Environment: LOCAL ne P/');
  $t += checkCmd( "$prefix/$plugin -F $prefix/xml/nagios-1.0.xml -H 'Host Name ...' -s service -e P -i 10", 3, '/ERROR: Content Error: - Service: Service Name ... ne service - Environment: LOCAL ne P/');
  $t += checkCmd( "$prefix/$plugin -F $prefix/xml/nagios-1.0.xml -H 'Host Name ...' -s 'Service Name ...' -e P -i 10", 3, '/ERROR: Content Error: - Environment: LOCAL ne P/');
  $t += checkCmd( "$prefix/$plugin -F $prefix/xml/nagios-1.0.xml -H 'Host Name ...' -s 'Service Name ...' -e L -i 10", 3, '/Result into XML file \'[//\w\-\.]+\' are out of date:/');
} else {
  $t += skipMissingCmd( "$prefix/$plugin", $tests );
}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);
