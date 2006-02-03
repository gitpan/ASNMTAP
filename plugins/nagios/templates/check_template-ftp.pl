#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# � Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/29, v3.000.003, making Asnmtap v3.000.003 compatible
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.000.003;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_template-ftp.pl',
  _programDescription => 'FTP Nagios Template',
  _programVersion     => '3.000.003',
  _programGetOptions => ['host|H=s', 'username|u|loginname=s', 'password|passwd|p=s', 'environment|e:s'],
  _timeout           => 30,
  _debug             => 0);

my $host = $objectNagios->getOptionsArgv ('host') ? $objectNagios->getOptionsArgv ('host') : undef;
$objectNagios->printUsage ('Missing host') unless (defined $host);

my $username = $objectNagios->getOptionsArgv ('username') ? $objectNagios->getOptionsArgv ('username') : undef;
$objectNagios->printUsage ('Missing username') unless (defined $username);

my $password = $objectNagios->getOptionsArgv ('password') ? $objectNagios->getOptionsArgv ('password') : undef;
$objectNagios->printUsage ('Missing password') unless (defined $password);

my $environment = $objectNagios->getOptionsArgv ('environment') ? $objectNagios->getOptionsArgv ('environment') : undef;
$objectNagios->printUsage ('Missing environment') unless (defined $environment);

my $debug = $objectNagios->getOptionsValue ('debug');

my $timeout = $objectNagios->timeout ();

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnValue = 1;

use Net::FTP;
my $ftp = Net::FTP->new(Host => $host, Timeout => $timeout, Debug => $debug) or $returnValue = errorTrapFTP ("Cannot connect to $host", "$@", $debug);
$ftp->login($username, $password) or $returnValue = errorTrapFTP ('Cannot login', $ftp->message, $debug) if ($returnValue);

if ( $returnValue ) {
  print "You are logged on\n" if ($debug);

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # $ftp->cwd("/ape") or $returnValue = errorTrapFTP("Cannot change to directory", $ftp->message, $debug) if ($returnValue);
  # $ftp->ascii or $returnValue = errorTrapFTP("Transfer file in ascii mode", $ftp->message, $debug) if ($returnValue);
  # $ftp->binary or $returnValue = errorTrapFTP("Transfer file in binary mode", $ftp->message, $debug) if ($returnValue);
  # $ftp->get("that.file") or $returnValue = errorTrapFTP("Get failed", $ftp->message, $debug) if ($returnValue);
  # $ftp->ls or $returnValue = errorTrapFTP("List ", $ftp->message, $debug) if ($returnValue);

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

$ftp->quit or $returnValue = errorTrapFTP ('Quit', $ftp->quit, $debug) if ($returnValue);
$objectNagios->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'OKIDO' }, $TYPE{APPEND} ) if ( $returnValue ); 
$objectNagios->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapFTP {
  my ($error_message, $ftp_message, $debug) = @_;
  print "$error_message\n" if ($debug);
  chomp ($ftp_message);
  $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => $error_message .': '. $ftp_message, result => '' }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Nagios

check_template-ftp.pl

FTP Nagios Template

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut