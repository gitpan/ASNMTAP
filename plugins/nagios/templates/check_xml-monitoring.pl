#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/29, v3.000.002, making Asnmtap v3.000.002 compatible
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Date::Calc qw(check_date check_time);
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.000.002;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $schema = "1.0";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_xml-monitoring.pl',
  _programDescription => 'Check Nagios by XML Monitoring',
  _programVersion     => '3.000.002',
  _programUsagePrefix => '-F|--filename <filename> -H|--hostname <hostname> -s|--service <service> -i|--interval <interval> [-p|--plugin <plugin>] [-p|--parameters <parameters>] [--validation <validation>]',
  _programHelpPrefix  => "-F, --filename=FILENAME
   FILENAME: XML 'filename' with the Nagios compatible test results
-H, --hostname=<Nagios Hostname>
-s, --service=<Nagios service name>
-i, --interval=<sec result out of date>
-P, --plugin=<plugin to execute>
-p, --parameters=<parameters for the plugin to execute>
--validation=F|T
   F(alse)       : dtd validation off (default)
   T(true)       : dtd validation on",
  _programGetOptions => ['filename|F=s', 'hostname|H=s', 'service|s=s', 'interval|i=s', 'plugin|P:s', 'parameters|p:s', 'validation:s', 'environment|e:s'],
  _timeout           => 30,
  _debug             => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $filename = $objectNagios->getOptionsArgv ('filename') ? $objectNagios->getOptionsArgv ('filename') : undef;
$objectNagios->printUsage ('Missing XML file') unless (defined $filename);

my $hostname = $objectNagios->getOptionsArgv ('hostname') ? $objectNagios->getOptionsArgv ('hostname') : undef;
$objectNagios->printUsage ('Missing hostname') unless (defined $hostname);

my $service = $objectNagios->getOptionsArgv ('service') ? $objectNagios->getOptionsArgv ('service') : undef;
$objectNagios->printUsage ('Missing service') unless ( defined $service);

my $resultOutOfDate = $objectNagios->getOptionsArgv ('interval') ? $objectNagios->getOptionsArgv ('interval') : undef;
$objectNagios->printUsage ('Missing interval') unless (defined $resultOutOfDate);

my $plugin      = $objectNagios->getOptionsArgv ('plugin')     ? $objectNagios->getOptionsArgv ('plugin')     : undef;
my $parameters  = $objectNagios->getOptionsArgv ('parameters') ? $objectNagios->getOptionsArgv ('parameters') : '';
my $validateDTD = $objectNagios->getOptionsArgv ('validation') ? $objectNagios->getOptionsArgv ('validation') : 'F';

if (defined $validateDTD) {
  $objectNagios->printUsage ('Invalid validation option: ' . $validateDTD) unless ($validateDTD =~ /^[FT]$/);
  $validateDTD = ($validateDTD eq 'T') ? 1 : 0;
}

my $environment = $objectNagios->getOptionsArgv ('environment');
$objectNagios->printUsage ('Missing environment') unless (defined $environment);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

use constant HEADER => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER => '</MonitoringXML>';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ( defined $plugin ) {
  if (-s $plugin ) {
    $objectNagios->exit (3) if ( $objectNagios->call_system ( $plugin .' '. $parameters, 1 ) );
  } else {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "The Plugin '$plugin' doesn't exist" }, $TYPE{APPEND} );
    $objectNagios->exit (3);
  }
}

my ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectNagios, filenameXML => $filename, headerXML => HEADER, footerXML => FOOTER, validateDTD => $validateDTD, filenameDTD => "dtd/Monitoring-$schema.dtd" );
$objectNagios->exit (3) if ( $returnCode );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $currentTimeslot = timelocal (0, (localtime)[1,2,3,4,5]);

if ($xml->{'Monitoring'}{'Schema'}{'Value'} eq $schema and $xml->{'Monitoring'}{'Results'}{'Details'}{'Host'} eq $hostname and $xml->{'Monitoring'}{'Results'}{'Details'}{'Service'} eq $service and $xml->{'Monitoring'}{'Results'}{'Details'}{'Environment'} =~ /^$environment/i) {
  my ($checkEpochtime, $checkDate, $checkTime) = ($xml->{'Monitoring'}{'Results'}{'Details'}{'Epochtime'}, $xml->{'Monitoring'}{'Results'}{'Details'}{'Date'}, $xml->{'Monitoring'}{'Results'}{'Details'}{'Time'});
  my ($checkYear, $checkMonth, $checkDay) = split (/\//, $checkDate);
  my ($checkHour, $checkMin, $checkSec) = split (/:/, $checkTime);
  my $xmlEpochtime = timelocal ( $checkSec, $checkMin, $checkHour, $checkDay, ($checkMonth-1), ($checkYear-1900) );
  print "$checkEpochtime, $xmlEpochtime ($checkDate, $checkTime), $currentTimeslot - $checkEpochtime = ". ($currentTimeslot - $checkEpochtime) ." > $resultOutOfDate\n"  if ( $objectNagios->getOptionsValue('debug') );

  if (! (check_date($checkYear, $checkMonth, $checkDay) or check_time($checkHour, $checkMin, $checkSec))) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Date or Time into XML file '$filename' are wrong: $checkDate $checkTime", result => undef }, $TYPE{APPEND} );
  } elsif ( $checkEpochtime != $xmlEpochtime ) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Epochtime difference from Date and Time into XML file '$filename' are wrong: $checkEpochtime != $xmlEpochtime ($checkDate $checkTime)", result => undef }, $TYPE{APPEND} );
  } elsif ( $currentTimeslot - $checkEpochtime > $resultOutOfDate ) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Result into XML file '$filename' are out of date: $checkDate $checkTime", result => undef }, $TYPE{APPEND} );
  } else {
    $objectNagios->pluginValues ( { stateError => $STATE{$xml->{'Monitoring'}{'Results'}{'Details'}{'Status'}}, alert => $xml->{'Monitoring'}{'Results'}{'Details'}{'StatusMessage'}, result => $xml->{'Monitoring'}{'Results'}{'Details'}{'content'} }, $TYPE{APPEND} );
    $objectNagios->appendPerformanceData( $xml->{'Monitoring'}{'Results'}{'Details'}{'PerfData'} ) if ( $xml->{'Monitoring'}{'Results'}{'Details'}{'PerfData'} );
  }
} else {
  my $tError = 'Content Error:';
  $tError .= ' - Schema: '. $xml->{'Monitoring'}{'Schema'}{'Value'} ." ne $schema" if ($xml->{'Monitoring'}{'Schema'}{'Value'} ne $schema);
  $tError .= ' - Host: '. $xml->{'Monitoring'}{'Results'}{'Details'}{'Host'}. " ne $hostname" if ($xml->{'Monitoring'}{'Results'}{'Details'}{'Host'} ne $hostname);
  $tError .= ' - Service: '. $xml->{'Monitoring'}{'Results'}{'Details'}{'Service'} ." ne $service" if ($xml->{'Monitoring'}{'Results'}{'Details'}{'Service'} ne $service);
  $tError .= ' - Environment: ' .$xml->{'Monitoring'}{'Results'}{'Details'}{'Environment'} . " ne $environment" if ($xml->{'Monitoring'}{'Results'}{'Details'}{'Environment'} !~ /^$environment$/i);
  $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $tError, result => undef }, $TYPE{APPEND} );
}

$objectNagios->exit (3);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Nagios

check_xml-monitoring.pl

Check Nagios by XML Monitoring

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

=head1 LICENSE

ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
