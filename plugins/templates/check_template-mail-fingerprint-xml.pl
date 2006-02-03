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

use lib qw(/opt/asnmtap/.);
use ASNMTAP::Asnmtap::Plugins v3.000.003;
use ASNMTAP::Asnmtap::Plugins qw(:DEFAULT :ASNMTAP :PLUGINS :MAILXML);

use Getopt::Long;
use vars qw($opt_i $opt_e  $opt_t $opt_S $opt_D $opt_L $opt_d $opt_O $opt_A $opt_V $opt_h $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME    = "check_template-mail-fingerprint-xml.pl";
my $prgtext  = "XML fingerprint Mail plugin template for testing the '$APPLICATION'";
my $version  = "3.0";
$TIMEOUT     = 10;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp ();
sub printUsage ();

Getopt::Long::Configure('bundling');

GetOptions (
  # xml parameters  - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "i=i" => \$opt_i, "interval=i"    => \$opt_i,
  "e:s" => \$opt_e, "environment:s" => \$opt_e,
  # default - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "t:f" => \$opt_t, "trendline:f"  => \$opt_t,
  "S:s" => \$opt_S, "status:s"     => \$opt_S,
  "D:s" => \$opt_D, "debug:s"      => \$opt_D,
  "L:s" => \$opt_L, "logging:s"    => \$opt_L,
  "d:s" => \$opt_d, "debugfile:s"   => \$opt_d,
  "O:s" => \$opt_O, "onDemand:s"   => \$opt_O,
  "A:s" => \$opt_A, "asnmtapEnv:s" => \$opt_A,
  "V"   => \$opt_V, "version"      => \$opt_V,
  "h"   => \$opt_h, "help"         => \$opt_h
);

if ($opt_V) { printRevision($PROGNAME, $version); exit $ERRORS{"OK"}; }
if ($opt_h) { printHelp(); exit $ERRORS{"OK"}; }
my ($trendline, $status, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $returnCode, $startTime, $onDemand, $asnmtapEnv) = init_plugin ($opt_t, $opt_S, $opt_D, $opt_L, $opt_d, $opt_O, $opt_A);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $resultOutOfDate = ($opt_i) ? $opt_i : 300;

my $environment = 'P';

if ($opt_e) {
  if ($opt_e eq 'P' || $opt_e eq 'A' || $opt_e eq 'S' || $opt_e eq 'T' || $opt_e eq 'D' || $opt_e eq 'L') {
    $environment = $opt_e;
  } else {
    usage("Invalid environment: $opt_e\n");
  }
}

# smtp & pop3 config  - - - - - - - - - - - - - - - - - - - - - - - - - -

use constant SUBJECT => 'ASNMTAP';

# cygwin: $boolean_unixSystem & linux: $boolean_unixSystem = 1
my $boolean_unixSystem  = 1;

# when $emailsReceivedState = 1: No emails received => $state = $STATE{$ERRORS{"OK"}} or $STATE{$ERRORS{"WARNING"}};
# when $emailsReceivedState = 0: x mail(s) received => $state = $STATE{$ERRORS{"OK"}} or $STATE{$ERRORS{"WARNING"}};
my $emailsReceivedState = 0;

my $serverListSMTP = [qw(chablis.dvkhosting.com)];
my $serverSMTP     = 'chablis.dvkhosting.com';

my $mailFrom       = 'alex.peeters@citap.com';
my $mailTo         = 'asnmtap@citap.com';
my $serverPOP3     = 'chablis.dvkhosting.com';
my $username       = 'asnmtap';
my $password       = 'asnmtap';

my $textFrom       = 'From:';
my $textTo         = 'To:';
my $textSubject    = 'Subject:';
my $textStatus     = 'Status';

my $textStatusUp   = $APPLICATION . ' Status UP';
my $textStatusDown = $APPLICATION . ' Status Down';

# ansmtap  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$state             = $STATE{$ERRORS{"UNKNOWN"}};
$message           = "Receive Mail";
$alert             = "";
$error             = "";
$result            = "";

# Fingerprint emails  - - - - - - - - - - - - - - - - - - - - - - - - - -

my $mailSubject     = SUBJECT . ' / ' . $textFrom . ' ' . $mailFrom . ' ' . $textTo . ' ' . $mailTo;

my $mailPlugin      = $PROGNAME;
my $mailDescription = $prgtext;
my $mailEnvironment = 'PROD';

if ($environment eq 'A') {
  $mailEnvironment = "ACC";
} elsif ($environment eq 'S') {
  $mailEnvironment = "SIM";
} elsif ($environment eq 'T') {
  $mailEnvironment = "TEST";
} elsif ($environment eq 'D') {
  $mailEnvironment = "DEV";
} elsif ($environment eq 'L') {
  $mailEnvironment = "LOCAL";
}

my $mailStatus      = $textStatusUp;

# Body of the emails  - - - - - - - - - - - - - - - - - - - - - - - - - -

my $mailBody       = "

This is the body of the email !!!

";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($endTime, $responseTime, $performanceData);
($endTime, $responseTime) = setEndTime_and_getResponsTime ($startTime);

# Receiving Fingerprint Mails - - - - - - - - - - - - - - - - - - - - - -

sleep 3 if ($debug); # sleep 3 secs - Can't call method 'login' on an undefined value at '$pop->login($username, $password);'
($returnCode, $alert, $state) = scan_socket_info ( 'tcp', $serverPOP3, 110, 'pop3', 'OK (POP3)', $boolean_unixSystem, $alert, $state, $debug, pop3 => { username => $username, password => $password, serviceReady => "[XMail [0-9.]+ POP3 Server] service ready", passwirdRequired => "Password required for", mailMessages => "Maildrop has [0-9.]+ messages", closingSession => "[XMail [0-9.]+ POP3 Server] closing session" } );

if ( $returnCode ) {
   my ($numberOfMails, $statusUp, $statusDown);
  ($alert, $state, $result, $numberOfMails, $statusUp, $statusDown) = receiving_fingerprint_mails_XML ( $alert, $state, $serverPOP3, $username, $password, $TIMEOUT, $emailsReceivedState, $textFrom, $textTo, $textSubject, $textStatusUp, $textStatusDown, $mailTo, $mailFrom, $mailSubject, $mailPlugin, $mailDescription, $mailEnvironment, $mailStatus, 1, $resultOutOfDate, $debug, \&actionOnMailBody, $onDemand );

  if ($numberOfMails != 0) {
    $alert .= " - $statusUp Email(s) service up" if $statusUp;
    $alert .= " - $statusDown Email(s) service down" if $statusDown;
  }
}

($endTime, $responseTime) = setEndTime_and_getResponsTime ($endTime);
$performanceData = "receiving=" .$responseTime. "ms;" .($trendline*1000). ";;;";

# Sending Fingerprint Mail  - - - - - - - - - - - - - - - - - - - - - - -

($returnCode, $alert, $state) = scan_socket_info ( 'tcp', $serverSMTP, '25', 'smtp', 'OK (221)', $boolean_unixSystem, $alert, $state, $debug );

if ( $returnCode ) {
  ($returnCode, $alert, $state) = sending_fingerprint_mail_XML ( $alert, $state, $serverListSMTP, $mailTo, $mailFrom, $mailSubject, $mailPlugin, $mailDescription, $mailEnvironment, $mailStatus, $mailBody, $debug );
}

($endTime, $responseTime) = setEndTime_and_getResponsTime ($endTime);
$performanceData .= " sending=" .$responseTime. "ms;" .($trendline*1000). ";;;";

($endTime, $responseTime) = setEndTime_and_getResponsTime ($startTime);
$performanceData .= " Total=" .$responseTime. "ms;" .($trendline*1000). ";;;";

exit_plugin ( $asnmtapEnv, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $performanceData );

# Function needed by receiving_fingerprint_mails_XML !!! - - - - - - - - - -

sub actionOnMailBody {
  my ($tNumberOfMails, $tAlert, $tState, $tResult, $tPop, $tMsgnum, $tDate, $tTime, $tDay, $tMonth, $tYear, $tHour, $tMin, $tSec, $tResultOutOfDate, $tDebug, $tOnDemand) = @_;
  print "# mail(s) : $tNumberOfMails\nAlert     : $tAlert\nState     : $tState\nResult    : $tResult\nPop       : $tPop\nmsgnum    : $tMsgnum\nDebug     : $tDebug\n" if $tDebug;

  # put here your code regarding the MailBody - - - - - - - - - - - - - -
  #
  # $tAlert  = "";
  # $tState  = $STATE{$ERRORS{"OK"}};
  $tResult = "<NIHIL>";
  #
  # put here your code for deleting the email from the Mailbox  - - - - -
  #
  $tPop->delete($tMsgnum) if (! ($tOnDemand or $tDebug));
  #
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $tNumberOfMails++;
  return ($tNumberOfMails, $tAlert, $tState, $tResult);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printUsage () {
  print "Usage: $PROGNAME [-i <interval>] [-e <environment>] $PLUGINUSAGE\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp () {
  printRevision($PROGNAME, $version);
  print "This is the plugin '$prgtext'\n";
  printUsage();

  print "
-i, --interval=<sec result out of date>
-e, --environment=P(roduction)|T(est)|A(cceptation)|S(imulation)|D(evelopment)|L(ocal)
";

  support();
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

