# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/09/16, v3.000.011, package ASNMTAP::Asnmtap::Applications
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

use ASNMTAP::Time qw(&get_csvfiledate &get_datetimeSignal);

use ASNMTAP::Asnmtap qw(:ASNMTAP :COMMANDS :_HIDDEN :APPLICATIONS :PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Applications::ISA         = qw(Exporter ASNMTAP::Asnmtap);

  %ASNMTAP::Asnmtap::Applications::EXPORT_TAGS = (ALL          => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO
                                                                       $CAPTUREOUTPUT
                                                                       $PREFIXPATH $LOGPATH $PIDPATH
                                                                       %ERRORS %STATE %TYPE

                                                                       $CHATCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND

                                                                       &_checkAccObjRef
                                                                       &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                                       &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                                       &_dumpValue

                                                                       $APPLICATIONPATH $PLUGINPATH
 							   
                                                                       $ASNMTAPMANUAL
                                                                       $DATABASE
                                                                       $CONFIGDIR $CGISESSDIR $DEBUGDIR $REPORTDIR $RESULTSDIR
                                                                       $CGISESSPATH $HTTPSPATH $IMAGESPATH $PDPHELPPATH $RESULTSPATH $SSHKEYPATH $WWWKEYPATH
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
                                                 					   &error_Trap_DBI

                                                                       &print_revision &usage &call_system) ],

                                                  APPLICATIONS => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO
                                                                       $CAPTUREOUTPUT
                                                                       $PREFIXPATH $PLUGINPATH $LOGPATH $PIDPATH
                                                                       %ERRORS %STATE %TYPE

                                                                       &sending_mail

                                                                       &print_revision &usage &call_system) ],

                                                  COMMANDS     => [ qw($CHATCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND) ],

                                                 _HIDDEN       => [ qw(&_checkAccObjRef
                                                                       &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                                       &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                                       &_dumpValue) ],

                                                  ARCHIVE      => [ qw($DATABASE
                                                                       $DEBUGDIR $REPORTDIR
                                                                       $CGISESSPATH $RESULTSPATH
                                                                       $SMTPUNIXSYSTEM $SERVERLISTSMTP $SERVERSMTP $SENDMAILFROM
                                                                       &read_table &get_session_param
                                                                       &init_email_report &send_email_report) ],

                                                  DBARCHIVE    => [ qw($DATABASE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE $SERVERTABLEVENTS $SERVERTABLCOMMENTS)],

                                                  COLLECTOR    => [ qw($APPLICATIONPATH

                                                                       $DEBUGDIR
                                                                       $HTTPSPATH $RESULTSPATH $PIDPATH
                                                                       $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                                                       %COLORSRRD
                                                                       &read_table &get_trendline_from_test
                                                                       &set_doIt_and_doOffline
                                                                       &create_header &create_footer

                                                                       &print_revision &usage &call_system) ],

                                                  DBCOLLECTOR  => [ qw($DATABASE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                                                       $SERVERTABLCOMMENTS $SERVERTABLEVENTS) ],
 
                                                  DISPLAY      => [ qw($APPLICATIONPATH

                                                                       $HTTPSPATH $RESULTSPATH $PIDPATH
                                                                       $HTTPSURL $IMAGESURL $RESULTSURL
                                                                       $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                                                       $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $STATUSHEADER01
                                                                       %COLORS %ICONS %ICONSACK %ICONSRECORD %SOUND
                                                                       &read_table &get_trendline_from_test
                                                                       &create_header &create_footer &encode_html_entities &decode_html_entities &print_header &print_legend

                                                                       &print_revision &usage &call_system) ],
 
                                                  DBDISPLAY    => [ qw($DATABASE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE 
                                                                       $SERVERTABLCOMMENTS $SERVERTABLEVENTS) ],
									   
                                                  CGI          => [ qw($APPLICATIONPATH

                                                                       $ASNMTAPMANUAL
                                                                       $DATABASE
                                                                       $CONFIGDIR $CGISESSDIR $DEBUGDIR $REPORTDIR $RESULTSDIR
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
                                                                       $SERVERTABLCLLCTRDMNS $SERVERTABLCOMMENTS $SERVERTABLCOUNTRIES $SERVERTABLCRONTABS $SERVERTABLDSPLYDMNS $SERVERTABLDSPLYGRPS $SERVERTABLEVENTS $SERVERTABLHOLIDYS $SERVERTABLHLDSBNDL $SERVERTABLLANGUAGE $SERVERTABLPAGEDIRS $SERVERTABLPLUGINS $SERVERTABLREPORTS $SERVERTABLRSLTSDR $SERVERTABLSERVERS $SERVERTABLUSERS $SERVERTABLVIEWS) ] );

  @ASNMTAP::Asnmtap::Applications::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Applications::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Applications::VERSION     = 3.000.011;
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# TMP, exist into: Asnmtap

sub print_revision ($$);
sub usage;
sub call_system;

