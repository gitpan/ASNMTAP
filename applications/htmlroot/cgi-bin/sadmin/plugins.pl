#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/05/01, v3.000.008, plugins.pl for ASNMTAP::Asnmtap::Applications::CGI making Asnmtap v3.000.xxx compatible
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

use ASNMTAP::Asnmtap::Applications::CGI v3.000.008;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :SADMIN :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "plugins.pl";
my $prgtext     = "Plugins";
my $version     = '3.000.008';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))            ? $cgi->param('pagedir')            : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))            ? $cgi->param('pageset')            : "sadmin";  $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))              ? $cgi->param('debug')              : "F";
my $pageNo              = (defined $cgi->param('pageNo'))             ? $cgi->param('pageNo')             : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))         ? $cgi->param('pageOffset')         : 0;
my $orderBy             = (defined $cgi->param('orderBy'))            ? $cgi->param('orderBy')            : "uKey";
my $action              = (defined $cgi->param('action'))             ? $cgi->param('action')             : "listView";
my $CuKey               = (defined $cgi->param('uKey'))               ? $cgi->param('uKey')               : "";
my $Ctest               = (defined $cgi->param('test'))               ? $cgi->param('test')               : "";
my $Carguments          = (defined $cgi->param('arguments'))          ? $cgi->param('arguments')          : "";
my $CargumentsOndemand  = (defined $cgi->param('argumentsOndemand'))  ? $cgi->param('argumentsOndemand')  : "";
my $Ctitle              = (defined $cgi->param('title'))              ? $cgi->param('title')              : "";
my $Ctrendline          = (defined $cgi->param('trendline'))          ? $cgi->param('trendline')          : 0;
my $Cstep               = (defined $cgi->param('step'))               ? $cgi->param('step')               : 0;
my $Condemand           = (defined $cgi->param('ondemand'))           ? $cgi->param('ondemand')           : "off";
my $Cproduction         = (defined $cgi->param('production'))         ? $cgi->param('production')         : "off";
my @Cpagedir            =          $cgi->param('pagedirs');
my $Cresultsdir         = (defined $cgi->param('resultsdir'))         ? $cgi->param('resultsdir')         : "none";
my $ChelpPluginFilename = (defined $cgi->param('helpPluginFilename')) ? $cgi->param('helpPluginFilename') : '<NIHIL>';
my $CholidayBundleID    = (defined $cgi->param('holidayBundleID'))    ? $cgi->param('holidayBundleID')    : 0;
my $Cactivated          = (defined $cgi->param('activated'))          ? $cgi->param('activated')          : "off";

