#!/bin/env perl -w -I ..
#
# ... Tests via check_template-mail-without-fingerprint.pl
#
# $Id: check_template-mail-without-fingerprint.t, v 1.0 2006/02/01 Alex Peeters Exp $
#

use strict;
use Test;
use ASNMTAP::Asnmtap::Plugins::NPTest;

use vars qw($tests);
BEGIN {$tests = 5; plan tests => $tests}

my $t;
my $prefix = '../plugins/templates';
my $plugin = 'check_template-mail-without-fingerprint.pl';

if ( -x "$prefix/$plugin" ) {
  $t += checkCmd( "$prefix/$plugin -V", 3, "/$plugin/");
  $t += checkCmd( "$prefix/$plugin -h", 3);
  $t += checkCmd( "$prefix/$plugin", 3, "/Missing parent object command line option -e\|--environment/");
} else {
  $t += skipMissingCmd( "$prefix/$plugin", $tests );
}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);