sub print_revision ($$) {
  my $commandName = shift;
  my $pluginRevision = shift;
  $pluginRevision =~ s/^\$Revision: //;
  $pluginRevision =~ s/ \$\s*$//;

  print "
$commandName $pluginRevision

© Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub usage {
  my $format = shift;
  printf($format, @_);
  exit $ERRORS{UNKNOWN};
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub call_system {
  my ($system_action, $debug) = @_;

  my ($stdout, $stderr, $exit_value, $signal_num, $dumped_core, $status);

  if ($CAPTUREOUTPUT) {
    use IO::CaptureOutput qw(capture_exec);
   ($stdout, $stderr) = capture_exec("$system_action");
  } else {
    system ("$system_action"); $stdout = $stderr = '';
  }

  $exit_value  = $? >> 8;
  $signal_num  = $? & 127;
  $dumped_core = $? & 128;
  $status = ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 && $stderr eq '' ) ? 1 : 0;
  print "< $system_action >< $exit_value >< $signal_num >< $dumped_core >< $status >< $stdout >< $stderr >\n" if ($debug);
  return ($status, $stdout, $stderr);
}

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

# Applications variables  - - - - - - - - - - - - - - - - - - - - - - - -

our $RMVERSION = '3.000.011';

our %QUARTERS  = ( '1' => '1', '2' => '4', '3' => '7', '4' => '10' );

# read config file  - - - - - - - - - - - - - - - - - - - - - - - - - - -

my %_config;

my $_configfile = "$APPLICATIONPATH/Applications.cnf";

if ( -e $_configfile ) {
  use Config::General qw(ParseConfig);
  %_config = ParseConfig ( -ConfigFile => $_configfile, -InterPolateVars => 0 ) ;
  die "ASNMTAP::Asnmtap::Applications: Config '$_configfile' can't be loaded." unless (%_config);
  undef $_configfile;
}

# SET ASNMTAP::Asnmtap::Applications VARIABLES  - - - - - - - - - - - - -

our $ASNMTAPMANUAL  = ( exists $_config{COMMON}{ASNMTAPMANUAL}     ? $_config{COMMON}{ASNMTAPMANUAL}     : 'ApplicationMonitorVersion2.000.xxx.pdf' );

our $SMTPUNIXSYSTEM = ( exists $_config{COMMON}{SMTPUNIXSYSTEM}    ? $_config{COMMON}{SMTPUNIXSYSTEM}    : 1 );
my  $serverListSMTP = ( exists $_config{COMMON}{SERVERLISTSMTP}    ? $_config{COMMON}{SERVERLISTSMTP}    : 'localhost' );
our $SERVERLISTSMTP = [ split ( /\s+/, $serverListSMTP ) ];
our $SERVERSMTP     = ( exists $_config{COMMON}{SERVERSMTP}        ? $_config{COMMON}{SERVERSMTP}        : 'localhost' );
our $SENDMAILFROM   = ( exists $_config{COMMON}{SENDMAILFROM}      ? $_config{COMMON}{SENDMAILFROM}      : 'asnmtap@localhost' );

our $HTTPSSERVER    = ( exists $_config{COMMON}{HTTPSSERVER}       ? $_config{COMMON}{HTTPSSERVER}       : 'asnmtap.localhost' );
our $REMOTE_HOST    = ( exists $_config{COMMON}{REMOTE_HOST}       ? $_config{COMMON}{REMOTE_HOST}       : 'localhost' );
our $REMOTE_ADDR    = ( exists $_config{COMMON}{REMOTE_ADDR}       ? $_config{COMMON}{REMOTE_ADDR}       : '127.0.0.1' );

our $SSHLOGONNAME   = ( exists $_config{COMMON}{SSHLOGONNAME}      ? $_config{COMMON}{SSHLOGONNAME}      : 'asnmtap' );
our $RSYNCIDENTITY  = ( exists $_config{COMMON}{RSYNCIDENTITY}     ? $_config{COMMON}{RSYNCIDENTITY}     : 'rsync' );
our $SSHIDENTITY    = ( exists $_config{COMMON}{SSHIDENTITY}       ? $_config{COMMON}{SSHIDENTITY}       : 'asnmtap' );
our $WWWIDENTITY    = ( exists $_config{COMMON}{WWWIDENTITY}       ? $_config{COMMON}{WWWIDENTITY}       : 'ssh' );

our $RMDEFAULTUSER  = ( exists $_config{COMMON}{RMDEFAULTUSER}     ? $_config{COMMON}{RMDEFAULTUSER}     : 'admin' );

our $RECORDSONPAGE  = ( exists $_config{COMMON}{RECORDSONPAGE}     ? $_config{COMMON}{RECORDSONPAGE}     : 10 );
our $NUMBEROFFTESTS = ( exists $_config{COMMON}{NUMBEROFFTESTS}    ? $_config{COMMON}{NUMBEROFFTESTS}    : 9 );
our $VERIFYNUMBEROK = ( exists $_config{COMMON}{VERIFYNUMBEROK}    ? $_config{COMMON}{VERIFYNUMBEROK}    : 3 );
our $VERIFYMINUTEOK = ( exists $_config{COMMON}{VERIFYMINUTEOK}    ? $_config{COMMON}{VERIFYMINUTEOK}    : 30 );
our $FIRSTSTARTDATE = ( exists $_config{COMMON}{FIRSTSTARTDATE}    ? $_config{COMMON}{FIRSTSTARTDATE}    : '2004-10-31' );
our $STRICTDATE     = ( exists $_config{COMMON}{STRICTDATE}        ? $_config{COMMON}{STRICTDATE}        : 0 );
our $STATUSHEADER01 = ( exists $_config{COMMON}{STATUSHEADER01}    ? $_config{COMMON}{STATUSHEADER01}    : 'De resultaten worden weergegeven binnen timeslots van vastgestelde duur per groep. De testen binnen éénzelfde groep worden sequentieel uitgevoerd.' );

our $CONFIGDIR      = 'config';
our $CGISESSDIR     = 'cgisess';
our $DEBUGDIR       = 'debug';
our $REPORTDIR      = 'reports';
our $RESULTSDIR     = 'results';

if ( exists $_config{SUBDIR} ) {
  $CONFIGDIR        = $_config{SUBDIR}{CONFIG}  if ( exists $_config{SUBDIR}{CONFIG} );
  $CGISESSDIR       = $_config{SUBDIR}{CGISESS} if ( exists $_config{SUBDIR}{CGISESS} );
  $DEBUGDIR         = $_config{SUBDIR}{DEBUG}   if ( exists $_config{SUBDIR}{DEBUG} );
  $REPORTDIR        = $_config{SUBDIR}{REPORT}  if ( exists $_config{SUBDIR}{REPORT} );
  $RESULTSDIR       = $_config{SUBDIR}{RESULTS} if ( exists $_config{SUBDIR}{RESULTS} );
}

our $CGISESSPATH    = "$APPLICATIONPATH/tmp/$CGISESSDIR";

our $HTTPSPATH      = "$APPLICATIONPATH/htmlroot";
our $IMAGESPATH     = "$HTTPSPATH/img";
our $PDPHELPPATH    = "$HTTPSPATH/pdf";
our $RESULTSPATH    = "$PREFIXPATH/$RESULTSDIR";
our $SSHKEYPATH     = '/home';
our $WWWKEYPATH     = '/var/www';

if ( exists $_config{PATH} ) {
  $HTTPSPATH        = $_config{PATH}{HTTPS}   if ( exists $_config{PATH}{HTTPS} );
  $IMAGESPATH       = $_config{PATH}{IMAGES}  if ( exists $_config{PATH}{IMAGES} );
  $PDPHELPPATH      = $_config{PATH}{PDPHELP} if ( exists $_config{PATH}{PDPHELP} );
  $RESULTSPATH      = $_config{PATH}{RESULTS} if ( exists $_config{PATH}{RESULTS} );
  $SSHKEYPATH       = $_config{PATH}{SSHKEY}  if ( exists $_config{PATH}{SSHKEY} );
  $WWWKEYPATH       = $_config{PATH}{WWWKEY}  if ( exists $_config{PATH}{WWWKEY} );
}

our $HTTPSURL       = '/asnmtap';
our $IMAGESURL      = "$HTTPSURL/img";
our $PDPHELPURL     = "$HTTPSURL/pdf";
our $RESULTSURL     = "/$RESULTSDIR";

if ( exists $_config{URL} ) {
  $HTTPSURL         = $_config{URL}{HTTPS}   if ( exists $_config{URL}{HTTPS} );
  $IMAGESURL        = $_config{URL}{IMAGES}  if ( exists $_config{URL}{IMAGES} );
  $PDPHELPURL       = $_config{URL}{PDPHELP} if ( exists $_config{URL}{PDPHELP} );
  $RESULTSURL       = $_config{URL}{RESULTS} if ( exists $_config{URL}{RESULTS} );
}

our $HTMLTOPDFPRG   = ( exists $_config{COMMON}{HTMLTOPD}{PRG}     ? $_config{COMMON}{HTMLTOPD}{PRG}     : 'htmldoc' );
our $HTMLTOPDFHOW   = ( exists $_config{COMMON}{HTMLTOPD}{HOW}     ? $_config{COMMON}{HTMLTOPD}{HOW}     : 'shell' );
our $HTMLTOPDFOPTNS = ( exists $_config{COMMON}{HTMLTOPD}{OPTIONS} ? $_config{COMMON}{HTMLTOPD}{OPTIONS} : "--bodyimage $IMAGESPATH/logos/bodyimage.gif --format pdf14 --size A4 --landscape --browserwidth 1280 --top 10mm --bottom 10mm --left 10mm --right 10mm --fontsize 10.0 --fontspacing 1.2 --headingfont Helvetica --bodyfont Helvetica --headfootsize 10.0 --headfootfont Helvetica --embedfonts --pagemode fullscreen --permissions no-copy,print --no-links --color --quiet --webpage --header ... --footer ..." );

our $DATABASE       = ( exists $_config{DATABASE}{ASNMTAP}         ? $_config{DATABASE}{ASNMTAP}         : 'asnmtap' );

# archiver, collector.pl and display.pl - - - - - - - - - - - - - - - - -
# comments.pl, holidayBundleSetDowntimes.pl - - - - - - - - - - - - - - -
# scripts into directory /cgi-bin/admin & /cgi-bin/sadmin - - - - - - - -
our $SERVERNAMEREADWRITE  = ( exists $_config{DATABASE_ACCOUNT}{READWRITE}{HOST}     ? $_config{DATABASE_ACCOUNT}{READWRITE}{HOST}     : 'localhost' );
our $SERVERPORTREADWRITE  = ( exists $_config{DATABASE_ACCOUNT}{READWRITE}{PORT}     ? $_config{DATABASE_ACCOUNT}{READWRITE}{PORT}     : '3306' );
our $SERVERUSERREADWRITE  = ( exists $_config{DATABASE_ACCOUNT}{READWRITE}{USERNAME} ? $_config{DATABASE_ACCOUNT}{READWRITE}{USERNAME} : 'asnmtap' );
our $SERVERPASSREADWRITE  = ( exists $_config{DATABASE_ACCOUNT}{READWRITE}{PASSWORD} ? $_config{DATABASE_ACCOUNT}{READWRITE}{PASSWORD} : 'asnmtap' );

# comments.pl, generateChart.pl, getHelpPlugin.pl, runCommandOnDemand.pl
# and detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl -
our $SERVERNAMEREADONLY   = ( exists $_config{DATABASE_ACCOUNT}{READONLY}{HOST}      ? $_config{DATABASE_ACCOUNT}{READONLY}{HOST}      : 'localhost' );
our $SERVERPORTREADONLY   = ( exists $_config{DATABASE_ACCOUNT}{READONLY}{PORT}      ? $_config{DATABASE_ACCOUNT}{READONLY}{PORT}      : '3306' );
our $SERVERUSERREADONLY   = ( exists $_config{DATABASE_ACCOUNT}{READONLY}{USERNAME}  ? $_config{DATABASE_ACCOUNT}{READONLY}{USERNAME}  : 'asnmtapro' );
our $SERVERPASSREADONLY   = ( exists $_config{DATABASE_ACCOUNT}{READONLY}{PASSWORD}  ? $_config{DATABASE_ACCOUNT}{READONLY}{PASSWORD}  : 'asnmtapro' );

# tables
our $SERVERTABLCLLCTRDMNS = 'collectorDaemons';
our $SERVERTABLCOMMENTS   = 'comments';
our $SERVERTABLCOUNTRIES  = 'countries';
our $SERVERTABLCRONTABS   = 'crontabs';
our $SERVERTABLDSPLYDMNS  = 'displayDaemons';
our $SERVERTABLDSPLYGRPS  = 'displayGroups';
our $SERVERTABLEVENTS     = 'events';
our $SERVERTABLHOLIDYS    = 'holidays';
our $SERVERTABLHLDSBNDL   = 'holidaysBundle';
our $SERVERTABLLANGUAGE   = 'language';
our $SERVERTABLPAGEDIRS   = 'pagedirs';
our $SERVERTABLPLUGINS    = 'plugins';
our $SERVERTABLREPORTS    = 'reports';
our $SERVERTABLRSLTSDR    = 'resultsdir';
our $SERVERTABLSERVERS    = 'servers';
our $SERVERTABLUSERS      = 'users';
our $SERVERTABLVIEWS      = 'views';

if ( exists $_config{TABLES} ) {
  $SERVERTABLCLLCTRDMNS   = $_config{TABLES}{COLLECTORDAEMONS}  if ( exists $_config{TABLES}{COLLECTORDAEMONS} );
  $SERVERTABLCOMMENTS     = $_config{TABLES}{COMMENTS}          if ( exists $_config{TABLES}{COMMENTS} );
  $SERVERTABLCOUNTRIES    = $_config{TABLES}{COUNTRIES}         if ( exists $_config{TABLES}{COUNTRIES} );
  $SERVERTABLCRONTABS     = $_config{TABLES}{CRONTABS}          if ( exists $_config{TABLES}{CRONTABS} );
  $SERVERTABLDSPLYDMNS    = $_config{TABLES}{DISPLAYDAEMONS}    if ( exists $_config{TABLES}{DISPLAYDAEMONS} );
  $SERVERTABLDSPLYGRPS    = $_config{TABLES}{DISPLAYGROUPS}     if ( exists $_config{TABLES}{DISPLAYGROUPS} );
  $SERVERTABLEVENTS       = $_config{TABLES}{EVENTS}            if ( exists $_config{TABLES}{EVENTS} );
  $SERVERTABLHOLIDYS      = $_config{TABLES}{HOLIDAYS}          if ( exists $_config{TABLES}{HOLIDAYS} );
  $SERVERTABLHLDSBNDL     = $_config{TABLES}{HOLIDAYSBUNDLE}    if ( exists $_config{TABLES}{HOLIDAYSBUNDLE} );
  $SERVERTABLLANGUAGE     = $_config{TABLES}{LANGUAGE}          if ( exists $_config{TABLES}{LANGUAGE} );
  $SERVERTABLPAGEDIRS     = $_config{TABLES}{PAGEDIRS}          if ( exists $_config{TABLES}{PAGEDIRS} );
  $SERVERTABLPLUGINS      = $_config{TABLES}{PLUGINS}           if ( exists $_config{TABLES}{PLUGINS} );
  $SERVERTABLREPORTS      = $_config{TABLES}{REPORTS}           if ( exists $_config{TABLES}{REPORTS} );
  $SERVERTABLRSLTSDR      = $_config{TABLES}{RESULTSDIR}        if ( exists $_config{TABLES}{RESULTSDIR} );
  $SERVERTABLSERVERS      = $_config{TABLES}{SERVERS}           if ( exists $_config{TABLES}{SERVERS} );
  $SERVERTABLUSERS        = $_config{TABLES}{USERS}             if ( exists $_config{TABLES}{USERS} );
  $SERVERTABLVIEWS        = $_config{TABLES}{VIEWS}             if ( exists $_config{TABLES}{VIEWS} );
}

our %COLORS      = ('OK'=>'#99CC99','WARNING'=>'#FFFF00','CRITICAL'=>'#FF4444','UNKNOWN'=>'#FFFFFF','DEPENDENT'=>'#D8D8BF','OFFLINE'=>'#0000FF','NO DATA'=>'#CC00CC','IN PROGRESS'=>'#99CC99','NO TEST'=>'#99CC99', '<NIHIL>'=>'#CC00CC','TRENDLINE'=>'#ffa000');
our %COLORSPIE   = ('OK'=>0x00BA00, 'WARNING'=>0xffff00, 'CRITICAL'=>0xff0000, 'UNKNOWN'=>0x99FFFF, 'DEPENDENT'=>0xD8D8BF, 'OFFLINE'=>0x0000FF, 'NO DATA'=>0xCC00CC, 'IN PROGRESS'=>0x99CC99, 'NO TEST'=>0x444444,  '<NIHIL>'=>0xCC00CC, 'TRENDLINE'=>0xffa000);
our %COLORSRRD   = ('OK'=>0x00BA00, 'WARNING'=>0xffff00, 'CRITICAL'=>0xff0000, 'UNKNOWN'=>0x99FFFF, 'DEPENDENT'=>0xD8D8BF, 'OFFLINE'=>0x0000FF, 'NO DATA'=>0xCC00CC, 'IN PROGRESS'=>0x99CC99, 'NO TEST'=>0x000000,  '<NIHIL>'=>0xCC00CC, 'TRENDLINE'=>0xffa000);
our %COLORSTABLE = ('TABLE'=>'#333344', 'NOBLOCK'=>'#335566','ENDBLOCK'=>'#665555','STARTBLOCK'=>'#996666');

if ( exists $_config{COLORS} ) {
  $COLORS{OK}            = '#'. $_config{COLORS}{OK}          if ( exists $_config{COLORS}{OK} );
  $COLORS{WARNING}       = '#'. $_config{COLORS}{WARNING}     if ( exists $_config{COLORS}{WARNING} );
  $COLORS{CRITICAL}      = '#'. $_config{COLORS}{CRITICAL}    if ( exists $_config{COLORS}{CRITICAL} );
  $COLORS{UNKNOWN}       = '#'. $_config{COLORS}{UNKNOWN}     if ( exists $_config{COLORS}{UNKNOWN} );
  $COLORS{DEPENDENT}     = '#'. $_config{COLORS}{DEPENDENT}   if ( exists $_config{COLORS}{DEPENDENT} );
  $COLORS{OFFLINE}       = '#'. $_config{COLORS}{OFFLINE}     if ( exists $_config{COLORS}{OFFLINE} );
  $COLORS{'NO DATA'}     = '#'. $_config{COLORS}{NO_DATA}     if ( exists $_config{COLORS}{NO_DATA} );
  $COLORS{'IN PROGRESS'} = '#'. $_config{COLORS}{IN_PROGRESS} if ( exists $_config{COLORS}{IN_PROGRESS} );
  $COLORS{'NO TEST'}     = '#'. $_config{COLORS}{NO_TEST}     if ( exists $_config{COLORS}{NO_TEST} );
  $COLORS{'<NIHIL>'}     = '#'. $_config{COLORS}{_NIHIL_}     if ( exists $_config{COLORS}{_NIHIL_} );
  $COLORS{TRENDLINE}     = '#'. $_config{COLORS}{TRENDLINE}   if ( exists $_config{COLORS}{TRENDLINE} );

  if ( exists $_config{COLORS}{PIE} ) {
    $COLORSPIE{OK}            = $_config{COLORS}{PIE}{OK}          if ( exists $_config{COLORS}{PIE}{OK} );
    $COLORSPIE{WARNING}       = $_config{COLORS}{PIE}{WARNING}     if ( exists $_config{COLORS}{PIE}{WARNING} );
    $COLORSPIE{CRITICAL}      = $_config{COLORS}{PIE}{CRITICAL}    if ( exists $_config{COLORS}{PIE}{CRITICAL} );
    $COLORSPIE{UNKNOWN}       = $_config{COLORS}{PIE}{UNKNOWN}     if ( exists $_config{COLORS}{PIE}{UNKNOWN} );
    $COLORSPIE{DEPENDENT}     = $_config{COLORS}{PIE}{DEPENDENT}   if ( exists $_config{COLORS}{PIE}{DEPENDENT} );
    $COLORSPIE{OFFLINE}       = $_config{COLORS}{PIE}{OFFLINE}     if ( exists $_config{COLORS}{PIE}{OFFLINE} );
    $COLORSPIE{'NO DATA'}     = $_config{COLORS}{PIE}{NO_DATA}     if ( exists $_config{COLORS}{PIE}{NO_DATA} );
    $COLORSPIE{'IN PROGRESS'} = $_config{COLORS}{PIE}{IN_PROGRESS} if ( exists $_config{COLORS}{PIE}{IN_PROGRESS} );
    $COLORSPIE{'NO TEST'}     = $_config{COLORS}{PIE}{NO_TEST}     if ( exists $_config{COLORS}{PIE}{NO_TEST} );
    $COLORSPIE{'<NIHIL>'}     = $_config{COLORS}{PIE}{_NIHIL_}     if ( exists $_config{COLORS}{PIE}{_NIHIL_} );
    $COLORSPIE{TRENDLINE}     = $_config{COLORS}{PIE}{TRENDLINE}   if ( exists $_config{COLORS}{PIE}{TRENDLINE} );
  }

  if ( exists $_config{COLORS}{RRD} ) {
    $COLORSRRD{OK}            = $_config{COLORS}{RRD}{OK}          if ( exists $_config{COLORS}{RRD}{OK} );
    $COLORSRRD{WARNING}       = $_config{COLORS}{RRD}{WARNING}     if ( exists $_config{COLORS}{RRD}{WARNING} );
    $COLORSRRD{CRITICAL}      = $_config{COLORS}{RRD}{CRITICAL}    if ( exists $_config{COLORS}{RRD}{CRITICAL} );
    $COLORSRRD{UNKNOWN}       = $_config{COLORS}{RRD}{UNKNOWN}     if ( exists $_config{COLORS}{RRD}{UNKNOWN} );
    $COLORSRRD{DEPENDENT}     = $_config{COLORS}{RRD}{DEPENDENT}   if ( exists $_config{COLORS}{RRD}{DEPENDENT} );
    $COLORSRRD{OFFLINE}       = $_config{COLORS}{RRD}{OFFLINE}     if ( exists $_config{COLORS}{RRD}{OFFLINE} );
    $COLORSRRD{'NO DATA'}     = $_config{COLORS}{RRD}{NO_DATA}     if ( exists $_config{COLORS}{RRD}{NO_DATA} );
    $COLORSRRD{'IN PROGRESS'} = $_config{COLORS}{RRD}{IN_PROGRESS} if ( exists $_config{COLORS}{RRD}{IN_PROGRESS} );
    $COLORSRRD{'NO TEST'}     = $_config{COLORS}{RRD}{NO_TEST}     if ( exists $_config{COLORS}{RRD}{NO_TEST} );
    $COLORSRRD{'<NIHIL>'}     = $_config{COLORS}{RRD}{_NIHIL_}     if ( exists $_config{COLORS}{RRD}{_NIHIL_} );
    $COLORSRRD{TRENDLINE}     = $_config{COLORS}{RRD}{TRENDLINE}   if ( exists $_config{COLORS}{RRD}{TRENDLINE} );
  }

  if ( exists $_config{COLORS}{TABLE} ) {
    $COLORSTABLE{TABLE}       = '#'. $_config{COLORS}{TABLE}{TABLE}      if ( exists $_config{COLORS}{TABLE}{TABLE} );
    $COLORSTABLE{NOBLOCK}     = '#'. $_config{COLORS}{TABLE}{NOBLOCK}    if ( exists $_config{COLORS}{TABLE}{NOBLOCK} );
    $COLORSTABLE{ENDBLOCK}    = '#'. $_config{COLORS}{TABLE}{ENDBLOCK}   if ( exists $_config{COLORS}{TABLE}{ENDBLOCK} );
    $COLORSTABLE{STARTBLOCK}  = '#'. $_config{COLORS}{TABLE}{STARTBLOCK} if ( exists $_config{COLORS}{TABLE}{STARTBLOCK} );
  }
}

our %ICONS       = ('OK'=>'green.gif','WARNING'=>'yellow.gif','CRITICAL'=>'red.gif','UNKNOWN'=>'clear.gif','DEPENDENT'=>'','OFFLINE'=>'blue.gif','NO DATA'=>'purple.gif','IN PROGRESS'=>'running.gif','NO TEST'=>'notest.gif','TRENDLINE'=>'orange.gif');
our %ICONSACK    = ('OK'=>'green-ack.gif','WARNING'=>'yellow-ack.gif','CRITICAL'=>'red-ack.gif','UNKNOWN'=>'clear-ack.gif','DEPENDENT'=>'','OFFLINE'=>'blue-ack.gif','NO DATA'=>'purple-ack.gif','IN PROGRESS'=>'running.gif','NO TEST'=>'notest-ack.gif','TRENDLINE'=>'orange-ack.gif');
our %ICONSRECORD = ('maintenance'=>'maintenance.gif', 'duplicate'=>'recordDuplicate.gif', 'delete'=>'recordDelete.gif', 'details'=>'recordDetails.gif', 'query'=>'recordQuery.gif', 'edit'=>'recordEdit.gif', 'table'=>'recordTable.gif', 'up'=>'1arrowUp.gif', 'down'=>'1arrowDown.gif', 'left'=>'1arrowLeft.gif', 'right'=>'1arrowRight.gif', 'first'=>'2arrowLeft.gif', 'last'=>'2arrowRight.gif');
our %ICONSSYSTEM = ('pidKill'=>'pidKill.gif', 'pidRemove'=>'pidRemove.gif', 'daemonReload'=>'daemonReload.gif', 'daemonStart'=>'daemonStart.gif', 'daemonStop'=>'daemonStop.gif', 'daemonRestart'=>'daemonRestart.gif');

if ( exists $_config{ICONS} ) {
  $ICONS{OK}            = $_config{ICONS}{OK}          if ( exists $_config{ICONS}{OK} );
  $ICONS{WARNING}       = $_config{ICONS}{WARNING}     if ( exists $_config{ICONS}{WARNING} );
  $ICONS{CRITICAL}      = $_config{ICONS}{CRITICAL}    if ( exists $_config{ICONS}{CRITICAL} );
  $ICONS{UNKNOWN}       = $_config{ICONS}{UNKNOWN}     if ( exists $_config{ICONS}{UNKNOWN} );
  $ICONS{DEPENDENT}     = $_config{ICONS}{DEPENDENT}   if ( exists $_config{ICONS}{DEPENDENT} );
  $ICONS{OFFLINE}       = $_config{ICONS}{OFFLINE}     if ( exists $_config{ICONS}{OFFLINE} );
  $ICONS{'NO DATA'}     = $_config{ICONS}{NO_DATA}     if ( exists $_config{ICONS}{NO_DATA} );
  $ICONS{'IN PROGRESS'} = $_config{ICONS}{IN_PROGRESS} if ( exists $_config{ICONS}{IN_PROGRESS} );
  $ICONS{'NO TEST'}     = $_config{ICONS}{NO_TEST}     if ( exists $_config{ICONS}{NO_TEST} );
  $ICONS{TRENDLINE}     = $_config{ICONS}{TRENDLINE}   if ( exists $_config{ICONS}{TRENDLINE} );

  if ( exists $_config{ICONS}{ACK} ) {
    $ICONSACK{OK}            = $_config{ICONS}{ACK}{OK}          if ( exists $_config{ICONS}{ACK}{OK} );
    $ICONSACK{WARNING}       = $_config{ICONS}{ACK}{WARNING}     if ( exists $_config{ICONS}{ACK}{WARNING} );
    $ICONSACK{CRITICAL}      = $_config{ICONS}{ACK}{CRITICAL}    if ( exists $_config{ICONS}{ACK}{CRITICAL} );
    $ICONSACK{UNKNOWN}       = $_config{ICONS}{ACK}{UNKNOWN}     if ( exists $_config{ICONS}{ACK}{UNKNOWN} );
    $ICONSACK{DEPENDENT}     = $_config{ICONS}{ACK}{DEPENDENT}   if ( exists $_config{ICONS}{ACK}{DEPENDENT} );
    $ICONSACK{OFFLINE}       = $_config{ICONS}{ACK}{OFFLINE}     if ( exists $_config{ICONS}{ACK}{OFFLINE} );
    $ICONSACK{'NO DATA'}     = $_config{ICONS}{ACK}{NO_DATA}     if ( exists $_config{ICONS}{ACK}{NO_DATA} );
    $ICONSACK{'IN PROGRESS'} = $_config{ICONS}{ACK}{IN_PROGRESS} if ( exists $_config{ICONS}{ACK}{IN_PROGRESS} );
    $ICONSACK{'NO TEST'}     = $_config{ICONS}{ACK}{NO_TEST}     if ( exists $_config{ICONS}{ACK}{NO_TEST} );
    $ICONSACK{TRENDLINE}     = $_config{ICONS}{ACK}{TRENDLINE}   if ( exists $_config{ICONS}{ACK}{TRENDLINE} );
  }

  if ( exists $_config{ICONS}{RECORD} ) {
    $ICONSRECORD{maintenance} = $_config{ICONS}{RECORD}{maintenance} if ( exists $_config{ICONS}{RECORD}{maintenance} );
    $ICONSRECORD{duplicate}   = $_config{ICONS}{RECORD}{duplicate}   if ( exists $_config{ICONS}{RECORD}{duplicate} );
    $ICONSRECORD{delete}      = $_config{ICONS}{RECORD}{delete}      if ( exists $_config{ICONS}{RECORD}{delete} );
    $ICONSRECORD{details}     = $_config{ICONS}{RECORD}{details}     if ( exists $_config{ICONS}{RECORD}{details} );
    $ICONSRECORD{query}       = $_config{ICONS}{RECORD}{query}       if ( exists $_config{ICONS}{RECORD}{query} );
    $ICONSRECORD{edit}        = $_config{ICONS}{RECORD}{edit}        if ( exists $_config{ICONS}{RECORD}{edit} );
    $ICONSRECORD{table}       = $_config{ICONS}{RECORD}{table}       if ( exists $_config{ICONS}{RECORD}{table} );
    $ICONSRECORD{up}          = $_config{ICONS}{RECORD}{up}          if ( exists $_config{ICONS}{RECORD}{up} );
    $ICONSRECORD{down}        = $_config{ICONS}{RECORD}{down}        if ( exists $_config{ICONS}{RECORD}{down} );
    $ICONSRECORD{left}        = $_config{ICONS}{RECORD}{left}        if ( exists $_config{ICONS}{RECORD}{left} );
    $ICONSRECORD{right}       = $_config{ICONS}{RECORD}{right}       if ( exists $_config{ICONS}{RECORD}{right} );
    $ICONSRECORD{first}       = $_config{ICONS}{RECORD}{first}       if ( exists $_config{ICONS}{RECORD}{first} );
    $ICONSRECORD{last}        = $_config{ICONS}{RECORD}{last}        if ( exists $_config{ICONS}{RECORD}{last} );
  }

  if ( exists $_config{ICONS}{SYSTEM} ) {
    $ICONSSYSTEM{pidKill}       = $_config{ICONS}{SYSTEM}{pidKill}       if ( exists $_config{ICONS}{SYSTEM}{pidKill} );
    $ICONSSYSTEM{pidRemove}     = $_config{ICONS}{SYSTEM}{pidRemove}     if ( exists $_config{ICONS}{SYSTEM}{pidRemove} );
    $ICONSSYSTEM{daemonReload}  = $_config{ICONS}{SYSTEM}{daemonReload}  if ( exists $_config{ICONS}{SYSTEM}{daemonReload} );
    $ICONSSYSTEM{daemonStart}   = $_config{ICONS}{SYSTEM}{daemonStart}   if ( exists $_config{ICONS}{SYSTEM}{daemonStart} );
    $ICONSSYSTEM{daemonStop}    = $_config{ICONS}{SYSTEM}{daemonStop}    if ( exists $_config{ICONS}{SYSTEM}{daemonStop} );
    $ICONSSYSTEM{daemonRestart} = $_config{ICONS}{SYSTEM}{daemonRestart} if ( exists $_config{ICONS}{SYSTEM}{daemonRestart} );
  }
}

our %SOUND = ('0'=>'attention.wav','1'=>'warning.wav','2'=>'critical.wav','3'=>'unknown.wav','4'=>'attention.wav','5'=>'attention.wav','6'=>'attention.wav','7'=>'nodata.wav','8'=>'attention.wav','9'=>'warning.wav');

if ( exists $_config{SOUND} ) {
  $SOUND{0} = $_config{SOUND}{0} if ( exists $_config{SOUND}{0} );
  $SOUND{1} = $_config{SOUND}{1} if ( exists $_config{SOUND}{1} );
  $SOUND{2} = $_config{SOUND}{2} if ( exists $_config{SOUND}{2} );
  $SOUND{3} = $_config{SOUND}{3} if ( exists $_config{SOUND}{3} );
  $SOUND{4} = $_config{SOUND}{4} if ( exists $_config{SOUND}{4} );
  $SOUND{5} = $_config{SOUND}{5} if ( exists $_config{SOUND}{5} );
  $SOUND{6} = $_config{SOUND}{6} if ( exists $_config{SOUND}{6} );
  $SOUND{7} = $_config{SOUND}{7} if ( exists $_config{SOUND}{7} );
  $SOUND{8} = $_config{SOUND}{8} if ( exists $_config{SOUND}{8} );
  $SOUND{9} = $_config{SOUND}{9} if ( exists $_config{SOUND}{9} );
}

undef %_config;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub read_table {
  my ($prgtext, $filename, $email, $tDebug) = @_;

  my @table = ();
  my $rvOpen = open(CT, "$APPLICATIONPATH/etc/$filename");

  if ( $rvOpen ) {
    while (<CT>) {
      chomp;

      unless ( /^#/ ) {
        my $dummy = $_;
        $dummy =~ s/\ {1,}//g;
        if ($dummy ne '') { push (@table, $_); }
      }
    }
	
    close(CT);

	if ( $email ) {
      my $debug = $tDebug;
      $debug = 0 if ($tDebug eq 'F');
      $debug = 1 if ($tDebug eq 'T');
      $debug = 2 if ($tDebug eq 'L');
      $debug = 3 if ($tDebug eq 'M');
      $debug = 4 if ($tDebug eq 'A');
      $debug = 5 if ($tDebug eq 'S');

      use Sys::Hostname;
      my $action = $email == 2 ? 'reloaded' : 'restarted';
      my $subject = "$prgtext\@". hostname() .": Config $APPLICATIONPATH/etc/$filename succesfuly $action at ". get_datetimeSignal();
      my $message = $subject ."\n";
      my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $message, $debug );
      print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );
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
  $cgisession =~ s/["']//g;

  my %session = map { my ($key, $value) = split (/ => /) } split (/,/, $cgisession);

  if ($Tdebug == 2) {
    print "Session param\n";
    print "_SESSION_ID          : ", $session{_SESSION_ID}, "\n" if (defined $session{_SESSION_ID});
    print "_SESSION_REMOTE_ADDR : ", $session{_SESSION_REMOTE_ADDR}, "\n" if (defined $session{_SESSION_REMOTE_ADDR});
    print "_SESSION_CTIME       : ", $session{_SESSION_CTIME}, "\n" if (defined $session{_SESSION_CTIME});
    print "_SESSION_ATIME       : ", $session{_SESSION_ATIME}, "\n" if (defined $session{_SESSION_ATIME});
    print "_SESSION_ETIME       : ", $session{_SESSION_ETIME}, "\n" if (defined $session{_SESSION_ETIME});
    print "_SESSION_EXPIRE_LIST : ", $session{_SESSION_EXPIRE_LIST}, "\n" if (defined $session{_SESSION_EXPIRE_LIST});
    print "ASNMTAP              : ", $session{ASNMTAP}, "\n" if (defined $session{ASNMTAP});
    print "~login-trials        : ", $session{'~login-trials'}, "\n" if (defined $session{'~login-trials'});
    print "~logged-in           : ", $session{'~logged-in'}, "\n" if (defined $session{'~logged-in'});
    print "remoteUser           : ", $session{remoteUser}, "\n" if (defined $session{remoteUser});
    print "remoteAddr           : ", $session{remoteAddr}, "\n" if (defined $session{remoteAddr});
    print "remoteNetmask        : ", $session{remoteNetmask}, "\n" if (defined $session{remoteNetmask});
    print "givenName            : ", $session{givenName}, "\n" if (defined $session{givenName});
    print "familyName           : ", $session{familyName}, "\n" if (defined $session{familyName});
    print "email                : ", $session{email}, "\n" if (defined $session{email});
    print "keyLanguage          : ", $session{keyLanguage}, "\n" if (defined $session{keyLanguage});
    print "password             : ", $session{password}, "\n" if (defined $session{password});
    print "userType             : ", $session{userType}, "\n" if (defined $session{userType});
    print "pagedir              : ", $session{pagedir}, "\n" if (defined $session{pagedir});
    print "activated            : ", $session{activated}, "\n" if (defined $session{activated});
    print "iconAdd              : ", $session{iconAdd}, "\n" if (defined $session{iconAdd});
    print "iconDetails          : ", $session{iconDetails}, "\n" if (defined $session{iconDetails});
    print "iconEdit             : ", $session{iconEdit}, "\n" if (defined $session{iconEdit});
    print "iconDelete           : ", $session{iconDelete}, "\n" if (defined $session{iconDelete});
    print "iconQuery            : ", $session{iconQuery}, "\n" if (defined $session{iconQuery});
    print "iconTable            : ", $session{iconTable}, "\n" if (defined $session{iconTable});
  }

  if (defined $session{_SESSION_ID} and $session{_SESSION_ID} eq $sessionID) {
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

  unless ( -e "$filename" ) {                        # create HEADER.html
    my $rvOpen = open(HEADER, ">$filename");

    if ($rvOpen) {
      print_header (*HEADER, "index", "index-cv", $APPLICATION, "Debug", 3600, '', 'F', '', undef, "asnmtap-results.css");
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

  unless ( -e "$filename" ) {                        # create FOOTER.html
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

  my ($pageDir, $environment) = split (/\//, $pagedir, 2);
  $environment = 'P' unless (defined $environment);
  my %ENVIRONMENT = ('P'=>'Production', 'A'=>'Acceptation', 'S'=>'Simulation', 'T'=>'Test', 'D'=>'Development', 'L'=>'Local');
  my $selectEnvironment = (( $pagedir ne '<NIHIL>' and $pageset ne '<NIHIL>' ) ? '<form><select name="environment" size="1" onChange="window.location=this.options[this.selectedIndex].value;"><option value="'. $HTTPSURL .'/nav/'. $pageDir .'/'. $pageset .'.html"'. ($environment eq 'P' ? ' selected' : '') .'>Production</option><option value="'. $HTTPSURL .'/nav/'. $pageDir .'/A/'. $pageset .'.html"'. ($environment eq 'A' ? ' selected' : '') .'>Acceptation</option><option value="'. $HTTPSURL .'/nav/'. $pageDir .'/S/'. $pageset .'.html"'. ($environment eq 'S' ? ' selected' : '') .'>Simulation</option></select></form>' : '');

  my $sessionIdOrCookie = ( defined $sessionID ) ? "&amp;CGISESSID=$sessionID" : "&amp;CGICOOKIE=1";
  my $showToggle   = ($pagedir ne '<NIHIL>') ? "<A HREF=\"$HTTPSURL/nav/$pagedir/$pageset.html\">" : "<A HREF=\"/cgi-bin/$pageset/index.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F$sessionIdOrCookie\">";
  $showToggle     .= "<IMG SRC=\"$IMAGESURL/toggle.gif\" title=\"Toggle\" alt=\"Toggle\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>";
  my $showReport   = ($pagedir ne '<NIHIL>') ? "<A HREF=\"$HTTPSURL/nav/$pagedir/reports-$pageset.html\"><IMG SRC=\"$IMAGESURL/report.gif\" title=\"Report\" alt=\"Report\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : "";
  my $showOnDemand = ($pagedir ne '<NIHIL>') ? "<A HREF=\"/cgi-bin/runCmdOnDemand.pl?pagedir=$pagedir&amp;pageset=$pageset$sessionIdOrCookie\"><IMG SRC=\"$IMAGESURL/ondemand.gif\" title=\"On demand\" alt=\"On demand\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : "";
  my $showData     = ($pagedir ne '<NIHIL>') ? "<A HREF=\"/cgi-bin/getArchivedReport.pl?pagedir=$pagedir&amp;pageset=$pageset$sessionIdOrCookie\"><IMG SRC=\"$IMAGESURL/data.gif\" title=\"Report Archive\" alt=\"Report Archive\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>" : "";
  my $showAwstats  = "<A HREF=\"/awstats/awstats.pl\" target=\"_blank\"><IMG SRC=\"$IMAGESURL/awstats.gif\" title=\"Awstats\" alt=\"Awstats\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>";
  my $showInfo     = "<A HREF=\"/cgi-bin/info.pl?pagedir=$pagedir&amp;pageset=$pageset$sessionIdOrCookie\"><IMG SRC=\"$IMAGESURL/info.gif\" title=\"Info\" alt=\"Info\" WIDTH=\"32\" HEIGHT=\"27\" BORDER=0></A>";

  $stylesheet = "asnmtap.css" unless ( defined $stylesheet );

  my $showRefresh = "";
  my $metaRefresh = ( $onload eq 'ONLOAD="startRefresh();"' ) ? "" : "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"$refresh\">";

  print $HTML <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>${ENVIRONMENT{$environment}}: $APPLICATION @ $BUSINESS</title>
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
	<td class="HeaderTitel">$htmlTitle</td><td width="180" class="HeaderSubTitel">$subTitle</td><td width="1" valign="middle">$selectEnvironment</td>
  </TR></TABLE>
  <HR>
EndOfHtml

  if ( $pagedir ne '<NIHIL>' and $pageset ne '<NIHIL>' ) {
    my $directory = $HTTPSPATH ."/nav/". $pagedir;
    next unless (-e "$directory");
    my $reportFilename = $directory . "/reports-" . $pageset . ".html";

    unless ( -e "$reportFilename" ) { # create $reportFilename
      my $rvOpen = open(REPORTS, ">$reportFilename");

      if ($rvOpen) {
        print REPORTS <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
<html>
<head>
  <title>${ENVIRONMENT{$environment}}: $APPLICATION @ $BUSINESS</title>
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
	<td class="HeaderTitel">$htmlTitle</td><td width="180" class="HeaderSubTitel">Reports Menu</td><td width="1" valign="middle">$selectEnvironment</td>
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
    <td class="LegendIcons"><FONT COLOR="$COLORS{OK}"><IMG SRC="$IMAGESURL/$ICONS{OK}" ALT="OK" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> ok</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{TRENDLINE}"><IMG SRC="$IMAGESURL/$ICONS{TRENDLINE}" ALT="TRENDLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{TRENDLINE}}');"> trendline</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{WARNING}"><IMG SRC="$IMAGESURL/$ICONS{WARNING}" ALT="WARNING" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{WARNING}}');"> warning</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{CRITICAL}"><IMG SRC="$IMAGESURL/$ICONS{CRITICAL}" ALT="CRITICAL" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{CRITICAL}}');"> critical</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{UNKNOWN}"><IMG SRC="$IMAGESURL/$ICONS{UNKNOWN}" ALT="UNKNOWN" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{UNKNOWN}}');"> unknown</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO TEST'}"><IMG SRC="$IMAGESURL/$ICONS{'NO TEST'}" ALT="NO TEST" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> no test</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO DATA'}"><IMG SRC="$IMAGESURL/$ICONS{'NO DATA'}" ALT="NO DATA" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'NO DATA'}}');"> no data</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{OFFLINE}"><IMG SRC="$IMAGESURL/$ICONS{OFFLINE}" ALT="OFFLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> offline</FONT></TD>
    <td align="right"><span id="LegendSound" class="LegendLastUpdate">&nbsp;</span>v$RMVERSION</td>
  </tr><tr>
	<td>&nbsp;</td>
	<td class="LegendIcons">Comments:</td>
    <td class="LegendIcons"><FONT COLOR="$COLORS{OK}"><IMG SRC="$IMAGESURL/$ICONSACK{OK}" ALT="OK" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> ok</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{TRENDLINE}"><IMG SRC="$IMAGESURL/$ICONSACK{TRENDLINE}" ALT="TRENDLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{TRENDLINE}}');"> trendline</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{WARNING}"><IMG SRC="$IMAGESURL/$ICONSACK{WARNING}" ALT="WARNING" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{WARNING}}');"> warning</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{CRITICAL}"><IMG SRC="$IMAGESURL/$ICONSACK{CRITICAL}" ALT="CRITICAL" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{CRITICAL}}');"> critical</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{UNKNOWN}"><IMG SRC="$IMAGESURL/$ICONSACK{UNKNOWN}" ALT="UNKNOWN" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{UNKNOWN}}');"> unknown</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO TEST'}"><IMG SRC="$IMAGESURL/$ICONSACK{'NO TEST'}" ALT="NO TEST" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> no test</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{'NO DATA'}"><IMG SRC="$IMAGESURL/$ICONSACK{'NO DATA'}" ALT="NO DATA" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle" onMouseOver="LegendSound('$SOUND{$ERRORS{'NO DATA'}}');"> no data</FONT></TD>
    <td class="LegendIcons"><FONT COLOR="$COLORS{OFFLINE}"><IMG SRC="$IMAGESURL/$ICONSACK{OFFLINE}" ALT="OFFLINE" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> offline</FONT></TD>
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
          my $subject = "$prgtext / Daily status: ". get_csvfiledate();
          $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $emailMessage, $debug );
          print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );
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

  # look at Mail.pm !!!
  use Mail::Sendmail qw(sendmail %mailcfg);
  $mailcfg{port}     = 25;
  $mailcfg{retries}  = 3;
  $mailcfg{delay}    = 1;
  $mailcfg{mime}     = 0;
  $mailcfg{debug}    = ($debug eq 'T') ? 1 : 0;
  $mailcfg{smtp}     = $serverListSMTP;

  my %mail = ( To => $mailTo, From => $mailFrom, Subject => $mailSubject, Message => $mailBody );
  my $returnCode = ( sendmail %mail ) ? 1 : 0;
  print "\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log, "\n" if ($debug);
  return ( $returnCode );
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

ASNMTAP::Asnmtap::Applications is a Perl module that provides a nice object oriented interface for ASNMTAP Applications

=head1 Description

ASNMTAP::Asnmtap::Applications Subclass of ASNMTAP::Asnmtap

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
