#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/03/18, v3.000.006, index.pl for ASNMTAP::Asnmtap::Applications::CGI making Asnmtap v3.000.xxx compatible
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.006;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :ADMIN);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "index.pl";
my $prgtext     = "$APPLICATION Admin";
my $version     = '3.000.006';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : "admin";   $pageset =~ s/\+/ /g;
my $debug   = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : "F";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Admin Menu", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", 'F', "", $sessionID);

  print <<HTML;
  <br>
  <table width="100%" border="0" cellspacing="0" cellpadding="0"><tr align="center"><td>
	<table border="0" cellspacing="0" cellpadding="0">
	  <tr><td class="StatusItem"><font size="+1">Moderator</font></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="../moderator/sessions.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Session Console (for the Display)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="../moderator/runStatusOnDemand.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Status Console (for the Collector/Display)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="../moderator/pluginCrontabSchedulingReports.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Plugin Crontab Scheduling Reports (for the Collector)</a></td></tr>
	  <tr><td class="StatusItem"><a href="../moderator/collectorCrontabSchedulingReports.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Collector Crontab Scheduling Reports (for the Collector)</a></td></tr>
	  <tr><td class="StatusItem"><a href="../moderator/collectorDaemonSchedulingReports.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Collector Daemon Scheduling Reports (for the Collector)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><font size="+1">Administrator</font></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="languages.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Languages</a></td></tr>
	  <tr><td class="StatusItem"><a href="countries.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Countries</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="holidays.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Holidays</a></td></tr>
	  <tr><td class="StatusItem"><a href="holidaysBundle.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Holidays Bundle</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="users.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Users</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="reports.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Reports (to define the 'Detailed Statistics &amp; Report Generation' that are generated by the Archiver)</a></td></tr>
	</table>
  </td></tr></table>
  <br>
HTML
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

