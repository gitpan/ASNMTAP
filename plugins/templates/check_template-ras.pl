#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/01, v3.0, making ASNMTAP v3.xxx.xxx compatible
# ----------------------------------------------------------------------------------------------------------
# COPYRIGHT NOTICE
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be].                            All Rights Reserved.
#
# Asnmtap may be used and modified free of charge by anyone so long as this copyright notice and the comments
# above remain intact.  By using this code you agree to indemnify Alex Peeters from any liability that might
# arise from it's use.
#
# Selling the code for this program without prior written consent is expressly forbidden.    In other words,
# please ask first before you try and make money off of my program.
#
# Obtain permission before redistributing this software over the Internet or in any other medium.
# In all cases copyright and header must remain intact.
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

use lib qw(/opt/asnmtap-3.000.xxx/. /opt/asnmtap/.);
use ASNMTAP::Asnmtap::Plugins v3.000.004;
use ASNMTAP::Asnmtap::Plugins qw(:DEFAULT :ASNMTAP :PLUGINS :MODEM);

use Getopt::Long;
use vars qw($opt_p $opt_P $opt_B $opt_l  $opt_t $opt_S $opt_D $opt_L $opt_d $opt_O $opt_A $opt_V $opt_h $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME    = "check_template-ras.pl";
my $prgtext  = "RAS plugin template for testing the '$APPLICATION'";
my $version  = "3.0";
$TIMEOUT     = 30;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp ();
sub printUsage ();

Getopt::Long::Configure('bundling');

GetOptions (
  # modem - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "p=s" => \$opt_p, "phonenumber=s" => \$opt_p,
  "P:s" => \$opt_P, "port:s"        => \$opt_P,
  "B:s" => \$opt_B, "baud:s"        => \$opt_B,
  "l:s" => \$opt_l, "loglevel:s"    => \$opt_l,
  # default - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "t:f" => \$opt_t, "trendline:f"   => \$opt_t,
  "S:s" => \$opt_S, "status:s"      => \$opt_S,
  "D:s" => \$opt_D, "debug:s"       => \$opt_D,
  "L:s" => \$opt_L, "logging:s"     => \$opt_L,
  "d:s" => \$opt_d, "debugfile:s"    => \$opt_d,
  "O:s" => \$opt_O, "onDemand:s"    => \$opt_O,
  "A:s" => \$opt_A, "asnmtapEnv:s"  => \$opt_A,
  "V"   => \$opt_V, "version"       => \$opt_V,
  "h"   => \$opt_h, "help"          => \$opt_h
);

if ($opt_V) { printRevision($PROGNAME, $version); exit $ERRORS{"OK"}; }
if ($opt_h) { printHelp(); exit $ERRORS{"OK"}; }
my ($trendline, $status, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $returnCode, $startTime, $onDemand, $asnmtapEnv) = init_plugin ($opt_t, $opt_S, $opt_D, $opt_L, $opt_d, $opt_O, $opt_A);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$state   = $STATE{$ERRORS{"UNKNOWN"}};
$message = "Template Ras ...";
$alert   = "";
$error   = "";
$result  = "";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Net::FTP;
use Net::Ping;

# RAS settings
my $phonebook = "ASNMTAP";
my $username  = "testdimona";                                # if windows
my $password  = "testmvm";                                   # if windows

my ($endTime, $responseTime, $performanceData);
($endTime, $responseTime) = setEndTime_and_getResponsTime ($startTime);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($windows, $hrasconn, $modem, $ok, $answer, $not_connected_guess);
($windows, $hrasconn, $modem, $ok, $answer, $not_connected_guess, $alert, $state) = init_modem ($PROGNAME, $TIMEOUT, $phonebook, $username, $password, $opt_p, $opt_P, $opt_B, $opt_l, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $asnmtapEnv);

if ( $ok and !$not_connected_guess ) {
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print "--> $prgtext <--\n";

  # my $route = 1;
  #
  # ($route, undef, undef) = call_system ("/sbin/route add -net 193.178.202.0 netmask 255.255.255.0 dev ppp0", $debug) if $route;
  # call_system ("/sbin/route -n", $debug);

  # if ( $route) {
  #   my ($ftp, $rv);
  #   my $hostname = "ftp.socialsecurity.be";
  #   $ftp = Net::FTP->new($hostname, Debug => $debug) or $rv = errorTrapFTP ("Cannot connect to $hostname", "$@", $debug);
  #   $ftp->quit if $rv;

  #   ($route, undef, undef) = call_system ("/sbin/route del -net 193.178.202.0 netmask 255.255.255.0 dev ppp0", $debug);
  #   call_system ("/sbin/route del default", $debug);
  # } else {
  #   $state = $STATE{$ERRORS{"WARNING"}};
  #   $alert = "Cannot setup routing";
  #  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

($endTime, $responseTime) = setEndTime_and_getResponsTime ($startTime);
$performanceData .= " Total=" .$responseTime. "ms;" .($trendline*1000). ";;;";

exit_modem_plugin ($windows, $hrasconn, $asnmtapEnv, "192.168.123.254", "eth0", $phonebook, $modem, $ok, $not_connected_guess, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $performanceData );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapFTP {
  my ($error_message, $ftp_message, $debug) = @_;
  print "$error_message\n" if ($debug);
  chomp ($ftp_message);
  $alert .= " $error_message: $ftp_message";
  $state = $STATE{$ERRORS{"CRITICAL"}};
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printUsage () {
  print "Usage: $PROGNAME -p <phonemumber> [-P <port>] [-B <baudrate>] [-l <loglevel>] $PLUGINUSAGE\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp () {
  printRevision($PROGNAME, $version);
  print "This is the plugin '$prgtext'\n";
  printUsage();

  print "
-p, --phonenumber=<phonenumber>
-P, --port=com1|com2|/dev/ttyS0|/dev/ttyS1, default 'com1'
-B, --baud=<baudrate>, default '19200'
-l, --loglevel=debug|verbose|notice|info|warning|err|crit|alert|emerg, default 'emerg'
";

  support();
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

