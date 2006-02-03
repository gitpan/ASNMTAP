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
use ASNMTAP::Asnmtap::Plugins v3.000.002;
use ASNMTAP::Asnmtap::Plugins qw(:DEFAULT :ASNMTAP :PLUGINS :HTTP :MAIL :XML);

use Getopt::Long;
use vars qw($opt_e  $opt_t $opt_S $opt_D $opt_L $opt_d $opt_O $opt_A $opt_V $opt_h $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME    = "check_template-mail-xml.pl";
my $prgtext  = "Mail XML plugin template for testing the '$APPLICATION'";
my $version  = "3.0";
$TIMEOUT     = 10;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp ();
sub printUsage ();

Getopt::Long::Configure('bundling');

GetOptions (
  # mail xml  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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

my $environment = 'P';

if ($opt_e) {
  if ($opt_e eq 'P' || $opt_e eq 'A' || $opt_e eq 'S' || $opt_e eq 'T' || $opt_e eq 'D' || $opt_e eq 'L') {
    $environment = $opt_e;
  } else {
    usage("Invalid environment: $opt_e\n");
  }
}

# XML config  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use constant HEADER  => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER  => '</BaseServiceReport>';

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
$message           = "Receive XML Mail";
$alert             = "";
$error             = "";
$result            = "";

# Fingerprint emails  - - - - - - - - - - - - - - - - - - - - - - - - - -

my $mailSubject    = SUBJECT . ' / ' . $textFrom . ' ' . $mailFrom . ' ' . $textTo . ' ' . $mailTo;

my $mailHeader     = $mailSubject;
my $mailPluginname = '<' . $PROGNAME . '>';
my $mailBranding   = $mailPluginname . ' <' . $prgtext . '>';
my $mailTimestamp  = 'Timestamp <' . $mailFrom . '>:';
my $mailStatus     = $textStatus . ' <' . $textStatusDown . '>';

# Body of the emails  - - - - - - - - - - - - - - - - - - - - - - - - - -

my $mailBody       = "
<?xml version=\"1.0\" encoding=\"UTF-8\"?>

<BaseServiceReport>
  <Ressource>
    <Server>Production-Server</Server>
    <Name>Name Service to Report</Name>
    <Date>yyyy/mm/dd</Date>
    <Time>hh:mm:ss</Time>
    <Environment>PROD</Environment>
	<ErrorStack><![CDATA[ErrorStack .1.]]></ErrorStack>
    <ErrorDetail><![CDATA[ErrorDetail .1.]]></ErrorDetail>
  </Ressource>
</BaseServiceReport>
";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($endTime, $responseTime, $performanceData);
($endTime, $responseTime) = setEndTime_and_getResponsTime ($startTime);

# Receiving Fingerprint Mails - - - - - - - - - - - - - - - - - - - - - -

sleep 3 if ($debug); # sleep 3 secs - Can't call method 'login' on an undefined value at '$pop->login($username, $password);'
($returnCode, $alert, $state) = scan_socket_info ( 'tcp', $serverPOP3, 110, 'pop3', 'OK (POP3)', $boolean_unixSystem, $alert, $state, $debug, pop3 => { username => $username, password => $password, serviceReady => "[XMail [0-9.]+ POP3 Server] service ready", passwirdRequired => "Password required for", mailMessages => "Maildrop has [0-9.]+ messages", closingSession => "[XMail [0-9.]+ POP3 Server] closing session" } );

if ( $returnCode ) {
  my ($debugfileMessage, $dummy, $numberOfMails, $statusUp, $statusDown, @xml);

  if ($environment eq 'P') {
    $dummy = "Production";
  } elsif ($environment eq 'A') {
    $dummy = "Acceptation";
  } elsif ($environment eq 'S') {
    $dummy = "Simulation";
  } elsif ($environment eq 'T') {
    $dummy = "Test";
  } elsif ($environment eq 'D') {
    $dummy = "Development";
  } elsif ($environment eq 'L') {
    $dummy = "Local";
  }

  $debugfileMessage  = "\n<HTML><HEAD><TITLE>XML::Parser $prgtext \@ $APPLICATION</TITLE></HEAD><BODY><HR><H1 style=\"margin: 0px 0px 5px; font: 125% verdana,arial,helvetica\">$prgtext @ $APPLICATION</H1><HR>\n";
  $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal 68% bold verdana,arial,helvetica; text-align:left; background:#a6caf0;\"><TH>Server</TH><TH>Name</TH><TH>Environment</TH><TH>First Occurence Date</TH><TH>First Occurence Time</TH><TH>Errors</TH></TR>\n";
  $debugfileMessage .= "<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">$dummy</H3>";

  ($alert, $state, $result, $numberOfMails, $statusUp, $statusDown) = receiving_fingerprint_mails ( $alert, $state, $serverPOP3, $username, $password, $TIMEOUT, $emailsReceivedState, $textFrom, $textTo, $textSubject, $textStatus, $textStatusUp, $textStatusDown, $mailTo, $mailFrom, $mailSubject, $mailHeader, $mailPluginname, $mailBranding, $mailTimestamp, $mailStatus, 7, $debug, \&actionOnMailBody, $environment, \@xml, HEADER, FOOTER, 0, '', $onDemand );

  if ($numberOfMails != 0) {
    $alert .= " - $statusUp Email(s) service up" if $statusUp;
    $alert .= " - $statusDown Email(s) service down" if $statusDown;
    my $fixedAlert = "+";

    foreach my $xml (@xml) {
      $debugfileMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:purple;\"><TD>$xml->{Ressource}->{Server}</TD><TD>$xml->{Ressource}->{Name}</TD><TD>$xml->{Ressource}->{Environment}</TD><TD>$xml->{Ressource}->{Date}</TD><TD>$xml->{Ressource}->{Time}</TD><TD>$xml->{Ressource}->{Errors}</TD></TR>\n";
      $debugfileMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD valign=\"top\">Error Stack</TD><TD colspan=\"6\">$xml->{Ressource}->{ErrorStack}</TD></TR>\n";
      $debugfileMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD valign=\"top\">Error Detail</TD><TD colspan=\"6\">$xml->{Ressource}->{ErrorDetail}</TD></TR>\n" if ($debug >= 2);
      $fixedAlert      .= "$xml->{Ressource}->{Server}-$xml->{Ressource}->{Name}+";
    }

    $alert .= ", $fixedAlert" if ($fixedAlert ne "+");
  }

  $debugfileMessage .= "\n</TABLE>\n</BODY>\n</HTML>";
  write_debugfile($debug, $debugfile, 0, $debugfileMessage);
}

($endTime, $responseTime) = setEndTime_and_getResponsTime ($endTime);
$performanceData = "receiving=" .$responseTime. "ms;" .($trendline*1000). ";;;";

# Sending Fingerprint Mail  - - - - - - - - - - - - - - - - - - - - - - -

($returnCode, $alert, $state) = scan_socket_info ( 'tcp', $serverSMTP, '25', 'smtp', 'OK (221)', $boolean_unixSystem, $alert, $state, $debug );

if ( $returnCode ) {
  ($returnCode, $alert, $state) = sending_fingerprint_mail ( $alert, $state, $serverListSMTP, $mailTo, $mailFrom, $mailSubject, $mailHeader, $mailBranding, $mailTimestamp, $mailStatus, $mailBody, $debug );
}

($endTime, $responseTime) = setEndTime_and_getResponsTime ($endTime);
$performanceData .= " sending=" .$responseTime. "ms;" .($trendline*1000). ";;;";

($endTime, $responseTime) = setEndTime_and_getResponsTime ($startTime);
$performanceData .= " Total=" .$responseTime. "ms;" .($trendline*1000). ";;;";

exit_plugin ( $asnmtapEnv, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $performanceData );

# Function needed by receiving_fingerprint_mails!!! - - - - - - - - - - - -

sub actionOnMailBody {
  my ($tNumberOfMails, $tAlert, $tState, $tResultXML, $tPop, $tMsgnum, $tDate, $tTime, $tDay, $tMonth, $tYear, $tHour, $tMin, $tSec, $tDebug, $tEnvironment, $tXml, $tHeaderXML, $tFooterXML, $tValidateDTD, $tFilenameDTD, $tOnDemand) = @_;

  print "# mail(s) : $tNumberOfMails\nAlert     : $tAlert\nState     : $tState\nResult    : $tResultXML\nPop       : $tPop\nmsgnum    : $tMsgnum\nDebug     : $tDebug\nEnvironm. : $tEnvironment\nHeader    : $tHeaderXML\nFooter    : $tFooterXML\nValidate  : $tValidateDTD\nFilename  : $tFilenameDTD\n" if ( $tDebug >= 2 );

  my ($returnCode, $stateXML, $xml);
  ( $returnCode, $stateXML, $tAlert, $xml ) = extract_XML($tState, $tAlert, $tResultXML, undef, $tHeaderXML, $tFooterXML, $tValidateDTD, $tFilenameDTD, $tDebug);

  if ($returnCode == $ERRORS{'OK'}) {
    # put here your code regarding the MailBody - - - - - - - - - - - - -
    if ($tDebug) {
      print "<->\n", $xml->{Ressource}->{Server}, "\n";
      print "<->\n", $xml->{Ressource}->{Name}, "\n";
      print "<->\n", $xml->{Ressource}->{Date}, "\n";
      print "<->\n", $xml->{Ressource}->{Time}, "\n";
      print "<->\n", $xml->{Ressource}->{Environment}, "\n";
    }

    if ((($tEnvironment eq 'P') && $xml->{Ressource}->{Environment} =~ /^prod$/i) or (($tEnvironment eq 'S') && $xml->{Ressource}->{Environment} =~ /^sim$/i) or (($tEnvironment eq 'A') && $xml->{Ressource}->{Environment} =~ /^acc$/i) or (($tEnvironment eq 'T') && $xml->{Ressource}->{Environment} =~ /^test$/i) or (($tEnvironment eq 'D') && $xml->{Ressource}->{Environment} =~ /^dev$/i) or (($tEnvironment eq 'L') && $xml->{Ressource}->{Environment} =~ /^local$/i)) {
      my $push = 0;

      foreach my $tmpXML (@{$tXml}) {
        $push = ($tmpXML->{Ressource}->{Server} eq $xml->{Ressource}->{Server}) &&
                ($tmpXML->{Ressource}->{Name} eq $xml->{Ressource}->{Name}) &&
                ($tmpXML->{Ressource}->{Environment} eq $xml->{Ressource}->{Environment}) &&
                ($tmpXML->{Ressource}->{ErrorStack} eq $xml->{Ressource}->{ErrorStack});

        if ($push && $tDebug >= 2) { $push = ($tmpXML->{Ressource}->{ErrorDetail} eq $xml->{Ressource}->{ErrorDetail}); }

        if ($push) {
          $tmpXML->{Ressource}->{Errors}++;
          last;
        }
      }

      if (! $push) {
        $xml->{Ressource}->{Errors} = 1;
        push (@{$tXml}, $xml);
      }

      $xml->{Ressource}->{ErrorDetail} = "" if ($tDebug ne 2);
      $tPop->delete($tMsgnum) if (! ($tOnDemand or $tDebug));
      $tNumberOfMails++;
    }

    if ( $tDebug ) {
      foreach my $xml (@{$tXml}) {
        print "\n+++(out)+++\n$xml->{Ressource}->{Name}\n$xml->{Ressource}->{Date}\n$xml->{Ressource}->{Time}\n$xml->{Ressource}->{Errors}\n";
      }
    }
  } else {
    $tState = $stateXML;
    $tPop->delete($tMsgnum) if ($tOnDemand and $tDebug >= 4);
  }

  return ($tNumberOfMails, $tAlert, $tState, $tResultXML);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printUsage () {
  print "Usage: $PROGNAME [-e <environment>] $PLUGINUSAGE\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp () {
  printRevision($PROGNAME, $version);
  print "This is the plugin '$prgtext'\n";
  printUsage();

  print "
-e, --environment=P(roduction)|T(est)|A(cceptation)|S(imulation)|D(evelopment)|L(ocal)
";

  support();
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
