#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/06/01, v3.000.009, contact.pl for ASNMTAP::Asnmtap::Applications::CGI making Asnmtap v3.000.xxx compatible
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.009;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "contact.pl";
my $prgtext     = "$APPLICATION Contact Server Administrators";
my $version     = '3.000.009';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir  = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : "index"; $pagedir =~ s/\+/ /g;
my $pageset  = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : "index-cv"; $pageset =~ s/\+/ /g;
my $debug    = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : "F";
my $action   = (defined $cgi->param('action'))  ? $cgi->param('action')  : "sendView";
my $Csubject = (defined $cgi->param('subject')) ? $cgi->param('subject') : "";
my $Cmessage = (defined $cgi->param('message')) ? $cgi->param('message') : "";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($nextAction, $submitButton, $sendMessage);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTiltle) = user_session_and_access_control (0, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Contact", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&subject=$Csubject&message=$Cmessage";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>subject       : $Csubject<br>message       : $Cmessage<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  if ($action eq "sendView") {
    $htmlTitle    = "Send contact email";
    $submitButton = "Send";
    $nextAction   = "send";
  } elsif ($action eq "send") {
    my $tDebug = ($debug eq 'T') ? 2 : 0;
    my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, "$APPLICATION / $Csubject", $Cmessage, $tDebug );
    $sendMessage = ( $returnCode ? "Email succesfully send to the '$APPLICATION' server administrators" : "Problem sending email to the '$APPLICATION' server administrators" );
  }

  # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);

  if ($action eq "sendView") {
    print <<HTML;
    <form action="$ENV{SCRIPT_NAME}" method="post" name="contact">
      <input type="hidden" name="pagedir"   value="$pagedir">
      <input type="hidden" name="pageset"   value="$pageset">
      <input type="hidden" name="debug"     value="$debug">
      <input type="hidden" name="CGISESSID" value="$sessionID">
      <input type="hidden" name="action"    value="$nextAction">
HTML
  }

  print <<HTML;
  <br>
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td><table border="0" cellspacing="0" cellpadding="0">
HTML

  if ($action eq "sendView") {
  print <<HTML;
      <tr><td><b>Subject: </b>&nbsp;</td><td><input type="text" name="subject" value="$Csubject" size="108" maxlength="108"></td></tr>
      <tr><td valign="top"><b>Message: </b>&nbsp;</td><td><textarea name=message cols=84 rows=13>$Cmessage</textarea></td></tr>
      <tr align="left"><td align="right"><br><input type="submit" value="$submitButton"></td><td><br><input type="reset" value="Reset"></td></tr>
HTML
  } else {
    print "      <tr><td class=\"StatusItem\">$sendMessage</td></tr>\n";
  }

  print "    </table>\n      </td></tr></table>\n  <br>\n";
  print "      </form>" if ($action eq "sendView");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

