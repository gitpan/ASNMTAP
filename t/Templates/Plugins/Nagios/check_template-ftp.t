#! /usr/bin/perl -w -I ..
#
# ... Tests via check_template-ftp.pl
#
# $Id: check_template-ftp.t, v 1.0 2006/02/01 Alex Peeters Exp $
#

use strict;
use Test;
use ASNMTAP::Asnmtap::Plugins::NPTest;

use vars qw($tests);
BEGIN {$tests = 12; plan tests => $tests}

my ($module, $version, $installed);
$module    = 'Net::FTP';
$version   = '2.75';
$installed = eval ( "require $module; Exporter::require_version ( '$module', $version );" );

my $t;
my $prefix = '../plugins/nagios/templates';
my $plugin = 'check_template-ftp.pl';

if ( $installed and -x "$prefix/$plugin" ) {
  $t += checkCmd( "$prefix/$plugin -V", 3, "/$plugin/");
  $t += checkCmd( "$prefix/$plugin -h", 3);
  $t += checkCmd( "$prefix/$plugin", 3, "/Missing host/");
  $t += checkCmd( "$prefix/$plugin -H ftp.citap.com", 3, "/Missing username/");
  $t += checkCmd( "$prefix/$plugin -H ftp.citap.com -u username", 3, "/Missing password/");
  $t += checkCmd( "$prefix/$plugin -H ftp.citap.com -u username -p password", 3, "/Missing environment/");
  $t += checkCmd( "$prefix/$plugin -H ftp.citap.com -u username -p password -e L", 2);
} else {
  $t += skipMissingCmd( "$prefix/$plugin", $tests );
}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);