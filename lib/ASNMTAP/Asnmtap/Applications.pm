# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/02/28, v3.000.004, package ASNMTAP::Asnmtap::Applications Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap::Applications;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);
use Time::Local;

# include the class files - - - - - - - - - - - - - - - - - - - - - - - -

use lib qw(/opt/asnmtap/.);
use ASNMTAP::Asnmtap v3.000.004;
use ASNMTAP::Asnmtap qw(:DEFAULT :ASNMTAP :APPLICATIONS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Exporter;

our @ISA         = qw(Exporter ASNMTAP::Asnmtap);

our @EXPORT      = qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO);

our @EXPORT_OK   = qw($CAPTUREOUTPUT $PREFIXPATH $PLUGINPATH $PERLCOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND %ERRORS %STATE &scan_socket_info
                      $APPLICATIONPATH

                      $ASNMTAPMANUAL
                      $DATABASE
                      $CONFIGDIR $DEBUGDIR $REPORTDIR $RESULTSDIR
                      $CGISESSPATH $HTTPSPATH $IMAGESPATH $PDPHELPPATH $RESULTSPATH $LOGPATH $PIDPATH $SSHKEYPATH $WWWKEYPATH
                      $HTTPSSERVER $REMOTE_HOST $REMOTE_ADDR $HTTPSURL $IMAGESURL $PDPHELPURL $RESULTSURL
                      $SMTPUNIXSYSTEM $SERVERLISTSMTP $SERVERSMTP $SENDMAILFROM
                      $SSHLOGONNAME $RSYNCIDENTITY $SSHIDENTITY $WWWIDENTITY
                      $RMVERSION $RMDEFAULTUSER
                      $HTMLTOPDFPRG $HTMLTOPDFHOW $HTMLTOPDFOPTNS
                      $RECORDSONPAGE $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $FIRSTSTARTDATE $STRICTDATE $STATUSHEADER01
					  %COLORS %COLORSPIE %COLORSRRD %COLORSTABLE %ICONS %ICONSACK %ICONSRECORD %ICONSSYSTEM %SOUND %QUARTERS
                      $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                      $SERVERNAMEREADONLY $SERVERPORTREADONLY $SERVERUSERREADONLY $SERVERPASSREADONLY
                      $SERVERTABLCLLCTRDMNS $SERVERTABLCOMMENTS $SERVERTABLCOUNTRIES $SERVERTABLCRONTABS $SERVERTABLDSPLYDMNS $SERVERTABLDSPLYGRPS $SERVERTABLEVENTS $SERVERTABLHOLIDYS $SERVERTABLHLDSBNDL $SERVERTABLLANGUAGE $SERVERTABLPAGEDIRS $SERVERTABLPLUGINS $SERVERTABLREPORTS $SERVERTABLRSLTSDR $SERVERTABLSERVERS $SERVERTABLUSERS $SERVERTABLVIEWS
                      &read_table &get_session_param &get_trendline_from_test
                      &set_doIt_and_doOffline
                      &create_header &create_footer &encode_html_entities &decode_html_entities &print_header &print_legend
                      &init_email_report &send_email_report &sending_mail
					  &error_Trap_DBI);

our %EXPORT_TAGS = (ASNMTAP     => [qw($CAPTUREOUTPUT $PREFIXPATH $PLUGINPATH $PERLCOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND %ERRORS %STATE &scan_socket_info &sending_mail)],

                    ARCHIVE     => [qw($DATABASE
                                       $DEBUGDIR $REPORTDIR
                                       $CGISESSPATH $RESULTSPATH
                                       $SMTPUNIXSYSTEM $SERVERLISTSMTP $SERVERSMTP $SENDMAILFROM
                                       &read_table &get_session_param
                                       &init_email_report &send_email_report)],

                    DBARCHIVE   => [qw($DATABASE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE $SERVERTABLEVENTS $SERVERTABLCOMMENTS)],

                    COLLECTOR   => [qw($APPLICATIONPATH

                                       $DEBUGDIR
                                       $HTTPSPATH $RESULTSPATH $PIDPATH
                                       $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                       %COLORSRRD
                                       &read_table &get_trendline_from_test
                                       &set_doIt_and_doOffline
                                       &create_header &create_footer)],

                    DBCOLLECTOR => [qw($DATABASE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                       $SERVERTABLCOMMENTS $SERVERTABLEVENTS)],

                    DISPLAY     => [qw($APPLICATIONPATH

                                       $HTTPSPATH $RESULTSPATH $PIDPATH
                                       $HTTPSURL $IMAGESURL $RESULTSURL
                                       $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                       $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $STATUSHEADER01
                                       %COLORS %ICONS %ICONSACK %ICONSRECORD %SOUND
                                       &read_table &get_trendline_from_test
                                       &create_header &create_footer &encode_html_entities &decode_html_entities &print_header &print_legend)],

                    DBDISPLAY   => [qw($DATABASE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE 
                                       $SERVERTABLCOMMENTS $SERVERTABLEVENTS)],
									   
                    CGI         => [qw($APPLICATIONPATH

                                       $ASNMTAPMANUAL
                                       $DATABASE
                                       $CONFIGDIR $DEBUGDIR $REPORTDIR $RESULTSDIR
                                       $CGISESSPATH $HTTPSPATH $IMAGESPATH $PDPHELPPATH $RESULTSPATH $LOGPATH $PIDPATH $SSHKEYPATH $WWWKEYPATH
                                       $HTTPSSERVER $REMOTE_HOST $REMOTE_ADDR $HTTPSURL $IMAGESURL $PDPHELPURL $RESULTSURL
                                       $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                       $SSHLOGONNAME $RSYNCIDENTITY $SSHIDENTITY $WWWIDENTITY
                                       $RMVERSION $RMDEFAULTUSER
                                       $HTMLTOPDFPRG $HTMLTOPDFHOW $HTMLTOPDFOPTNS
                                       $RECORDSONPAGE $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $FIRSTSTARTDATE $STRICTDATE
                                       %COLORS %COLORSPIE %COLORSRRD %COLORSTABLE %ICONS %ICONSACK %ICONSRECORD %ICONSSYSTEM %SOUND %QUARTERS
                                       &get_session_param
                                       &set_doIt_and_doOffline
                                       &encode_html_entities &print_header &print_legend

                                       $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                       $SERVERNAMEREADONLY $SERVERPORTREADONLY $SERVERUSERREADONLY $SERVERPASSREADONLY
                                       $SERVERTABLCLLCTRDMNS $SERVERTABLCOMMENTS $SERVERTABLCOUNTRIES $SERVERTABLCRONTABS $SERVERTABLDSPLYDMNS $SERVERTABLDSPLYGRPS $SERVERTABLEVENTS $SERVERTABLHOLIDYS $SERVERTABLHLDSBNDL $SERVERTABLLANGUAGE $SERVERTABLPAGEDIRS $SERVERTABLPLUGINS $SERVERTABLREPORTS $SERVERTABLRSLTSDR $SERVERTABLSERVERS $SERVERTABLUSERS $SERVERTABLVIEWS)]);