my $Cpagedir = (@Cpagedir) ? '/'. join ('/', @Cpagedir) .'/' : '';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledUniqueKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Plugins", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&uKey=$CuKey&test=$Ctest&arguments=$Carguments&argumentsOndemand=$CargumentsOndemand&title=$Ctitle&trendline=$Ctrendline&step=$Cstep&ondemand=$Condemand&production=$Cproduction&pagedirs=$Cpagedir&resultsdir=$Cresultsdir&helpPluginFilename=$ChelpPluginFilename&holidayBundleID=$CholidayBundleID&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>uKey              : $CuKey<br>test              : $Ctest<br>arguments         : $Carguments<br>arguments ondemand: $CargumentsOndemand<br>title             : $Ctitle<br>trendline         : $Ctrendline<br>step              : $Cstep<br>on demand         : $Condemand<br>production        : $Cproduction<br>pagedirs          : $Cpagedir<br>resultsdir        : $Cresultsdir<br>helpPluginFilename: $ChelpPluginFilename<br>holiday Bundle ID : $CholidayBundleID<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($holidayBundleSelect, $pagedirsSelect, $resultsdirSelect, $matchingPlugins, $navigationBar, $matchingViewsCrontabs, $generatePluginCrontabSchedulingReport);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledUniqueKey = "";

    if ($action eq "duplicateView" or $action eq "insertView") {
      $htmlTitle    = "Insert Plugin";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
    } elsif ($action eq "insert") {
      $htmlTitle    = "Check if Plugin $CuKey exist before to insert";

      $sql = "select title from $SERVERTABLPLUGINS WHERE uKey='$CuKey'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle  = "Plugin $CuKey exist already";
        $nextAction = "insertView";
      } else {
        $htmlTitle  = "Plugin $CuKey inserted";
        my $dummyOndemand   = ($Condemand eq "on") ? 1 : 0;
        my $dummyProduction = ($Cproduction eq "on") ? 1 : 0;
        my $dummyActivated  = ($Cactivated eq "on") ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLPLUGINS. ' SET uKey="' .$CuKey. '", test="' .$Ctest. '", arguments="' .$Carguments. '", argumentsOndemand="' .$CargumentsOndemand. '", title="' .$Ctitle. '", trendline="' .$Ctrendline. '", step="' .$Cstep. '", ondemand="' .$dummyOndemand. '", production="' .$dummyProduction. '", pagedir="' .$Cpagedir. '", resultsdir="' .$Cresultsdir. '", helpPluginFilename="' .$ChelpPluginFilename. '", holidayBundleID="' .$CholidayBundleID. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq "deleteView") {
      $formDisabledUniqueKey = $formDisabledAll = "disabled";
      $htmlTitle    = "Delete plugin $CuKey";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq "delete") {
      $sql = "select uKey, title from $SERVERTABLCOMMENTS where uKey = '$CuKey' order by title, uKey";
      ($rv, $matchingPlugins) = check_record_exist ($rv, $dbh, $sql, 'Comments', 'Unique Key', 'Title', '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

      $sql = "select lineNumber, uKey from $SERVERTABLCRONTABS where uKey = '$CuKey' order by uKey, lineNumber";
      ($rv, $matchingPlugins) = check_record_exist ($rv, $dbh, $sql, 'Crontabs', 'Unique Key', 'Linenumber', $matchingPlugins, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

      $sql = "select uKey, displayDaemon from $SERVERTABLVIEWS where uKey = '$CuKey' order by displayDaemon, uKey";
      ($rv, $matchingPlugins) = check_record_exist ($rv, $dbh, $sql, 'Views', 'Unique Key', 'Display Daemon', $matchingPlugins, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

      $sql = "select uKey, reportTitle from $SERVERTABLREPORTS where uKey = '$CuKey' order by reportTitle, uKey";
      ($rv, $matchingPlugins) = check_record_exist ($rv, $dbh, $sql, 'Reports', 'Unique Key', 'Title', $matchingPlugins, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

	  if ($matchingPlugins eq "") {
        $htmlTitle = "Plugin $CuKey deleted";
        $sql = 'DELETE FROM ' .$SERVERTABLPLUGINS. ' WHERE uKey="' .$CuKey. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
      } else {
        $htmlTitle = "Plugin $CuKey not deleted, still used by";
      }

      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "displayView") {
      $formDisabledUniqueKey = $formDisabledAll = "disabled";
      $htmlTitle    = "Display plugin $CuKey";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "editView") {
      $formDisabledUniqueKey = "disabled";
      $htmlTitle    = "Edit plugin $CuKey";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq "edit") {
      $htmlTitle    = "Plugin $CuKey updated";
      my $dummyOndemand   = ($Condemand eq "on") ? 1 : 0;
      my $dummyProduction = ($Cproduction eq "on") ? 1 : 0;
      my $dummyActivated  = ($Cactivated eq "on") ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLPLUGINS. ' SET uKey="' .$CuKey. '", test="' .$Ctest. '", arguments="' .$Carguments. '", argumentsOndemand="' .$CargumentsOndemand. '", title="' .$Ctitle. '", trendline="' .$Ctrendline. '", step="' .$Cstep. '", ondemand="' .$dummyOndemand. '", production="' .$dummyProduction. '", pagedir="' .$Cpagedir. '", resultsdir="' .$Cresultsdir. '", helpPluginFilename="' .$ChelpPluginFilename. '", holidayBundleID="' .$CholidayBundleID. '", activated="' .$dummyActivated. '" WHERE uKey="' .$CuKey. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "listView") {
      $htmlTitle     = "All plugins listed";

      $sql = "select count(*) from $SERVERTABLPLUGINS";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;orderBy=$orderBy");

      $sql = "select uKey, title, ondemand, production, pagedir, resultsdir, activated from $SERVERTABLPLUGINS order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header  = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Unique Key <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=ondemand desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> On Demand <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=ondemand asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      $header .= "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=production desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Production <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=production asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=pagedir desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Views <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=pagedir asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=resultsdir desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Results <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=resultsdir asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, uKey desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>\n";
      ($rv, $matchingPlugins, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Plugin', 'uKey', '0', '', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTiltle, $sessionID, $debug);
    }

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView") {
      $sql = "select uKey, test, arguments, argumentsOndemand, title, trendline, step, ondemand, production, pagedir, resultsdir, helpPluginFilename, holidayBundleID, activated from $SERVERTABLPLUGINS where uKey = '$CuKey'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID) if $rv;

      if ( $rv ) {
        ($CuKey, $Ctest, $Carguments, $CargumentsOndemand, $Ctitle, $Ctrendline, $Cstep, $Condemand, $Cproduction, $Cpagedir, $Cresultsdir, $ChelpPluginFilename, $CholidayBundleID, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID) if ($sth->rows);
        $Condemand   = ($Condemand == 1) ? "on" : "off";
        $Cproduction = ($Cproduction == 1) ? "on" : "off";
        $Cactivated  = ($Cactivated == 1) ? "on" : "off";

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
      }
    }

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      $sql = "select pagedir, groupName from $SERVERTABLPAGEDIRS order by groupName";
      ($rv, $pagedirsSelect) = create_combobox_multiple_from_DBI ($rv, $dbh, $sql, $action, $Cpagedir, 'pagedirs', '-Select-', 5, 100, $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

      $sql = "select resultsdir, groupName from $SERVERTABLRSLTSDR order by groupName";
      ($rv, $resultsdirSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $Cresultsdir, 'resultsdir', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

      $sql = "select holidayBundleID, holidayBundleName from $SERVERTABLHLDSBNDL where activated = '1' order by holidayBundleName";
      ($rv, $holidayBundleSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CholidayBundleID, 'holidayBundleID', '0', '+ No Holliday Bundle', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);
    }

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "editView") {
      $matchingViewsCrontabs .= "<table border=0 cellpadding=1 cellspacing=1 bgcolor=\"$COLORSTABLE{TABLE}\">";
      my ($VdisplayDaemon, $Vactivated, $DDdisplayDaemon, $DDgroupName, $DDactivated, $DGgroupTitle, $DGactivated, $CTlinenumber, $CTcollectorDaemon, $CTarguments, $CTminute, $CThour, $CTdayOfTheMonth, $CTmonthOfTheYear, $CTdayOfTheWeek, $CTnoOffline, $CTactivated, $CDcollectorDaemon, $CDgroupName, $CDactivated, $SserverID, $SserverTitle, $StypeServers, $StypeMonitoring, $SmasterFQDN, $SslaveFQDN, $Sactivated);
      my ($prevSserverID, $prevDDdisplayDaemon, $prevCDcollectorDaemon, $urlWithAccessParametersAction, $actionItem, $notActivated);

      $matchingViewsCrontabs .= "<tr><th colspan=\"3\">Servers, Display Daemons, Views &amp; Display Groups:</th></tr>\n";
      $sql = "select $SERVERTABLVIEWS.displayDaemon, $SERVERTABLVIEWS.activated, $SERVERTABLDSPLYGRPS.groupTitle, $SERVERTABLDSPLYGRPS.activated, $SERVERTABLDSPLYDMNS.displayDaemon, $SERVERTABLDSPLYDMNS.groupName, $SERVERTABLDSPLYDMNS.activated, $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.serverTitle, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.activated from $SERVERTABLPLUGINS, $SERVERTABLVIEWS, $SERVERTABLDSPLYDMNS, $SERVERTABLDSPLYGRPS, $SERVERTABLSERVERS where $SERVERTABLPLUGINS.uKey = '$CuKey' and $SERVERTABLPLUGINS.uKey = $SERVERTABLVIEWS.uKey and $SERVERTABLVIEWS.displayDaemon = $SERVERTABLDSPLYDMNS.displayDaemon and $SERVERTABLVIEWS.displayGroupID = $SERVERTABLDSPLYGRPS.displayGroupID and $SERVERTABLDSPLYDMNS.serverID = $SERVERTABLSERVERS.serverID order by $SERVERTABLSERVERS.serverID, $SERVERTABLDSPLYDMNS.displayDaemon, $SERVERTABLVIEWS.displayDaemon, $SERVERTABLDSPLYGRPS.groupTitle";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID) if $rv;
      $sth->bind_columns( \$VdisplayDaemon, \$Vactivated, \$DGgroupTitle, \$DGactivated, \$DDdisplayDaemon, \$DDgroupName, \$DDactivated, \$SserverID, \$SserverTitle, \$StypeServers, \$StypeMonitoring, \$SmasterFQDN, \$SslaveFQDN, \$Sactivated ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID) if $rv;

      if ( $rv ) {
        $prevSserverID = $prevDDdisplayDaemon = "";

        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($prevSserverID eq "" or $prevSserverID ne $SserverID) {
              $urlWithAccessParametersAction = "servers.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;serverID=$SserverID&amp;orderBy=serverID asc&amp;action";
              $actionItem = "&nbsp;";
			  $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Server\" alt=\"Display Server\" border=\"0\"></a>&nbsp;" if ($iconDetails);
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Server\" alt=\"Edit Server\" border=\"0\"></a>&nbsp;" if ($iconEdit);
              $notActivated = ($Sactivated) ? "" : " not";
              $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td colspan=\"2\"><b>Server: $SserverTitle ($SserverID) -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
              my $typeMonitoringText = ($StypeMonitoring) ? "Distributed" : "Central";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type monitoring</td><td>$typeMonitoringText</td><td>&nbsp;</td></tr>\n";
              my $typeServersText = ($StypeServers) ? "Failover" : "Standalone";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type servers</td><td>$typeServersText</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">master FQDN</td><td>$SmasterFQDN</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">slave FQDN</td><td>$SslaveFQDN</td><td>&nbsp;</td></tr>\n";
            }

            if ($prevDDdisplayDaemon eq "" or $prevDDdisplayDaemon ne $DDdisplayDaemon) {
              $urlWithAccessParametersAction = "displayDaemons.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;displayDaemon=$DDdisplayDaemon&amp;orderBy=displayDaemon asc&amp;action";
              $actionItem = "&nbsp;";
			  $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Display Daemon\" alt=\"Display Display Daemon\" border=\"0\"></a>&nbsp;" if ($iconDetails);
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Display Daemon\" alt=\"Edit Display Daemon\" border=\"0\"></a>&nbsp;" if ($iconEdit);
              $notActivated = ($DDactivated) ? "" : " not";
              $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td colspan=\"2\"><b>Display daemon: DisplayCT-$DDdisplayDaemon -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Group name</td><td>$DDgroupName</td><td>&nbsp;</td></tr>\n";
            }

            $urlWithAccessParametersAction = "views.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;displayDaemon=$VdisplayDaemon&amp;uKey=$CuKey&amp;orderBy=groupName asc, groupTitle asc, title asc&amp;action";
            $actionItem = "&nbsp;";
         	$actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display View\" alt=\"Display View\" border=\"0\"></a>&nbsp;" if ($iconDetails);
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit View\" alt=\"Edit View\" border=\"0\"></a>&nbsp;" if ($iconEdit);
            $notActivated = ($Vactivated) ? "" : " not";
            $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td colspan=\"2\"><b>View: $HTTPSURL/nav/$VdisplayDaemon -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
            $notActivated = ($DGactivated) ? "" : " not";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Display group title</td><td>$DGgroupTitle -<b>$notActivated activated</b></td><td>&nbsp;</td></tr>\n";

            $prevSserverID       = $SserverID;
			$prevDDdisplayDaemon = $DDdisplayDaemon;
          }
        } else {
          $matchingViewsCrontabs .= "<tr><td>No records found</td></tr>\n";
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
      }

      $matchingViewsCrontabs .= "<tr bgcolor=\"#000000\"><td colspan=\"3\">&nbsp;</td></tr><tr><th colspan=\"3\">Servers, Collector Daemons &amp; Crontabs:</th></tr>\n";
      $sql = "select $SERVERTABLCRONTABS.linenumber, $SERVERTABLCRONTABS.collectorDaemon, $SERVERTABLCRONTABS.arguments, $SERVERTABLCRONTABS.minute, $SERVERTABLCRONTABS.hour, $SERVERTABLCRONTABS.dayOfTheMonth, $SERVERTABLCRONTABS.monthOfTheYear, $SERVERTABLCRONTABS.dayOfTheWeek, $SERVERTABLCRONTABS.noOffline, $SERVERTABLCRONTABS.activated, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLCLLCTRDMNS.groupName, $SERVERTABLCLLCTRDMNS.activated, $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.serverTitle, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.activated from $SERVERTABLPLUGINS, $SERVERTABLCRONTABS, $SERVERTABLCLLCTRDMNS, $SERVERTABLSERVERS where $SERVERTABLPLUGINS.uKey = '$CuKey' and $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon and $SERVERTABLCLLCTRDMNS.serverID = $SERVERTABLSERVERS.serverID order by $SERVERTABLSERVERS.serverID, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLCRONTABS.collectorDaemon, $SERVERTABLCRONTABS.linenumber";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID) if $rv;
      $sth->bind_columns( \$CTlinenumber, \$CTcollectorDaemon, \$CTarguments, \$CTminute, \$CThour, \$CTdayOfTheMonth, \$CTmonthOfTheYear, \$CTdayOfTheWeek, \$CTnoOffline, \$CTactivated, \$CDcollectorDaemon, \$CDgroupName, \$CDactivated, \$SserverID, \$SserverTitle, \$StypeServers, \$StypeMonitoring, \$SmasterFQDN, \$SslaveFQDN, \$Sactivated ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID) if $rv;

      if ( $rv ) {
        $prevSserverID = $prevCDcollectorDaemon = "";

        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($prevSserverID eq "" or $prevSserverID ne $SserverID) {
              $urlWithAccessParametersAction = "servers.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;serverID=$SserverID&amp;orderBy=serverID asc&amp;action";
              $actionItem = "&nbsp;";
			  $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Server\" alt=\"Display Server\" border=\"0\"></a>&nbsp;" if ($iconDetails);
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Server\" alt=\"Edit Server\" border=\"0\"></a>&nbsp;" if ($iconEdit);
              $notActivated = ($Sactivated) ? "" : " not";
              $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td colspan=\"2\"><b>Server: $SserverTitle ($SserverID) -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
              my $typeMonitoringText = ($StypeMonitoring) ? "Distributed" : "Central";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type monitoring</td><td>$typeMonitoringText</td><td>&nbsp;</td></tr>\n";
              my $typeServersText = ($StypeServers) ? "Failover" : "Standalone";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type servers</td><td>$typeServersText</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">master FQDN</td><td>$SmasterFQDN</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">slave FQDN</td><td>$SslaveFQDN</td><td>&nbsp;</td></tr>\n";
            }

            if ($prevCDcollectorDaemon eq "" or $prevCDcollectorDaemon ne $CDcollectorDaemon) {
              $urlWithAccessParametersAction = "collectorDaemons.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;collectorDaemon=$CDcollectorDaemon&amp;orderBy=collectorDaemon asc&amp;action";
              $actionItem = "&nbsp;";
			  $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Collector Daemon\" alt=\"Display Collector Daemon\" border=\"0\"></a>&nbsp;" if ($iconDetails);
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Collector Daemon\" alt=\"Edit Collector Daemon\" border=\"0\"></a>&nbsp;" if ($iconEdit);
              $notActivated = ($CDactivated) ? "" : " not";
              $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td colspan=\"2\"><b>Collector daemon: CollectorCT-$CDcollectorDaemon -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Group name</td><td>$CDgroupName</td><td>&nbsp;</td></tr>\n";
            }

            $urlWithAccessParametersAction = "crontabs.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;lineNumber=$CTlinenumber&amp;uKey=$CuKey&amp;orderBy=lineNumber asc, uKey asc, groupName asc, title asc&amp;action";
            $actionItem = "&nbsp;";
         	$actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Crontab\" alt=\"Display Crontab\" border=\"0\"></a>&nbsp;" if ($iconDetails);
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Crontab\" alt=\"Edit Crontab\" border=\"0\"></a>&nbsp;" if ($iconEdit);
            $notActivated = ($Cactivated) ? "" : " not";
            $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td colspan=\"2\"><b>Crontab: $CuKey-$CTlinenumber -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Arguments</td><td>$CTarguments</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Minute</td><td>$CTminute</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Hour</td><td>$CThour</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Day of the Month</td><td>$CTdayOfTheMonth</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Month of the Year</td><td>$CTmonthOfTheYear</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Day of the Week</td><td>$CTdayOfTheWeek</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">no Offline</td><td>$CTnoOffline</td><td>&nbsp;</td></tr>\n";

            $prevSserverID         = $SserverID;
            $prevCDcollectorDaemon = $CDcollectorDaemon;
          }

          $generatePluginCrontabSchedulingReport = 1;
        } else {
          $matchingViewsCrontabs .= "<tr><td>No records found</td></tr>\n";
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
      }

      $matchingViewsCrontabs .= "</table>\n";
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", 'F', "", $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
HTML

      if ($action eq "duplicateView" or $action eq "insertView") {
        print <<HTML;
  if ( document.plugins.uKey.value == null || document.plugins.uKey.value == '' ) {
    document.plugins.uKey.focus();
    alert('Please enter a unique key!');
    return false;
  } else {
    var objectRegularExpressionUkeyFormat = /\^[a-z|A-Z|0-9|-]\+\$/;

    if ( ! objectRegularExpressionUkeyFormat.test(document.plugins.uKey.value) ) {
      document.plugins.uKey.focus();
      alert('Please re-enter a unique key: Bad unique key value!');
      return false;
    }
  }
HTML
      }

      print <<HTML;

  if ( document.plugins.title.value == null || document.plugins.title.value == '' ) {
    document.plugins.title.focus();
    alert('Please enter a title!');
    return false;
  }
	
  if ( document.plugins.test.value == null || document.plugins.test.value == '' ) {
    document.plugins.test.focus();
    alert('Please enter a plugin name!');
    return false;
  }

  if ( document.plugins.trendline.value == null || document.plugins.trendline.value == '' ) {
    document.plugins.trendline.focus();
    alert('Please enter a trendline!');
    return false;
  }

  if ( document.plugins.step.value == null || document.plugins.step.value == '' ) {
    document.plugins.step.focus();
    alert('Please enter a step!');
    return false;
  }

  if ( document.plugins.pagedirs.selectedIndex == -1 ) {
    document.plugins.pagedirs.focus();
    alert('Please select one or more view pagedirs!');
    return false;
  }

  if ( document.plugins.resultsdir.options[document.plugins.resultsdir.selectedIndex].value == 'none' ) {
    document.plugins.resultsdir.focus();
    alert('Please select a results subdir!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="plugins" onSubmit="return validateForm();">
HTML
    } elsif ($action eq "deleteView") {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", 'F', "", $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"plugins\">\n";
      $pageNo = 1; $pageOffset = 0;
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", 'F', "", $sessionID);
    }

    if ($action eq "deleteView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      print <<HTML;
  <input type="hidden" name="pagedir"      value="$pagedir">
  <input type="hidden" name="pageset"      value="$pageset">
  <input type="hidden" name="debug"        value="$debug">
  <input type="hidden" name="CGISESSID"    value="$sessionID">
  <input type="hidden" name="pageNo"       value="$pageNo">
  <input type="hidden" name="pageOffset"   value="$pageOffset">
  <input type="hidden" name="action"       value="$nextAction">
  <input type="hidden" name="orderBy"      value="$orderBy">
HTML
    } else {
      print "<br>\n";
    }

    print "  <input type=\"hidden\" name=\"uKey\"   value=\"$CuKey\">\n" if ($formDisabledUniqueKey ne "" and $action ne "displayView");
	
    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert new plugin]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all plugins]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      my $ondemandChecked   = ($Condemand eq "on") ? " checked" : "";
      my $productionChecked = ($Cproduction eq "on") ? " checked" : "";
      my $activatedChecked  = ($Cactivated eq "on") ? " checked" : "";

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
      <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Unique Key: </b></td><td>
          <input type="text" name="uKey" value="$CuKey" size="11" maxlength="11" $formDisabledUniqueKey>
        <tr><td><b>Title: </b></td><td>
          <input type="text" name="title" value="$Ctitle" size="75" maxlength="75" $formDisabledAll>
        <tr><td><b>Plugin Filename: </b></td><td>
          <input type="text" name="test" value="$Ctest" size="100" maxlength="100" $formDisabledAll>
        <tr><td>Common Arguments: </td><td>
          <input type="text" name="arguments" value="$Carguments" size="100" maxlength="100" $formDisabledAll>
        <tr><td>On Demand Arguments: </td><td>
          <input type="text" name="argumentsOndemand" value="$CargumentsOndemand" size="100" maxlength="100" $formDisabledAll>
        <tr><td><b>Trendline: </b></td><td>
          <input type="text" name="trendline" value="$Ctrendline" size="6" maxlength="6" $formDisabledAll>
        <tr><td><b>Step: </b></td><td>
          <input type="text" name="step" value="$Cstep" size="6" maxlength="6" $formDisabledAll>
        <tr><td><b>Run On Demand: </b></td><td>
          <input type="checkbox" name="ondemand" $ondemandChecked $formDisabledAll>
        <tr><td><b>Into Production: </b></td><td>
          <input type="checkbox" name="production" $productionChecked $formDisabledAll>
        <tr><td valign="top"><b>View Pagedirs: </b></td><td>
    	  $pagedirsSelect
        <tr><td><b>Results Subdir: </b></td><td>
          $resultsdirSelect
        <tr><td>Help Plugin Filename: </td><td>
          <input type="text" name="helpPluginFilename" value="$ChelpPluginFilename" size="100" maxlength="100" $formDisabledAll>
        <tr><td>Holiday Bundle: </td><td>
    	  $holidayBundleSelect
        <tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq "duplicateView" or $action eq "editView" or $action eq "insertView");
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne "displayView");
      print "      </table>\n";
    } elsif ($action eq "delete" or $action eq "edit" or $action eq "insert") {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingPlugins</td></tr>" if (defined $matchingPlugins and $matchingPlugins ne "");
    } else {
      print "    <tr><td align=\"center\"><br>$matchingPlugins</td></tr>";
    }

    print "  </table>\n";

    if ($action eq "deleteView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      print "</form>\n";
    } else {
      print "<br>\n";
    }

    if (defined $matchingViewsCrontabs) {
      print "<table align=\"center\">\n<tr><td>\n$matchingViewsCrontabs</td></tr></table><br>\n";
      print "<table align=\"center\">\n<tr><td>\n<img src=\"/cgi-bin/moderator/generatePluginCrontabSchedulingReport.pl?uKey=$CuKey&amp;".encode_html_entities('U', "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID")."\"></td></tr></table><br>\n" if (defined $generatePluginCrontabSchedulingReport);
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
