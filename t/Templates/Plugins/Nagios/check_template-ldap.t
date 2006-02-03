#! /usr/bin/perl -w -I ..
#
# ... Tests via check_template-ldap.pl
#
# $Id: check_template-ldap.t, v 1.0 2006/02/01 Alex Peeters Exp $
#

use strict;
use Test;
use ASNMTAP::Asnmtap::Plugins::NPTest;

use vars qw($tests);
BEGIN {$tests = 21; plan tests => $tests}

my ($module, $version, $installed);
$module    = 'Net::LDAP';
$version   = '0.33';
$installed = eval ( "require $module; Exporter::require_version ( '$module', $version );" );

my $t;
my $prefix = '../plugins/nagios/templates';
my $plugin = 'check_template-ldap.pl';

if ( $installed and -x "$prefix/$plugin" ) {
  $t += checkCmd( "$prefix/$plugin -V", 3, "/$plugin/");
  $t += checkCmd( "$prefix/$plugin -h", 3);
  $t += checkCmd( "$prefix/$plugin", 3, '/Missing host/');
  $t += checkCmd( "$prefix/$plugin --host=ldap.citap.com", 3, '/Missing port/');
  $t += checkCmd( "$prefix/$plugin --host=ldap.citap.com --port=389", 3, '/Missing dn/');
  $t += checkCmd( "$prefix/$plugin --host=ldap.citap.com --port=389 --dn='uid=ldapconsult,ou=People,dc=be'", 3, '/Missing dnPass/');
  $t += checkCmd( "$prefix/$plugin --host=ldap.citap.com --port=389 --dn='uid=ldapconsult,ou=People,dc=be' --dnPass='consult'", 3, '/Missing base/');
  $t += checkCmd( "$prefix/$plugin --host=ldap.citap.com --port=389 --dn='uid=ldapconsult,ou=People,dc=be' --dnPass='consult' --base='dc=be'", 3, '/Missing scope/');
  $t += checkCmd( "$prefix/$plugin --host=ldap.citap.com --port=389 --dn='uid=ldapconsult,ou=People,dc=be' --dnPass='consult' --base='dc=be' --scope='SUB'", 3, '/Missing filter/');
  $t += checkCmd( "$prefix/$plugin --host=ldap.citap.com --port=389 --dn='uid=ldapconsult,ou=People,dc=be' --dnPass='consult' --base='dc=be' --scope='SUB' --filter='(uid=alexpeeters)'", 3, '/Missing password/');
  $t += checkCmd( "$prefix/$plugin --host=ldap.citap.com --port=389 --dn='uid=ldapconsult,ou=People,dc=be' --dnPass='consult' --base='dc=be' --scope='SUB' --filter='(uid=alexpeeters)' --password=password", 3, "/ERROR: Can't get an connection to ldapserver/" );
} else {
  $t += skipMissingCmd( "$prefix/$plugin", $tests );
}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);
