#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# � Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/09/16, v3.000.011, getHelpPlugin.pl for ASNMTAP::Asnmtap::Applications::CGI
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;
use Shell;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.011;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "getHelpPlugin.pl";
my $prgtext     = "Get help for one '$APPLICATION' plugin";
my $version     = '3.000.011';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $uKey    = (defined $cgi->param('uKey'))    ? $cgi->param('uKey')    : "";      $uKey    =~ s/\+/ /g;
my $pagedir = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : "index"; $pagedir =~ s/\+/ /g;
my $pageset = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : "index-cv"; $pageset =~ s/\+/ /g;
my $debug   = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : "F";

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my %ENVIRONMENT = ('P'=>'Production', 'A'=>'Acceptation', 'S'=>'Simulation', 'T'=>'Test', 'D'=>'Development', 'L'=>'Local');
my $htmlTitle = $APPLICATION .' - '. $ENVIRONMENT{$environment};

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Help for Plugin", "uKey=$uKey");

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&uKey=$uKey";

# Debug information
print "<pre>pagedir   : $pagedir<br>pageset   : $pageset<br>debug     : $debug<br>CGISESSID : $sessionID<br>uKey      : $uKey<br>URL ...   : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  my ($htmlHelpPluginTitle, $htmlHelpPluginFilename, $fileHelpPluginFilename);
  $htmlHelpPluginTitle = $htmlHelpPluginFilename = $fileHelpPluginFilename = '<NIHIL>';

  my $sql = "select title, helpPluginFilename from $SERVERTABLPLUGINS where uKey = '$uKey'";

  my $rv  = 1;
  my $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTiltle, 3600, '', $sessionID);	

  if ($dbh and $rv) {
    my $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTiltle, 3600, '', $sessionID);
    $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTiltle, 3600, '', $sessionID) if $rv;

    if ( $rv ) {
      while (my ($title, $helpPluginFilename) = $sth->fetchrow_array()) {
        $htmlHelpPluginTitle = $title;
        $htmlHelpPluginFilename = $helpPluginFilename;
      }

      $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTiltle, 3600, '', $sessionID);

      if ($htmlHelpPluginFilename ne '<NIHIL>') {
        $fileHelpPluginFilename = $PDPHELPPATH .'/'. $htmlHelpPluginFilename;
        $htmlHelpPluginFilename = $PDPHELPURL .'/'. $htmlHelpPluginFilename;
		
        if (open(PDF, "$fileHelpPluginFilename")) {
          close(PDF);
        } else {
          $fileHelpPluginFilename = '<NIHIL>';
          $htmlHelpPluginFilename = "Wanted helpfile: '$htmlHelpPluginFilename'";
        }		

      } else {
        $htmlHelpPluginFilename = "There is no helpfile defined into the plugin database!";
      }

      print_header (*STDOUT, $pagedir, $pageset, $htmlHelpPluginTitle, $subTiltle, 3600, '', 'F', '', $sessionID);

      print '<br>', "\n", '<table WIDTH="100%" border=0><tr><td class="HelpPluginFilename">', "\n";

      if ($fileHelpPluginFilename eq '<NIHIL>') {
        print '<IMG SRC="', $IMAGESURL, '/404.jpg"><br><br>', $htmlHelpPluginFilename, "\n";
      } else {
        print '<iframe src="', $htmlHelpPluginFilename, '" width="100%" height="1214" more="" ATTRIBUTES=""></iframe>', "\n";
      }

      print '</td></tr></table>', "\n";
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTiltle, 3600, '', $sessionID);
  }

  print '<BR>', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