our $VERSION     = 3.000.004;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub read_table;
sub get_session_param;
sub get_trendline_from_test;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub _in_cyclus;
sub set_doIt_and_doOffline;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub create_header;
sub create_footer;

sub encode_html_entities;
sub decode_html_entities;

sub print_header;
sub print_legend;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub init_email_report;
sub send_email_report;
sub sending_mail;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub error_Trap_DBI;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs without TAGS  = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Common variables  = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

my $ASNMTAPMANUAL  = "asnmtap.pdf";

my $DATABASE       = "asnmtap";

my $CONFIGDIR      = "config";
my $DEBUGDIR       = "debug";
my $REPORTDIR      = "reports";
my $RESULTSDIR     = "results";

my $CGISESSPATH    = "/tmp";                   # for the cgisess_ files
my $HTTPSPATH      = "$APPLICATIONPATH/htmlroot";
my $IMAGESPATH     = "$HTTPSPATH/img";
my $PDPHELPPATH    = "$HTTPSPATH/pdf";
my $RESULTSPATH    = "$PREFIXPATH/$RESULTSDIR";
my $LOGPATH        = '/var/log/asnmtap';
my $PIDPATH        = '/var/run/asnmtap';
my $SSHKEYPATH     = '/home';
my $WWWKEYPATH     = '/var/www';

my $HTTPSSERVER    = "asnmtap.citap.be";
my $REMOTE_HOST    = "localhost";              # user_session_and_access_control true for this host
my $REMOTE_ADDR    = "127.0.0.1";              # user_session_and_access_control true for this ip
my $HTTPSURL       = "/asnmtap";
my $IMAGESURL      = "$HTTPSURL/img";
my $PDPHELPURL     = "$HTTPSURL/pdf";
my $RESULTSURL     = "/$RESULTSDIR";

my $SMTPUNIXSYSTEM = 1;                               # cygwin: 0 & linux: 1
my $SERVERLISTSMTP = [qw(chablis.dvkhosting.com)];
my $SERVERSMTP     = 'chablis.dvkhosting.com';
my $SENDMAILFROM   = "asnmtap\@citap.com";

my $SSHLOGONNAME   = "asnmtap";
my $RSYNCIDENTITY  = 'rsync';
my $SSHIDENTITY    = 'asnmtap';
my $WWWIDENTITY    = 'ssh';

my $RMVERSION      = '3.000.004';
my $RMDEFAULTUSER  = "admin";

my $HTMLTOPDFPRG   = 'htmldoc';        # '<nihil>' or 'htmldoc'
my $HTMLTOPDFHOW   = 'shell';          # '<nihil>', 'cgi' or 'shell'
my $HTMLTOPDFOPTNS = "--bodyimage $IMAGESPATH/logos/citap.gif --format pdf14 --size A4 --landscape --browserwidth 1280 --top 10mm --bottom 10mm --left 10mm --right 10mm --fontsize 10.0 --fontspacing 1.2 --headingfont Helvetica --bodyfont Helvetica --headfootsize 10.0 --headfootfont Helvetica --embedfonts --pagemode fullscreen --permissions no-copy,print --no-links --color --quiet --webpage --header ... --footer ...";

my $RECORDSONPAGE  = 10;
my $NUMBEROFFTESTS = 9;
my $VERIFYNUMBEROK = 3;
my $VERIFYMINUTEOK = 30;
my $FIRSTSTARTDATE = '2004-10-31';
my $STRICTDATE     = 0; # 1 = 'strict date checking' or 0 = 'no strict date checking'
my $STATUSHEADER01 = "De resultaten worden weergegeven binnen timeslots van vastgestelde duur per groep. De testen binnen éénzelfde groep worden sequentieel uitgevoerd.";

my %COLORS         = ('OK'=>'#99CC99','WARNING'=>'#FFFF00','CRITICAL'=>'#FF4444','UNKNOWN'=>'#FFFFFF','DEPENDENT'=>'#D8D8BF','OFFLINE'=>'#0000FF','NO DATA'=>'#CC00CC','IN PROGRESS'=>'#99CC99','NO TEST'=>'#99CC99', '<NIHIL>'=>'#CC00CC','TRENDLINE'=>'#ffa000');
my %COLORSPIE      = ('OK'=>0x00BA00, 'WARNING'=>0xffff00, 'CRITICAL'=>0xff0000, 'UNKNOWN'=>0x99FFFF, 'DEPENDENT'=>0xD8D8BF, 'OFFLINE'=>0x0000FF, 'NO DATA'=>0xCC00CC, 'IN PROGRESS'=>0x99CC99, 'NO TEST'=>0x444444,  '<NIHIL>'=>0xCC00CC, 'TRENDLINE'=>0xffa000);
my %COLORSRRD      = ('OK'=>0x00BA00, 'WARNING'=>0xffff00, 'CRITICAL'=>0xff0000, 'UNKNOWN'=>0x99FFFF, 'DEPENDENT'=>0xD8D8BF, 'OFFLINE'=>0x0000FF, 'NO DATA'=>0xCC00CC, 'IN PROGRESS'=>0x99CC99, 'NO TEST'=>0x000000,  '<NIHIL>'=>0xCC00CC, 'TRENDLINE'=>0xffa000);
my %COLORSTABLE    = ('TABLE'=>'#333344', 'NOBLOCK'=>'#335566','ENDBLOCK'=>'#665555','STARTBLOCK'=>'#996666');

