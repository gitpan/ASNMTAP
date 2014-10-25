#!/usr/local/bin/perl
# ----------------------------------------------------------------------------------------------------------
# � Copyright 2003-2007 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/02/25, v3.000.013, check_template-ras.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.000.013;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS $ROUTECOMMAND);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_template-ras.pl',
  _programDescription => "RAS plugin template for the '$APPLICATION'",
  _programVersion     => '3.000.013',
  _programUsagePrefix => '--phonenumber=<phonenumber> [--port=<port>] [--baud=<baud rate>]',
  _programHelpPrefix  => '--phonenumber<phonenumber>
--port=<port>
   windows: com1, com2, com3 or com4
   linux  : /dev/ttyS0, /dev/ttyS1, /dev/ttyS2 or /dev/ttyS3
--baud=<baud rate>
   300, 1200, 2400, 4800, 9600, 19200, 28800, 38400, 57600 or 115200',
  _programGetOptions  => ['Phonenumber=s', 'Port:s' ,'Baud:s', 'loglevel|l=s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $loglevel = $objectPlugins->getOptionsArgv ('loglevel');

my $phonenumber = $objectPlugins->getOptionsArgv ('Phonenumber');
$objectPlugins->printUsage ('Missing command line argument Phonenumber') unless (defined $phonenumber);

my $port = $objectPlugins->getOptionsArgv ('Port');
$objectPlugins->printUsage ('Missing command line argument Port') unless (defined $port);

my $baud = $objectPlugins->getOptionsArgv ('Baud');
$objectPlugins->printUsage ('Missing command line argument Baud') unless (defined $baud);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Modem v3.000.013;
use ASNMTAP::Asnmtap::Plugins::Modem qw(&get_modem_request);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnCode = get_modem_request (
  asnmtapInherited => \$objectPlugins,
  custom           => \&actionOnModemResponse,
  phonenumber      => $phonenumber,
  port             => $port,
  baudrate         => $baud,
  phonebook        => 'ASNMTAP',
  defaultGateway   => '192.168.123.254',
  interface        => 'eth0',
  logtype          => 'file',
  loglevel         => $loglevel
);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub actionOnModemResponse {
  my ($asnmtapInherited, $parms, $modem, $ok, $answer, $not_connected_guess, $arguments) = @_;

  my $debug = $asnmtapInherited->getOptionsValue ('debug');

  if ($debug and defined $arguments) {
    for ( ref $arguments ) {
      /^REF$/ &&
        do { 
          for ( ref $$arguments ) {
            /^ARRAY$/ &&
              do { print "REF ARRAY: @$$arguments\n"; last; };
            /^HASH$/ &&
              do { print "REF HASH: "; while (my ($key, $value) = each %{ $$arguments } ) { print "$key => $value "; }; print "\n"; last; };
          }

          last;
        };
      /^ARRAY$/ &&
        do { print "ARRAY: @$arguments\n"; last; };
      /^HASH$/ &&
        do { print "HASH: "; while (my ($key, $value) = each %{ $arguments } ) { print "$key => $value "; }; print "\n"; last; };
      /^SCALAR$/ &&
        do { print "REF SCALAR: ", $$arguments, "\n"; last; };
      print "SCALAR: ", $arguments, "\n";
    }
  }

  print 'ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request::actionOnModemResponse: ', $asnmtapInherited->programDescription (), "\n" if ( $debug );

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub errorTrapFTP {
    my ($asnmtapInherited, $error_message, $ftp_message, $debug) = @_;

    print "$error_message\n" if ($debug);
    chomp ($ftp_message);
    $asnmtapInherited->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => $error_message .': '. $ftp_message, result => '' }, $TYPE{APPEND} );
    return 0;
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#  use Net::FTP;

  my ($ftp, $rv, $hostname);
  $rv = 1;

  $hostname = 'ftp.citap.be';
#  $ftp = Net::FTP->new ($hostname, Debug => $debug) or $rv = errorTrapFTP ($asnmtapInherited, 'Cannot connect to '. $hostname, "$@", $debug);
#  $ftp->quit if $rv;

  return ( $rv ? $ERRORS{OK} : $ERRORS{UNKNOWN} );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-ras.pl

RAS plugin template for the 'Application Monitor'

The ASNMTAP plugins come with ABSOLUTELY NO WARRANTY.

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2007 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut

