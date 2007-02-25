#!/usr/local/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2007/02/25, v3.000.013, htmlToPdf.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------
# Compatible with HTMLDOC v1.8.27 from http://www.htmldoc.org/ or http://www.easysw.com/htmldoc
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.013;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MEMBER &call_system);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "htmlToPdf.pl";
my $prgtext     = "HTML to PDF";
my $version     = do { my @r = (q$Revision: 3.000.013$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($year, $month, $day) = (((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3]);
my $endDate;

# URL Access Parameters
my $cgi = new CGI;
my $HTMLtoPDFprg = (defined $cgi->param('HTMLtoPDFprg')) ? $cgi->param('HTMLtoPDFprg') : "$HTMLTOPDFPRG";
my $HTMLtoPDFhow = (defined $cgi->param('HTMLtoPDFhow')) ? $cgi->param('HTMLtoPDFhow') : "$HTMLTOPDFHOW";
my $scriptname   = (defined $cgi->param('scriptname'))   ? $cgi->param('scriptname')   : undef;
my $pagedir      = (defined $cgi->param('pagedir'))      ? $cgi->param('pagedir')      : ""; $pagedir =~ s/\+/ /g;
my $pageset      = (defined $cgi->param('pageset'))      ? $cgi->param('pageset')      : ""; $pageset =~ s/\+/ /g;
my $sessionID    = (defined $cgi->param('CGISESSID'))    ? $cgi->param('CGISESSID')    : undef;
my $debug        = (defined $cgi->param('debug'))        ? $cgi->param('debug')        : "F";
my $selDetailed  = (defined $cgi->param('detailed'))     ? $cgi->param('detailed')     : "on";
my $uKey1        = (defined $cgi->param('uKey1'))        ? $cgi->param('uKey1')        : "none";
my $uKey2        = (defined $cgi->param('uKey2'))        ? $cgi->param('uKey2')        : "none";
my $uKey3        = (defined $cgi->param('uKey3'))        ? $cgi->param('uKey3')        : "none";
my $startDate    = (defined $cgi->param('startDate'))    ? $cgi->param('startDate')    : "$year-$month-$day";
my $inputType    = (defined $cgi->param('inputType'))    ? $cgi->param('inputType')    : "fromto";
my $selYear      = (defined $cgi->param('year'))         ? $cgi->param('year')         : 0;
my $selWeek      = (defined $cgi->param('week'))         ? $cgi->param('week')         : 0;
my $selMonth     = (defined $cgi->param('month'))        ? $cgi->param('month')        : 0;
my $selQuarter   = (defined $cgi->param('quarter'))      ? $cgi->param('quarter')      : 0;
my $timeperiodID = (defined $cgi->param('timeperiodID')) ? $cgi->param('timeperiodID') : 1;
my $statuspie    = (defined $cgi->param('statuspie'))    ? $cgi->param('statuspie')    : "off";
my $errorpie     = (defined $cgi->param('errorpie'))     ? $cgi->param('errorpie')     : "off";
my $bar          = (defined $cgi->param('bar'))          ? $cgi->param('bar')          : "off";
my $hourlyAvg    = (defined $cgi->param('hourlyAvg'))    ? $cgi->param('hourlyAvg')    : "off";
my $dailyAvg     = (defined $cgi->param('dailyAvg'))     ? $cgi->param('dailyAvg')     : "off";
my $details      = (defined $cgi->param('details'))      ? $cgi->param('details')      : "off";
my $topx         = (defined $cgi->param('topx'))         ? $cgi->param('topx')         : "off";
my $pf           = (defined $cgi->param('pf'))           ? $cgi->param('pf')           : "off";

if ( $cgi->param('endDate') ) { $endDate = $cgi->param('endDate'); } else { $endDate = ""; }

my $htmlTitle = "Convert HTML to PDF";
my $subTiltle = "HTML to PDF";

# Write the content type to the client...
print "Content-Type: Text/HTML\n\n";

if ((!defined $scriptname) or (!defined $sessionID)) {
  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);
  print "<h1 align=\"center\">Scriptname and/or CGISESSID missing</h1>\n";
} else {
  # Serialize the URL Access Parameters into a string
  my $urlAccessParameters = "pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;detailed=$selDetailed&amp;uKey1=$uKey1&amp;uKey2=$uKey2&amp;uKey3=$uKey3&amp;startDate=$startDate&amp;endDate=$endDate&amp;inputType=$inputType&amp;year=$selYear&amp;week=$selWeek&amp;month=$selMonth&amp;quarter=$selQuarter&amp;timeperiodID=$timeperiodID&amp;statuspie=$statuspie&amp;errorpie=$errorpie&amp;bar=$bar&amp;hourlyAvg=$hourlyAvg&amp;dailyAvg=$dailyAvg&amp;details=$details&amp;topx=$topx&amp;pf=$pf&amp;htmlToPdf=1";

  my $refresh = "";

  if ($HTMLtoPDFprg eq "htmldoc") {
    my $extension = ($HTMLtoPDFhow eq 'cgi') ? 'cgi' : 'sh';
    $refresh = "1; url=/cgi-bin/$HTMLtoPDFprg.$extension$scriptname?$urlAccessParameters";
  }

  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, $refresh, '', 'F', '', $sessionID);

  if ($HTMLtoPDFhow eq 'cgi' or $HTMLtoPDFhow eq "shell") {
    print "<h1 align=\"center\">Wait, i make a PDF for you ... ($HTMLtoPDFhow)</h1>\n";
  } else {
    print "<h1 align=\"center\">It's not a bug, it's a missing feature!</h1>\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