my %ICONS          = ('OK'=>'green.gif','WARNING'=>'yellow.gif','CRITICAL'=>'red.gif','UNKNOWN'=>'clear.gif','DEPENDENT'=>'','OFFLINE'=>'blue.gif','NO DATA'=>'purple.gif','IN PROGRESS'=>'running.gif','NO TEST'=>'notest.gif','TRENDLINE'=>'orange.gif');
my %ICONSACK       = ('OK'=>'green-ack.gif','WARNING'=>'yellow-ack.gif','CRITICAL'=>'red-ack.gif','UNKNOWN'=>'clear-ack.gif','DEPENDENT'=>'','OFFLINE'=>'blue-ack.gif','NO DATA'=>'purple-ack.gif','IN PROGRESS'=>'running.gif','NO TEST'=>'notest-ack.gif','TRENDLINE'=>'orange-ack.gif');
my %ICONSRECORD    = ('maintenance'=>'maintenance.gif', 'duplicate'=>'recordDuplicate.gif', 'delete'=>'recordDelete.gif', 'details'=>'recordDetails.gif', 'query'=>'recordQuery.gif', 'edit'=>'recordEdit.gif', 'table'=>'recordTable.gif', 'up'=>'1arrowUp.gif', 'down'=>'1arrowDown.gif', 'left'=>'1arrowLeft.gif', 'right'=>'1arrowRight.gif', 'first'=>'2arrowLeft.gif', 'last'=>'2arrowRight.gif');
my %ICONSSYSTEM    = ('pidKill'=>'pidKill.gif', 'pidRemove'=>'pidRemove.gif', 'daemonReload'=>'daemonReload.gif', 'daemonStart'=>'daemonStart.gif', 'daemonStop'=>'daemonStop.gif', 'daemonRestart'=>'daemonRestart.gif');

my %SOUND          = ('0'=>'attention.wav','1'=>'warning.wav','2'=>'critical.wav','3'=>'unknown.wav','4'=>'attention.wav','5'=>'attention.wav','6'=>'attention.wav','7'=>'nodata.wav','8'=>'attention.wav','9'=>'warning.wav');

my %QUARTERS       = ('1'=>'1','2'=>'4','3'=>'7','4'=>'10');

# archiver, collector.pl and display.pl - - - - - - - - - - - - - - - - -
# comments.pl, holidayBundleSetDowntimes.pl - - - - - - - - - - - - - - -
# scripts into directory /cgi-bin/admin & /cgi-bin/sadmin - - - - - - - -
my $SERVERNAMEREADWRITE  = "chablis.dvkhosting.com";
my $SERVERPORTREADWRITE  = "3306";
my $SERVERUSERREADWRITE  = "asnmtap";
my $SERVERPASSREADWRITE  = "asnmtap";

# comments.pl, generateChart.pl, getHelpPlugin.pl, runCommandOnDemand.pl
# and detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl -
my $SERVERNAMEREADONLY   = "chablis.dvkhosting.com";
my $SERVERPORTREADONLY   = "3306";
my $SERVERUSERREADONLY   = "asnmtapro";
my $SERVERPASSREADONLY   = "asnmtapro";

# tables
my $SERVERTABLCLLCTRDMNS = "collectorDaemons";
my $SERVERTABLCOMMENTS   = "comments";
my $SERVERTABLCOUNTRIES  = "countries";
my $SERVERTABLCRONTABS   = "crontabs";
my $SERVERTABLDSPLYDMNS  = "displayDaemons";
my $SERVERTABLDSPLYGRPS  = "displayGroups";
my $SERVERTABLEVENTS     = "events";
my $SERVERTABLHOLIDYS    = "holidays";
my $SERVERTABLHLDSBNDL   = "holidaysBundle";
my $SERVERTABLLANGUAGE   = "language";
my $SERVERTABLPAGEDIRS   = "pagedirs";
my $SERVERTABLPLUGINS    = "plugins";
my $SERVERTABLREPORTS    = "reports";
my $SERVERTABLRSLTSDR    = "resultsdir";
my $SERVERTABLSERVERS    = "servers";
my $SERVERTABLUSERS      = "users";
my $SERVERTABLVIEWS      = "views";

