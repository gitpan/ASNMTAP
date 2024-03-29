#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# � Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-sftp.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.002.003;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_template-sftp.pl',
  _programDescription => 'SFTP Nagios Template',
  _programUsagePrefix => '-i|--id <id file>',
  _programHelpPrefix  => '-i, --id=<id file>',
  _programVersion     => '3.002.003',
  _programGetOptions  => ['id|i=s', 'host|H=s', 'username|u|loginname=s', 'port|p=s', 'environment|e=s', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

my $id          = $objectNagios->getOptionsArgv ('id');
$objectNagios->printUsage ('Missing command line argument id') unless ( defined $id);

my $host        = $objectNagios->getOptionsArgv ('host');
my $port        = $objectNagios->getOptionsArgv ('port');
my $username    = $objectNagios->getOptionsArgv ('username');
my $environment = $objectNagios->getOptionsArgv ('environment');

my $debug = $objectNagios->getOptionsValue ('debug');

my $timeout = $objectNagios->timeout ();

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnValue = 1;

use Net::SFTP::Foreign;
use Fcntl qw(S_ISDIR);

my $sftp = Net::SFTP::Foreign->new($host, port => $port, user => $username, more => [-i => $id]);

if ( $returnValue = errorTrapSFTP ('SFTP connection failed', \$sftp, $debug) ) {
  print "You are logged on\n" if ($debug);

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # ...

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

$objectNagios->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'OKIDO' }, $TYPE{APPEND} ) if ( $returnValue ); 
$objectNagios->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapSFTP {
  my ($error_message, $sftp, $debug) = @_;

  if ( $$sftp->error ) {
    print $error_message, ": ", $$sftp->error,"\n" if ($debug);
    $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => $error_message .': '. $$sftp->error, result => '' }, $TYPE{APPEND} );
    return 0;
  } else {
    return 1;
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Nagios

check_template-sftp.pl

SFTP Nagios Template

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut