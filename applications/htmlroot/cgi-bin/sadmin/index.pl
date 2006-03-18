#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/03/18, v3.000.006, index.pl for ASNMTAP::Asnmtap::Applications::CGI making Asnmtap v3.000.xxx compatible
# ---------------------------------------------------------------------------------------------------------
# COPYRIGHT NOTICE
# © Copyright 2005 Alex Peeters [alex.peeters@citap.be].                                All Rights Reserved.
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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.006;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :SADMIN);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "index.pl";
my $prgtext     = "$APPLICATION sAdmin";
my $version     = '3.000.006';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : "sadmin";  $pageset =~ s/\+/ /g;
my $debug   = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : "F";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle      = $APPLICATION;

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "sAdmin Menu", undef);

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
	  <tr><td class="StatusItem"><a href="../admin/languages.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Languages</a></td></tr>
	  <tr><td class="StatusItem"><a href="../admin/countries.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Countries</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="../admin/holidays.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Holidays</a></td></tr>
	  <tr><td class="StatusItem"><a href="../admin/holidaysBundle.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Holidays Bundle</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="../admin/users.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Users</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="../admin/reports.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Reports (to define the 'Detailed Statistics &amp; Report Generation' that are generated by the Archiver)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><font size="+1">Server Administrator</font></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="servers.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Servers (to define the different application monitoring servers)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="pagedirs.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Pagedirs (where the Display writes the different views)</a></td></tr>
	  <tr><td class="StatusItem"><a href="resultsdirs.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Resultdirs (where the Collector writes the returned data from a plugin)</a></td></tr>
	  <tr><td class="StatusItem"><a href="displayGroups.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Display Groups (to define the group titles that are used by the Display)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="displayDaemons.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Display Daemons (to define the different daemons used for the Display)</a></td></tr>
	  <tr><td class="StatusItem"><a href="collectorDaemons.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Collector Daemons (to define the different daemons used for the Collector)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="plugins.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Plugins (to define the plugins that are executed by the Collector)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="views.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Views (to define the different views used by the Display daemons)</a></td></tr>
	  <tr><td class="StatusItem"><a href="crontabs.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Crontabs (to define the different crontabs used by the Collector daemons)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="generateConfig.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Configurations (for the Archiver, Display, Collector and Rsync Mirroring)</a></td></tr>
<!--
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="databaseConsole.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Database Console (for the Display and Collector)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="daemonConsole.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Daemon Console (for the Display and Collector)</a></td></tr>
-->
	</table>
  </td></tr></table>
  <br>
HTML
}

# 	  <tr><td class="StatusItem"><a href="databaseConsole.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Database Console (for the Display and Collector)</a></td></tr>
# 	  <tr><td class="StatusItem"><a href="daemonConsole.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Daemon Console (for the Display and Collector)</a></td></tr>
# 	  <tr><td class="StatusItem"><a href="sessionConsole.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Session Console (for the Display and Collector)</a></td></tr>

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