# read config file  - - - - - - - - - - - - - - - - - - - - - - - - - - -
if (-s "$PREFIXPATH/applications/custom/Applications.conf") { require "$PREFIXPATH/applications/custom/Applications.conf"; }

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub read_table {
  my ($prgtext, $filename, $email, $tDebug) = @_;

  my @table = ();
  my $rvOpen = open(CT, "$APPLICATIONPATH/etc/$filename");

  if ($rvOpen) {
    while (<CT>) {
      chomp;

      if (!/^#/) {
        my $dummy = $_;
        $dummy =~ s/\ {1,}//g;
        if ($dummy ne '') { push (@table, $_); }
      }
    }
	
    close(CT);

	if ($email) {
      my $debug = $tDebug;
      $debug = 0 if ($tDebug eq 'F');
      $debug = 1 if ($tDebug eq 'T');
      $debug = 2 if ($tDebug eq 'L');
      $debug = 3 if ($tDebug eq 'M');
      $debug = 4 if ($tDebug eq 'A');
      $debug = 5 if ($tDebug eq 'S');

      my ($returnCode, undef, undef) = scan_socket_info ( 'tcp', $SERVERSMTP, '25', 'smtp', 'OK (221)', $SMTPUNIXSYSTEM, "", "", $debug);

      if ( $returnCode ) {
        my $subject = "$prgtext / Config $APPLICATIONPATH/etc/$filename succesfuly reloaded/restarted: " . get_datetimeSignal();
	    my $message = get_datetimeSignal() . " Config $APPLICATIONPATH/etc/$filename succesfuly reloaded/restarted\n";
        ($returnCode) = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $message, $debug );
      }
    }
  } else {
    print "Cannot open $APPLICATIONPATH/etc/$filename!\n";
    exit $ERRORS{UNKNOWN};
  }

  return @table;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_session_param {
  my ($sessionID, $cgipath, $filename, $debug) =  @_;

  my ($Tdebug, $cgisession);

  if ($debug eq 'F') {
    $Tdebug = 0;
  } elsif ($debug eq 'T') {
    $Tdebug = 1;
  } elsif ($debug eq 'L') {
    $Tdebug = 2;
  } elsif ($debug eq 'M') {
    $Tdebug = 3;
  } elsif ($debug eq 'A') {
    $Tdebug = 4;
  } elsif ($debug eq 'S') {
    $Tdebug = 5;
  } else {
    $Tdebug = $debug;
  }

  my $cgipathFilename = ($cgipath eq "") ? "$filename" : "$cgipath/$filename";

  if ( -e "$cgipathFilename" ) {
    my $rvOpen = open(CGISESSION, "$cgipathFilename");

    if ($rvOpen) {
      while (<CGISESSION>) {
        chomp;
        $cgisession .= $_;
      }

      close(CGISESSION);
    } else {
      print "\nCannot open cgisess '$cgipath$filename'!\n" if ($Tdebug);
      return (0, ());
    }
  } else {
    print "\ncgisess '$cgipath$filename' don't exists!\n" if ($Tdebug);
    return (0, ());
  }

  print "$cgisession\n\n" if ($Tdebug == 2);

  (undef, $cgisession) = map { split (/^\$D = {/) } split (/};$/, $cgisession);
  $cgisession =~ s/"//g;

  my %session = map { my ($key, $value) = split (/ => /) } split (/,/, $cgisession);

  if ($Tdebug == 2) {
    print "Session param\n";
    print "_SESSION_ID          : ", $session{'_SESSION_ID'}, "\n" if (defined $session{'_SESSION_ID'});
    print "_SESSION_REMOTE_ADDR : ", $session{'_SESSION_REMOTE_ADDR'}, "\n" if (defined $session{'_SESSION_REMOTE_ADDR'});
    print "_SESSION_CTIME       : ", $session{'_SESSION_CTIME'}, "\n" if (defined $session{'_SESSION_CTIME'});
    print "_SESSION_ATIME       : ", $session{'_SESSION_ATIME'}, "\n" if (defined $session{'_SESSION_ATIME'});
    print "_SESSION_ETIME       : ", $session{'_SESSION_ETIME'}, "\n" if (defined $session{'_SESSION_ETIME'});
    print "_SESSION_EXPIRE_LIST : ", $session{'_SESSION_EXPIRE_LIST'}, "\n" if (defined $session{'_SESSION_EXPIRE_LIST'});
    print "ASNMTAP              : ", $session{'ASNMTAP'}, "\n" if (defined $session{'ASNMTAP'});
    print "~login-trials        : ", $session{'~login-trials'}, "\n" if (defined $session{'~login-trials'});
    print "~logged-in           : ", $session{'~logged-in'}, "\n" if (defined $session{'~logged-in'});
    print "remoteUser           : ", $session{'remoteUser'}, "\n" if (defined $session{'remoteUser'});
    print "remoteAddr           : ", $session{'remoteAddr'}, "\n" if (defined $session{'remoteAddr'});
    print "remoteNetmask        : ", $session{'remoteNetmask'}, "\n" if (defined $session{'remoteNetmask'});
    print "givenName            : ", $session{'givenName'}, "\n" if (defined $session{'givenName'});
    print "familyName           : ", $session{'familyName'}, "\n" if (defined $session{'familyName'});
    print "email                : ", $session{'email'}, "\n" if (defined $session{'email'});
    print "keyLanguage          : ", $session{'keyLanguage'}, "\n" if (defined $session{'keyLanguage'});
    print "password             : ", $session{'password'}, "\n" if (defined $session{'password'});
    print "userType             : ", $session{'userType'}, "\n" if (defined $session{'userType'});
    print "pagedir              : ", $session{'pagedir'}, "\n" if (defined $session{'pagedir'});
    print "activated            : ", $session{'activated'}, "\n" if (defined $session{'activated'});
    print "iconAdd              : ", $session{'iconAdd'}, "\n" if (defined $session{'iconAdd'});
    print "iconDetails          : ", $session{'iconDetails'}, "\n" if (defined $session{'iconDetails'});
    print "iconEdit             : ", $session{'iconEdit'}, "\n" if (defined $session{'iconEdit'});
    print "iconDelete           : ", $session{'iconDelete'}, "\n" if (defined $session{'iconDelete'});
    print "iconQuery            : ", $session{'iconQuery'}, "\n" if (defined $session{'iconQuery'});
    print "iconTable            : ", $session{'iconTable'}, "\n" if (defined $session{'iconTable'});
  }

  if (defined $session{'_SESSION_ID'} and $session{'_SESSION_ID'} eq $sessionID) {
    print "\n-> cgisess '$cgipath/$filename' correct sessionID: $sessionID!\n" if ($Tdebug);
    return (1, %session);
  } else {
    print "\n-> cgisess '$cgipath/$filename' wrong sessionID: $sessionID!\n" if ($Tdebug);
    return (0, ());
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_trendline_from_test {
  my ($test) = @_;

  my ($pos, $posFrom);
  my $trendline = 0;

  if (($pos = index $test, " -t ") ne -1) {
    $posFrom = $pos + 4;
  } elsif (($pos = index $test, " --trendline=") ne -1) {
    $posFrom = $pos + 13;
  }

  if (defined $posFrom) {
    $trendline = substr($test, $posFrom);
    $trendline =~ s/(\d+)[ |\n][\D|\d]*/$1/g;
  }

  return $trendline;
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub _in_cyclus {
  my ($what, $cyclus, $min, $max) = @_;

  my @a = split(/,/, $cyclus);
  my @b = ();
  my ($x, $i);

  map {
    if (/^\*\/(\d+)$/) {                                          # */n
      if ($1) {
        for $i ($min..$max) { push (@b, $i) if ((($i-$min) % $1) == 0); };
      }
    } elsif (/^\*$/) {                                            # *
      push (@b, $min..$max);
    } elsif (/^(\d+)-(\d+)\/(\d+)$/) {					          # x-y/n
      if ($3) {
        for $i ($1..$2) { push (@b, $i) if ((($i-$1) % $3) == 0); };
      }
    } elsif (/^(\d+)-(\d+)$/) {                                   # x-y
      push (@b, $1..$2);
    } else {                                                      # x
      push (@b, $_);
    }
  } @a;

  for $x (@b) { return (1) if ($what eq $x); }
  return (0);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub set_doIt_and_doOffline {
  my ($min, $hour, $mday, $mon, $wday, $tmin, $thour, $tmday, $tmon, $twday) = @_;

  my ($doIt, $doOffline);

  # do it -- this month?
  $doIt = (($tmon eq "*") || ($mon eq $tmon) || _in_cyclus($mon, $tmon, 1, 12)) ? 1 : 0;

  # do it -- this day of the month?
  $doIt = ($doIt && (($tmday eq "*") || ($mday eq $tmday) || _in_cyclus($mday, $tmday, 1, 31))) ? 1 : 0;

  # do it -- this day of the week?
  $doIt = ($doIt && (($twday eq "*") || ($wday eq $twday) || _in_cyclus($wday, $twday, 0, 6))) ? 1 : 0;

  # do it -- this hour?
  $doIt = ($doIt && (($thour eq "*") || ($hour eq $thour)|| _in_cyclus($hour, $thour, 0, 23))) ? 1 : 0;

  # do it -- this minute?
  $doIt = ($doIt && (($tmin eq "*") || ($min eq $tmin) || _in_cyclus($min, $tmin, 0, 59))) ? 1 : 0;

  # do Offline?
  $doOffline = (!$doIt && (($min eq $tmin) || _in_cyclus($min, $tmin, 0, 59))) ? 1 : 0;

  return ($doIt, $doOffline);
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub create_header {
  my $filename = shift;

  if (! -e "$filename") {                            # create HEADER.html
    my $rvOpen = open(HEADER, ">$filename");

    if ($rvOpen) {
      print_header (*HEADER, "index", "index-cv", $APPLICATION, "Debug", 3600, "", 'F', "", undef, "asnmtap-results.css");
      print HEADER '<br>', "\n", '<table WIDTH="100%" border=0><tr><td class="DataDirectory">', "\n";
      close(HEADER);
    } else {
      print "Cannot open $filename to create reports page\n";
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_footer {
  my $filename = shift;

  if (! -e "$filename") {                            # create FOOTER.html
    my $rvOpen = open(FOOTER, ">$filename");

    if ($rvOpen) {
      print FOOTER '</td></tr></table>', "\n", '<BR>', "\n";
      print_legend (*FOOTER);
      print FOOTER '</BODY>', "\n", '</HTML>', "\n";
      close(FOOTER);
    } else {
      print "Cannot open $filename to create reports page\n";
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub encode_html_entities {
  my ($type, $string) = @_;

  sub convert_octalLatin1_to_decimalHtmlEntity {
    my $octalLatin1 = shift;
    return ("&#" .oct($octalLatin1). ";");
  }

  sub convert_charLatin1_to_decimalHtmlEntity {
    my $charLatin1 = shift;
    return ("&#" .ord($charLatin1). ";");
  }

  # Entities:  & | é @ " # ' ( § ^ è ! ç { à } ) ° - _ ^ ¨ $ * ù % ´ µ £ ` , ? ; . : / = + ~ < > \ ² ³ €
  use HTML::Entities;

  my $htmlEntityString;

  if ($type eq 'A') {      # convert All entities
    $htmlEntityString = encode_entities($string);
  } elsif ($type eq 'C') { # Comment data
    $htmlEntityString = encode_entities($string, ' &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:=\+~²³€');
  } elsif ($type eq 'D') { # Debug data
    $htmlEntityString = encode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'E') { # Error status message
    $htmlEntityString = encode_entities($string, '&|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'K') { # primary Key
    $htmlEntityString = encode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'M') { # status Message
    $htmlEntityString = encode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'S') { # Status
    $htmlEntityString = encode_entities($string, '<>');
  } elsif ($type eq 'T') { # Title
    $htmlEntityString = encode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'U') { # Url
    $htmlEntityString = encode_entities($string, '& ');
  } elsif ($type eq 'V') { # session Variable
    $htmlEntityString = encode_entities($string);
    $htmlEntityString =~ s/\\([2][4-7][0-7]|[3][0-7][0-7])/convert_octalLatin1_to_decimalHtmlEntity($1)/eg;
    $htmlEntityString =~ s/([\240-\377])/convert_charLatin1_to_decimalHtmlEntity($1)/eg;
  } else {
    $htmlEntityString = $string;
  }

  return ($htmlEntityString);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub decode_html_entities {
  my ($type, $string) = @_;

  # Entities:  & | é @ " # ' ( § ^ è ! ç { à } ) ° - _ ^ ¨ $ * ù % ´ µ £ ` , ? ; . : / = + ~ < > \ ² ³ €
  use HTML::Entities;

  my $htmlEntityString;

  if ($type eq 'A') {      # convert All entities
    $htmlEntityString = decode_entities($string);
  } elsif ($type eq 'C') { # Comment data
    $htmlEntityString = decode_entities($string, ' &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:=\+~²³€');
  } elsif ($type eq 'D') { # Debug data
    $htmlEntityString = decode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'E') { # Error status message
    $htmlEntityString = decode_entities($string, '&|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'K') { # primary Key
    $htmlEntityString = decode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'M') { # status Message
    $htmlEntityString = decode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'S') { # Status
    $htmlEntityString = decode_entities($string, '<>');
  } elsif ($type eq 'T') { # Title
    $htmlEntityString = decode_entities($string, '<> &|é@"#(§^è!ç{à})\'°\-_^¨\$\*ù%´µ£`,?;.:\/=\+~²³€');
  } elsif ($type eq 'U') { # Url
    $htmlEntityString = decode_entities($string, '& ');
  } elsif ($type eq 'V') { # session Variable
    $htmlEntityString = decode_entities($string);
  } else {
    $htmlEntityString = $string;
  }

  return ($htmlEntityString);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_header {
  my ($HTML, $pagedir, $pageset, $htmlTitle, $subTitle, $refresh, $onload, $openPngImage, $headScript, $sessionID, $stylesheet) = @_;

  my $sessionIdOrCookie = ( defined $sessionID ) ? "&amp;CGISESSID=$sessionID" : "&amp;CGICOOKIE=1";
  my $showToggle   = ($pagedir ne "<NIHIL>") ? "<A HREF=\"$HTTPSURL/nav/$pagedir/$pageset.html\">" : "<A HREF=\"/cgi-bin/$pageset/index.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F$sessionIdOrCookie\">";
  $showToggle     .= "<IMG SRC=\"$IMAGESURL/toggle.gif\" title=\"Toggle\" alt=\"Toggle\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>";
  my $showReport   = ($pagedir ne "<NIHIL>") ? "<A HREF=\"$HTTPSURL/nav/$pagedir/reports-$pageset.html\"><IMG SRC=\"$IMAGESURL/report.gif\" title=\"Report\" alt=\"Report\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : "";
  my $showOnDemand = ($pagedir ne "<NIHIL>") ? "<A HREF=\"/cgi-bin/runCmdOnDemand.pl?pagedir=$pagedir&amp;pageset=$pageset$sessionIdOrCookie\"><IMG SRC=\"$IMAGESURL/ondemand.gif\" title=\"On demand\" alt=\"On demand\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : "";
  my $showData     = ($pagedir ne "<NIHIL>") ? "<A HREF=\"/cgi-bin/getArchivedReport.pl?pagedir=$pagedir&amp;pageset=$pageset$sessionIdOrCookie\"><IMG SRC=\"$IMAGESURL/data.gif\" title=\"Report Archive\" alt=\"Report Archive\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : "";
  my $showAwstats  = "<A HREF=\"/awstats/awstats.pl\" target=\"_blank\"><IMG SRC=\"$IMAGESURL/awstats.gif\" title=\"Awstats\" alt=\"Awstats\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>";
  my $showInfo     = "<A HREF=\"/cgi-bin/info.pl?pagedir=$pagedir&amp;pageset=$pageset$sessionIdOrCookie\"><IMG SRC=\"$IMAGESURL/info.gif\" title=\"Info\" alt=\"Info\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>";

  $stylesheet = "asnmtap.css" if (! defined $stylesheet);

  my $showRefresh = "";
  my $metaRefresh = ( $onload eq 'ONLOAD="startRefresh();"' ) ? "" : "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"$refresh\">";

  print $HTML <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>$APPLICATION @ $BUSINESS</title>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
  <META HTTP-EQUIV="Expires" CONTENT="Wed, 10 Dec 2003 00:00:01 GMT">
  <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
  <META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
  $metaRefresh
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/$stylesheet">
  $headScript
  <script language="JavaScript1.2" type="text/javascript">
    function LegendSound(sound) {
EndOfHtml

  if ($subTitle !~ /^Reports\&nbsp\;\&nbsp\;/) {
    print $HTML "      document.getElementById('LegendSound').innerHTML='<embed src=\"$HTTPSURL/sound/' + sound + '\" width=\"\" height=\"\" hidden=\"true\" autostart=\"true\">'\n";
  }

  print $HTML "    }\n  </script>\n";
  
  if ( $onload eq 'ONLOAD="startRefresh();"' ) {
    $showRefresh = "<span id=\"refreshID\" class=\"LegendLastUpdate\"></span>";

    my ($pagesetName, $pagesetExtention) = split (/-/, $pageset);
    my $pagesetNameExtention = (defined $pagesetExtention) ? "$pagesetName" : "$pagesetName-cv";
    my $startRefresh = $refresh * 1000;

    print $HTML "  <script language=\"JavaScript1.2\" type=\"text/javascript\">
    function startRefresh() {
      timerID = setTimeout(\"location.href='$HTTPSURL/nav/$pagedir/$pagesetNameExtention.html'\", $startRefresh);
      document.body.style.backgroundImage = 'url($IMAGESURL/startRefresh.gif)';
      document.getElementById('refreshID').innerHTML='<A HREF=\"javascript:stopRefresh();\" title=\"Stop Refresh\" alt=\"Stop Refresh\"><img src=\"$IMAGESURL/stop.gif\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0><\\/A>'
    }

    function stopRefresh() {
      clearTimeout(timerID);
      document.body.style.backgroundImage = 'url($IMAGESURL/stopRefresh.gif)';
      document.getElementById('refreshID').innerHTML='<A HREF=\"javascript:startRefresh();\" title=\"Start Refresh\" alt=\"Start Refresh\"><img src=\"$IMAGESURL/start.gif\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0<\\/A>'
    }
  </script>\n";
  }

  if ( $openPngImage eq 'T' ) {
    print $HTML <<EndOfHtml;
  <script language="JavaScript1.2" type="text/javascript">
    function chromeless(u,n,W,H,X,Y,tH,tW,wB,wBs,wBG,wBGs,wNS,fSO,brd,bli,max,min,res,tsz){
      var c=(document.all&&navigator.userAgent.indexOf("Win")!=-1)?1:0
      var v=navigator.appVersion.substring(navigator.appVersion.indexOf("MSIE ")+5,navigator.appVersion.indexOf("MSIE ")+8)
      min=(v>=5.5?min:false);
      var w=window.screen.width; var h=window.screen.height
      var W=W||w; W=(typeof(W)=='string'?Math.ceil(parseInt(W)*w/100):W); W+=(brd*2+2)*c
      var H=H||h; H=(typeof(H)=='string'?Math.ceil(parseInt(H)*h/100):H); H+=(tsz+brd+2)*c
      var X=X||Math.ceil((w-W)/2)
      var Y=Y||Math.ceil((h-H)/2)
      var s=",width="+W+",height="+H
      var CWIN=window.open(u,n,wNS+s,true)
      CWIN.moveTo(X,Y)
      CWIN.focus()
      CWIN.setURL=function(u) { if (this && !this.closed) { if (this.frames.main) this.frames.main.location.href=u; else this.location.href=u } }
      CWIN.closeIT=function() { if (this && !this.closed) this.close() }
      return CWIN
    }

    function openPngImage(u,W,H,X,Y,n,b,x,t, m,r) {
      var tH  = '<font face=verdana color=#0000FF size=1>' + t + '<\\/font>';
      var tW  = '&nbsp;' + t;
      var wB  = '#0000FF';
      var wBs = '#0000FF';
      var wBG = '#000066';
      var wBGs= '#000000';
      var wNS = 'toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=1,resizable=0';
      var fSO = 'scrolling=yes noresize';
      var brd = b;
      var bli = 1;
      var max = x||false;
      var res = r||false;
      var min = m||true;
      var tsz = 20;
      return chromeless(u,n,W,H,X,Y,tH,tW,wB,wBs,wBG,wBGs,wNS,fSO,brd,bli,max,min,res,tsz);
    }
  </script>
EndOfHtml
  }

  print $HTML <<EndOfHtml;
</head>
<BODY $onload>
  <TABLE WIDTH="100%"><TR>
    <TD ALIGN="LEFT" WIDTH="260">
      $showToggle
      $showReport
      $showOnDemand
      $showData
      $showAwstats
      $showInfo
      $showRefresh
    </TD>
	<td class="HeaderTitel">$htmlTitle</td><td width="180" class="HeaderSubTitel">$subTitle</td>
  </TR></TABLE>
  <HR>
EndOfHtml

  if ( $pagedir ne "<NIHIL>" and $pageset ne "<NIHIL>" ) {
    my $reportFilename = $HTTPSPATH . "/nav/" . $pagedir . "/reports-" . $pageset . ".html";

    if (! -e "$reportFilename") { # create $reportFilename
      my $rvOpen = open(REPORTS, ">$reportFilename");

	  if ($rvOpen) {
        print REPORTS <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
<html>
<head>
  <title>$APPLICATION @ $BUSINESS</title>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
  <META HTTP-EQUIV="Expires" CONTENT="Wed, 10 Dec 2003 00:00:01 GMT">
  <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
  <META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
  <META HTTP-EQUIV="Refresh" CONTENT="$refresh">
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/asnmtap.css">
</head>
<BODY $onload>
  <TABLE WIDTH="100%"><TR>
    <TD ALIGN="LEFT" WIDTH="260">
      $showToggle
      $showReport
      $showOnDemand
      $showData
      $showAwstats
      $showInfo
    </TD>
	<td class="HeaderTitel">$htmlTitle</td><td width="180" class="HeaderSubTitel">Reports Menu</td>
  </TR></TABLE>
  <HR>

  <br>
  <table border="0" cellpadding="0" cellspacing="0" summary="menu" width="100%">
    <tr><td class="ReportItem"><a href="/cgi-bin/detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;CGICOOKIE=1&amp;detailed=on">Detailed Statistics &amp; Report Generation</a></td></tr>
    <tr><td>&nbsp;</td></tr>
    <tr><td class="ReportItem"><a href="/cgi-bin/detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;CGICOOKIE=1&amp;detailed=off">Compare Response Time Trends</a></td></tr>
    <tr><td>&nbsp;</td></tr>
EndOfHtml

        print REPORTS '    <tr><td>&nbsp;</td></tr>', "\n", '    <tr><td>&nbsp;</td></tr>', "\n", "    <tr><td class=\"ReportItem\"><a href=\"/cgi-bin/perfparse.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;CGICOOKIE=1\">PerfParse facilities for the performance data produced by the $APPLICATION</a></td></tr>", "\n" if (-e "$HTTPSPATH/cgi-bin/perfparse.cgi");
        print REPORTS '  </table>', "\n", '  <br>', "\n";
        print_legend (*REPORTS);
        print REPORTS '</body>', "\n", '</html>', "\n";

        close(REPORTS);
      } else {
        print "Cannot open $reportFilename to create reports page\n";
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_legend {
  my $HTML = shift;

  print $HTML <<EndOfHtml;
<HR>
<table width="100%">
  <tr>
    <td class="LegendCopyright">&copy; Copyright $COPYRIGHT \@ $BUSINESS</td>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'IN PROGRESS'}"><IMG SRC="$IMAGESURL/$ICONS{'IN PROGRESS'}" ALT="IN PROGRESS" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> in progress</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'OK'}"><IMG SRC="$IMAGESURL/$ICONS{'OK'}" ALT="OK" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> ok</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'TRENDLINE'}"><IMG SRC="$IMAGESURL/$ICONS{'TRENDLINE'}" ALT="TRENDLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'TRENDLINE'}}');"> trendline</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'WARNING'}"><IMG SRC="$IMAGESURL/$ICONS{'WARNING'}" ALT="WARNING" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'WARNING'}}');"> warning</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'CRITICAL'}"><IMG SRC="$IMAGESURL/$ICONS{'CRITICAL'}" ALT="CRITICAL" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'CRITICAL'}}');"> critical</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'UNKNOWN'}"><IMG SRC="$IMAGESURL/$ICONS{'UNKNOWN'}" ALT="UNKNOWN" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{UNKNOWN}}');"> unknown</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO TEST'}"><IMG SRC="$IMAGESURL/$ICONS{'NO TEST'}" ALT="NO TEST" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> no test</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO DATA'}"><IMG SRC="$IMAGESURL/$ICONS{'NO DATA'}" ALT="NO DATA" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'NO DATA'}}');"> no data</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'OFFLINE'}"><IMG SRC="$IMAGESURL/$ICONS{'OFFLINE'}" ALT="OFFLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> offline</FONT></TD>
    <td align="right"><span id="LegendSound" class="LegendLastUpdate">&nbsp;</span>v$RMVERSION</td>
  </tr><tr>
	<td>&nbsp;</td>
	<td class="LegendIcons">Comments:</td>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'OK'}"><IMG SRC="$IMAGESURL/$ICONSACK{'OK'}" ALT="OK" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> ok</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'TRENDLINE'}"><IMG SRC="$IMAGESURL/$ICONSACK{'TRENDLINE'}" ALT="TRENDLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'TRENDLINE'}}');"> trendline</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'WARNING'}"><IMG SRC="$IMAGESURL/$ICONSACK{'WARNING'}" ALT="WARNING" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'WARNING'}}');"> warning</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'CRITICAL'}"><IMG SRC="$IMAGESURL/$ICONSACK{'CRITICAL'}" ALT="CRITICAL" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'CRITICAL'}}');"> critical</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'UNKNOWN'}"><IMG SRC="$IMAGESURL/$ICONSACK{'UNKNOWN'}" ALT="UNKNOWN" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{UNKNOWN}}');"> unknown</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO TEST'}"><IMG SRC="$IMAGESURL/$ICONSACK{'NO TEST'}" ALT="NO TEST" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> no test</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO DATA'}"><IMG SRC="$IMAGESURL/$ICONSACK{'NO DATA'}" ALT="NO DATA" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'NO DATA'}}');"> no data</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'OFFLINE'}"><IMG SRC="$IMAGESURL/$ICONSACK{'OFFLINE'}" ALT="OFFLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> offline</FONT></TD>
    <td class="LegendLastUpdate">last update:&nbsp;&nbsp;
EndOfHtml

  print $HTML get_datetimeSignal();

  print $HTML <<EndOfHtml;
    </td>
  </tr>
</table>
<HR>
EndOfHtml
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub init_email_report {
  my ($EMAILREPORT, $filename, $debug) = @_;

  my $emailReport = $RESULTSPATH .'/'. $filename;
  my $rvOpen = ( $debug ) ? '1' : open($EMAILREPORT, "> $emailReport");

  return ($emailReport, $rvOpen);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub send_email_report {
  my ($EMAILREPORT, $emailReport, $rvOpen, $prgtext, $debug) = @_;

  my $returnCode;
  
  if ( $rvOpen and ! $debug ) {
    close($EMAILREPORT);

    if (-e "$emailReport") {
      my $emailMessage;
      $rvOpen = open($EMAILREPORT, "$emailReport");

      if ($rvOpen) {
        while (<$EMAILREPORT>) { $emailMessage .= $_; }
        close($EMAILREPORT);

        if (defined $emailMessage) {
          my $subject = "$prgtext / Daily status: " . get_csvfiledate();
          ($returnCode) = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $emailMessage, $debug );
          print "Problem sending email to the '$APPLICATION' server administrators\n" if ( ! $returnCode );
        }
      } else {
        print "Cannot open $emailReport to send email report information\n";
      }
    } else {
      print "$emailReport to send email report information don't exists\n";
    }
  }

  return ($returnCode);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub sending_mail {
  my ( $serverListSMTP, $mailTo, $mailFrom, $mailSubject, $mailBody, $debug ) = @_;

  use Mail::Sendmail qw(sendmail %mailcfg);
  $mailcfg{port}     = 25;
  $mailcfg{retries}  = 3;
  $mailcfg{delay}    = 1;
  $mailcfg{mime}     = 0;
  $mailcfg{debug}    = ($debug eq 'T') ? 1 : 0;
  $mailcfg{smtp}     = $serverListSMTP;

  my %mail = ( To => $mailTo, From => $mailFrom, Subject => $mailSubject, Message => $mailBody );
  my $returnCode = (sendmail %mail) ? 1 : 0;
  print "\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log, "\n" if ($debug);
  return ($returnCode);
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub error_Trap_DBI {
  my ($EMAILREPORT, $error_message, $debug) = @_;

  my $error = "  > DBI Error:\n" .$error_message. "\nERROR: $DBI::err ($DBI::errstr)\n";
  if ( $debug ) { print $error; } else { print $EMAILREPORT $error; }
  return 0;
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Applications Subclass of ASNMTAP::Asnmtap

=head1 Description

ASNMTAP::Asnmtap::Applications is a Perl module that provides a nice object oriented interface for ASNMTAP Applications

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Applications::CGI, ASNMTAP::Asnmtap::Applications::Collector, ASNMTAP::Asnmtap::Applications::Display

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

ASNMTAP is based on 'Process System daemons v1.60.17-01', Alex Peeters [alex.peeters@citap.com]

Purpose: CronTab (CT, sysdCT),
         Disk Filesystem monitoring (DF, sysdDF),
         Intrusion Detection for FW-1 (ID, sysdID)
         Process System daemons (PS, sysdPS),
         Reachability of Remote Hosts on a network (RH, sysdRH),
         Rotate Logfiles (system activity files) (RL),
         Remote Socket monitoring (RS, sysdRS),
         System Activity monitoring (SA, sysdSA).

'Process System daemons' is based on 'sysdaemon 1.60' written by Trans-Euro I.T Ltd

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
