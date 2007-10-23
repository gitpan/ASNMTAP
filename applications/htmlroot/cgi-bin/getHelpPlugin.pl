#!/usr/local/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/10/21, v3.000.015, getHelpPlugin.pl for ASNMTAP::Asnmtap::Applications::CGI
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;
use Shell;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.015;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "getHelpPlugin.pl";
my $prgtext     = "Get help for one '$APPLICATION' plugin";
my $version     = do { my @r = (q$Revision: 3.000.015$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $uKey    = (defined $cgi->param('uKey'))    ? $cgi->param('uKey')    : '';      $uKey    =~ s/\+/ /g;
my $pagedir = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : 'index'; $pagedir =~ s/\+/ /g;
my $pageset = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug   = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : 'F';

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle = $APPLICATION .' - '. $ENVIRONMENT{$environment};

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Help for Plugin", "uKey=$uKey");

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&uKey=$uKey";

# Debug information
print "<pre>pagedir   : $pagedir<br>pageset   : $pageset<br>debug     : $debug<br>CGISESSID : $sessionID<br>uKey      : $uKey<br>URL ...   : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  my ($htmlHelpPluginTitle, $htmlHelpPluginFilename, $fileHelpPluginFilename);
  $htmlHelpPluginTitle = $htmlHelpPluginFilename = $fileHelpPluginFilename = '<NIHIL>';

  my $sql = "select concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ), helpPluginFilename from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where uKey = '$uKey' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment";

  my $rv  = 1;
  my $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTitle, 3600, '', $sessionID);	

  if ($dbh and $rv) {
    my $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTitle, 3600, '', $sessionID);
    $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTitle, 3600, '', $sessionID) if $rv;

    if ( $rv ) {
      while (my ($title, $helpPluginFilename) = $sth->fetchrow_array()) {
        $htmlHelpPluginTitle = $title;
        $htmlHelpPluginFilename = $helpPluginFilename;
      }

      $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTitle, 3600, '', $sessionID);

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

      print_header (*STDOUT, $pagedir, $pageset, $htmlHelpPluginTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print '<br>', "\n", '<table WIDTH="100%" border=0><tr><td class="HelpPluginFilename">', "\n";

      if ($fileHelpPluginFilename eq '<NIHIL>') {
        print '<IMG SRC="', $IMAGESURL, '/404.jpg"><br><br>', $htmlHelpPluginFilename, "\n";
      } else {
        print '<iframe src="', $htmlHelpPluginFilename, '" width="100%" height="1214" more="" ATTRIBUTES=""></iframe>', "\n";
      }

      print '</td></tr></table>', "\n";
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlHelpPluginTitle, $subTitle, 3600, '', $sessionID);
  }

  print '<BR>', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
