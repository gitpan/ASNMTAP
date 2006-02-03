# This -*- perl -*- script writes the Makefile for ASNMTAP
# $Id: Makefile.PL,v 1.00 2006/01/29 18:49:00 Alex Peeters Exp $

use 5.008005;
use strict;

# Module section  - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Config qw(%Config);
use ExtUtils::MakeMaker qw(WriteMakefile prompt);

# Configuration section - - - - - - - - - - - - - - - - - - - - - - - - -

my $VERSION = '3.000.002';

my $PERL_AUTOINSTALL     = exists $ENV{PERL_AUTOINSTALL}     ? $ENV{PERL_AUTOINSTALL}     : 0;
my $ASNMTAP_APPLICATIONS = exists $ENV{ASNMTAP_APPLICATIONS} ? $ENV{ASNMTAP_APPLICATIONS} : 0;
my $ASNMTAP_PLUGINS      = exists $ENV{ASNMTAP_PLUGINS}      ? $ENV{ASNMTAP_PLUGINS}      : 0;
my $ASNMTAP_UID          = exists $ENV{ASNMTAP_UID}          ? $ENV{ASNMTAP_UID}          : '500';
my $ASNMTAP_GID          = exists $ENV{ASNMTAP_GID}          ? $ENV{ASNMTAP_GID}          : '500';
my $ASNMTAP_PATH         = exists $ENV{ASNMTAP_PATH}         ? $ENV{ASNMTAP_PATH}         : '/opt/asnmtap';
my $ASNMTAP_PROXY        = exists $ENV{ASNMTAP_PROXY}        ? $ENV{ASNMTAP_PROXY}        : '0.0.0.0';

my @prerequisites = (
# [ '<level>', '<feature>',                '<installed module>',                  <dependency hash>, <install by default: 0 = no, 1 = yes, 2 = always and 3 = reserverd>, [<directorie>, ...], [[<files>, <x|r>], ...] ];
  [ '*00',     'Package ASNMTAP::Asnmtap', 'ASNMTAP::Asnmtap',                    { 'Config::General' => '2.30', 'Config::General::Interpolated' => '2.06', 'Data::Dumper' => '2.121','Dumpvalue' => '1.11', 'Getopt::Long' => '2.34', 'IO::CaptureOutput' => '1.03', 'Time::Local' => '1.11' }, 2, 
   [], [
    [ 'Asnmtap.cnf',                                                              'r' ],
   ]
  ],
  [ '*01',     'IO',                       'ASNMTAP::IO',                         { 'ASNMTAP::Asnmtap' => '*00', 'IO' => '1.21' }, 2, [], [] ],
  [ '*02',     'Time',                     'ASNMTAP::Time',                       { 'ASNMTAP::Asnmtap' => '*00', 'Time::Local' => '1.11' }, 2, [], [] ],
  [ '*0010',   'Subclass Applications',    'ASNMTAP::Asnmtap::Applications',      { 'ASNMTAP::Asnmtap' => '*00' }, 3, [], [] ],
  [ '*001000', 'Subclass CGI Interface',   'ASNMTAP::Asnmtap::Applications::CGI', { 'ASNMTAP::Asnmtap::Applications' => '*0010' }, 3, [], [] ],
  [ '*0011',   'Subclass Plugins',         'ASNMTAP::Asnmtap::Plugins',           { 'ASNMTAP::Asnmtap' => '*00', 'Time::HiRes' => '1.81' }, 2,
   [
    'plugins',
    'plugins/templates',
    'plugins/templates/dtd',
    'plugins/templates/ssl',
    'plugins/templates/ssl/crt',
    'plugins/templates/ssl/key',
    'plugins/templates/xml',
    'plugins/tools',
    'plugins/tmp'
   ], [
    [ 'plugins/templates/check_dummy.pl',                                         'x' ],
    [ 'plugins/templates/check_MySQL-database.pl',                                'x' ],
    [ 'plugins/templates/check_template.pl',                                      'x' ],
    [ 'plugins/templates/check_template-mail.pl',                                 'x' ],
    [ 'plugins/templates/check_template-mail-fingerprint-xml.pl',                 'x' ],
    [ 'plugins/templates/check_template-mail-xml-fingerprint-xml.pl',             'x' ],
    [ 'plugins/templates/check_template-mail-xml.pl',                             'x' ],
    [ 'plugins/templates/check_template-modem.pl',                                'x' ],
    [ 'plugins/templates/check_template-ras.pl',                                  'x' ],
    [ 'plugins/templates/check_template-SOAP.pl',                                 'x' ],
    [ 'plugins/templates/check_template-WebTransact.pl',                          'x' ],
    [ 'plugins/templates/check_template-WebTransact-Perfdata.pl',                 'x' ],
    [ 'plugins/templates/check_template-WebTransact-with-client-certificate.pl',  'x' ],
    [ 'plugins/templates/check_template-WebTransact-XML.pl',                      'x' ],
    [ 'plugins/templates/check_template-WebTransact-XML-Cactus-parser.pl',        'x' ],
    [ 'plugins/templates/check_template-XML.pl',                                  'x' ],

    [ 'plugins/templates/dtd/email-upgrade-1.0.dtd',                              'r' ],
    [ 'plugins/templates/dtd/FingerprintEmail-1.0.dtd',                           'r' ],
    [ 'plugins/templates/dtd/Monitoring-1.0.dtd',                                 'r' ],

    [ 'plugins/templates/xml/email-upgrade-1.0.xml',                              'r' ],
    [ 'plugins/templates/xml/FingerprintEmail-1.0.xml',                           'r' ],
    [ 'plugins/templates/xml/Monitoring-1.0.xml',                                 'r' ],
    [ 'plugins/templates/xml/ServletTestRunner-FailureError.xml',                 'r' ],
    [ 'plugins/templates/xml/ServletTestRunner.xml',                              'r' ],

    [ 'plugins/templates/ssl/crt/alex-peeters.crt',                               'r' ],
    [ 'plugins/templates/ssl/crt/server-ca.crt',                                  'r' ],

    [ 'plugins/templates/ssl/key/alex-peeters-nopass.key',                        'r' ],
    [ 'plugins/templates/ssl/key/alex-peeters.key',                               'r' ],
    [ 'plugins/templates/ssl/key/server-ca.key',                                  'r' ],
	  
    [ 'plugins/tools/GrinderCaptureConverter.pl',                                 'x' ]
   ]
  ],
  [ '*001100', 'Subclass Nagios', 'ASNMTAP::Asnmtap::Plugins::Nagios', { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'Time::Local' => '1.11' }, 1,
   [
    'plugins/nagios',
    'plugins/nagios/templates',
    'plugins/nagios/templates/dtd',
    'plugins/nagios/templates/xml'
   ], [
    [ 'plugins/nagios/templates/check_template-ftp.pl',                           'x' ],
    [ 'plugins/nagios/templates/check_template-ldap.pl',                          'x' ],
    [ 'plugins/nagios/templates/check_template-nagios.pl',                        'x' ],
    [ 'plugins/nagios/templates/check_xml.pl',                                    'x' ],
    [ 'plugins/nagios/templates/check_xml-monitoring.pl',                         'x' ],

    [ 'plugins/nagios/templates/dtd/nagios-1.0.dtd',                              'r' ],
    [ 'plugins/nagios/templates/dtd/Monitoring-1.0.dtd',                          'r' ],

    [ 'plugins/nagios/templates/xml/Monitoring-1.0.xml',                          'r' ],
    [ 'plugins/nagios/templates/xml/nagios-1.0.xml',                              'r' ],
    [ 'plugins/nagios/templates/xml/nagios-1.0.xml-doctype',                      'r' ],
    [ 'plugins/nagios/templates/xml/nagios-1.0.xml-dtd',                          'r' ]
   ]
  ],
  [ '*001101', 'Mail support',        'ASNMTAP::Asnmtap::Plugins::Mail',        { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'Date::Calc' => '5.4', 'Mail::Sendmail' => '0.79', 'MIME::Base64' => '3.07', 'Net::POP3' => '2.28' }, 3, [], [] ],
  [ '*001102', 'Modem support',       'ASNMTAP::Asnmtap::Plugins::Modem',       { 'ASNMTAP::Asnmtap::Plugins' => '*0011' }, 3, [], [] ],
  [ '*001103', 'SOAP support',        'ASNMTAP::Asnmtap::Plugins::SOAP',        { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'SOAP::Lite' => '0.656' }, 1, [], [] ],
  [ '*001104', 'WebTransact support', 'ASNMTAP::Asnmtap::Plugins::WebTransact', { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'Bundle::LWP' => '1.11', 'CGI' => '3.15', 'URI' => '1.35' }, 1, [], [] ],
  [ '*001105', 'XML support',         'ASNMTAP::Asnmtap::Plugins::XML',         { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'XML::LibXML' => '1.58', 'XML::Simple' => '2.14' }, 2, [], [] ],
  [ '*001199', 'Testing Templates',   'ASNMTAP::Asnmtap::Plugins::NPTest',      { 'ASNMTAP::Asnmtap::Plugins' => '*0011', 'Cwd' => '3.05', 'Data::Dumper' => '2.121', 'File::Basename' => '2.73', 'IO' => '1.21' }, 1, [], [] ]
);

# End Configuration - You should not have to change anything below this line

my %has_module_cache = ();

# Allow us to suppress all program installation with the -n (library only) option.
# This is for those that don't want to mess with the configuration section of this file.
use Getopt::Std;
use vars qw ( $opt_n );
unless ( getopts ('n') ) { die "Usage: $0 [-n]\n"; }
my $prompt = ( $opt_n || grep /^LIB=/, @ARGV ) ? 0 : 1;

unlink ('t/APPLICATIONS_ENABLED')        if ( -e 't/APPLICATIONS_ENABLED' );
unlink ('t/APPLICATIONS_CGI_ENABLED')    if ( -e 't/APPLICATIONS_CGI_ENABLED' );

unlink ('t/PLUGINS_ENABLED')             if ( -e 't/PLUGINS_ENABLED' );
unlink ('t/PLUGINS_NPTEST_ENABLED')      if ( -e 't/PLUGINS_NPTEST_ENABLED' );
unlink ('t/PLUGINS_MAIL_ENABLED')        if ( -e 't/PLUGINS_MAIL_ENABLED' );
unlink ('t/PLUGINS_MODEM_ENABLED')       if ( -e 't/PLUGINS_MODEM_ENABLED' );
unlink ('t/PLUGINS_NAGIOS_ENABLED')      if ( -e 't/PLUGINS_NAGIOS_ENABLED' );
unlink ('t/PLUGINS_SOAP_ENABLED')        if ( -e 't/PLUGINS_SOAP_ENABLED' );
unlink ('t/PLUGINS_WEBTRANSACT_ENABLED') if ( -e 't/PLUGINS_WEBTRANSACT_ENABLED' );
unlink ('t/PLUGINS_XML_ENABLED')         if ( -e 't/PLUGINS_XML_ENABLED' );

if ( $prompt ) {
  print <<EOT;

Note that you can avoid these questions by passing the '-n' option 
to 'Makefile.PL'.

The DEFAULT AUTO for automatic installation of dependencies via CPAN is '$PERL_AUTOINSTALL'.

The Applications are installed when the value equals 1.
The DEFAULT APPLICATIONS for the the plugin templates is '$ASNMTAP_APPLICATIONS'.

The Plugin templates are installed when the value equals 1.
The DEFAULT PLUGINS for the the plugin templates is '$ASNMTAP_PLUGINS'.

The DEFAULT PATH for the applications and/or plugins is '$ASNMTAP_PATH'.

The DEFAULT UID for the applications and plugins is '$ASNMTAP_UID'.

The DEFAULT GID for the applications and plugins is '$ASNMTAP_GID'.

The DEFAULT PROXY for testing the plugins is '$ASNMTAP_PROXY'.

With the environment variables PERL_AUTOINSTALL, ASNMTAP_APPLICATIONS,
ASNMTAP_PLUGINS, ASNMTAP_PATH, ASNMTAP_UID, ASNMTAP_GID and ASNMTAP_PROXY
you can change this.

EOT

  $PERL_AUTOINSTALL = ( ExtUtils::MakeMaker::prompt( "\nAutomatic installation of dependencies via CPAN?" => ( $PERL_AUTOINSTALL ? 'yes' : 'no' ) ) =~ /^\s*(y)/i );
  $ENV{PERL_AUTOINSTALL} = $PERL_AUTOINSTALL;

# $ASNMTAP_APPLICATIONS = ( ExtUtils::MakeMaker::prompt( "\nDo you want to install the Applications?" => ( $ASNMTAP_APPLICATIONS ? 'yes' : 'no' ) ) =~ /^\s*(y)/i );
  $ASNMTAP_PLUGINS = ( ExtUtils::MakeMaker::prompt( "\nDo you want to install the Plugin templates?" => ( $ASNMTAP_PLUGINS ? 'yes' : 'no' ) ) =~ /^\s*(y)/i );

  if ( $ASNMTAP_APPLICATIONS or $ASNMTAP_PLUGINS ) {
    $ASNMTAP_UID = prompt ("\nThe wanted UID for the applications and/or plugins?", $ASNMTAP_UID);
    $ASNMTAP_GID = prompt ("\nThe wanted GID for the applications and/or plugins?", $ASNMTAP_GID);

    do {
      $ASNMTAP_PATH = prompt ("\nWhere do want to install the applications and/or plugins?", $ASNMTAP_PATH);
      unless ( -d $ASNMTAP_PATH ) { mkdir $ASNMTAP_PATH or print "- invalid directory: '$ASNMTAP_PATH'\n" };
    } while ( ! -d $ASNMTAP_PATH );
  }

} else {
  if ( $ASNMTAP_APPLICATIONS or $ASNMTAP_PLUGINS ) {
    print "\nCreate directory: '$ASNMTAP_PATH':\n";
    unless ( -d $ASNMTAP_PATH ) { mkdir $ASNMTAP_PATH or die "- invalid directory '$ASNMTAP_PATH'\n"; }
  }
}

print "- created (when not already exists): '$ASNMTAP_PATH'\n\n";
chown ( $ASNMTAP_UID, $ASNMTAP_GID, $ASNMTAP_PATH ) or die "- chown $ASNMTAP_UID:$ASNMTAP_GID $ASNMTAP_PATH failed: $!";

my $intro = <<EOI;
This Build comes with some package that I can install.

We are about to install ASNMTAP::Asnmtap and for your convenience will
provide you with list of modules and prerequisites,  so you'll be able
to choose only modules you need for your configuration.

EOI

if ( $prompt ) {
  ExtUtils::MakeMaker::prompt( $intro . "Press <enter> to see the detailed list." );
} else {
  print "These are the modules that will get installed:\n\n";
}

# This hash will contain a list of all perl modules we would like to explicitly depend upon in our Makefile
my %PREREQ_PM;

# Maintains a cache of what 3rd party modules you have installed
sub has_module {
  my ($module, $version) = @_;

  $version ||= '';
  return ( ( $version =~ /^\*\d{2,2}(?:\d{2,2}(?:\d{2,2})?)?$/ ) ? 2 : ( $has_module_cache { "$module$version" } ||= eval ( "require $module; Exporter::require_version ( '$module', $version ) if ( $version ); 1" ) ) );
}

# Print a single prerequisite to the screen
sub generate_PREREQ_PM {
  my ($feature, $dependency, $modules, $install) = @_;
  my $buffer;
  my $i = 0;

  foreach (keys %$modules) {
    my $detected = has_module ( $_, $modules->{$_} );

    $buffer .= sprintf ( "%-24s [%s] %-32s %-8s\n", ( $i++ ? '' : $feature), ($detected >= 2 ? '+' : ( $detected ? '*' : ' ') ), $_ . ( $modules->{ $_ } and $modules->{ $_ } !~ /^\*\d{2,2}(?:\d{2,2}(?:\d{2,2})?)?$/ ? " (v$modules->{$_})" : '' ), ( $i == 1 ? ( $install ? ( $install == 3 ? 'reserved' : ($install == 2 ? 'always' : '[ yes ]') ) : '[ no ]') : '' ) );
  }

  return $buffer;
}

# Print the entire prerequisites table
sub generate_PREREQ_PM_table {
  my $buffer = sprintf ( "%-24s %-36s %-8s\n", 'Feature', 'Prerequisites', 'Install?' );
  $buffer   .= sprintf ( "%s %s %s\n","-" x 24,"-" x 36,"-" x 8 );
  foreach my $prerequisites ( @prerequisites ) { $buffer .= generate_PREREQ_PM ( @$prerequisites[1..4] ); }
  $buffer   .= "\n<- An asterix [*] indicates if the module is currently installed.\n";
  return $buffer;
}

# Update the entire prerequisites table
sub update_prerequisites_table {
  my ($u_level, $u_default) = @_;

  return if ( $u_default > 2 );

  my ($action, $u1, $u2, $u3);
  ($u1, $u2, $u3) = $u_level =~ /^\*(\d{2,2})(?:(\d{2,2})(\d{2,2})?)?$/;

  if ( defined $u3 ) {
    return unless ( $u_default );  $action = 3;
  } elsif ( defined $u2 ) {
    return if ( $u_default );      $action = 2;
  } elsif ( defined $u1 ) {
    return unless ( $u1 eq '00' ); $action = 1;
  } else {
    return;                        $action = 0;
  }

  foreach my $prerequisite ( @prerequisites ) {
    my ($level, $default) = ( @{$prerequisite}[0], @{$prerequisite}[4] );
    if ( $action == 1 and $u_level eq $level ) { @{$prerequisite}[4] = 2; last; }
    next if ( $default >= 2 );

    if ( $u_level ne $level ) {
      if ( $u_default ) {
        next unless ( $action == 3 and length($u_level) == 7 and length($level) == 5 and $u_level =~ /^$level/ );
      } else {
        next unless ( $action == 2 and length($u_level) == 5 and length($level) == 7 and $level =~ /^$u_level/ );
      }
    }

    @{$prerequisite}[4] = $u_default;
  }
}

# Initialize the entire prerequisites table
foreach my $prerequisites ( @prerequisites ) { update_prerequisites_table( @$prerequisites[0], @$prerequisites[4] ); }

my $proceed = 0;

do {
  print "\n". generate_PREREQ_PM_table() ."\n";
  $proceed = ( $prompt ? ExtUtils::MakeMaker::prompt( "Do you want to proceed with this configuration?" => 'yes' ) =~ /^\s*y/i : 1 );
  print "\nActivate test:\n" if ($proceed);
  %PREREQ_PM = ();

  foreach my $prerequisite ( @prerequisites ) {
    my ($level, $feature, $dependency, $modules, $default) = @{$prerequisite}[0..4];
    next unless ( $dependency ne '' );

    unless ( $proceed || $default >= 2 ) {
      $default = ( ( ExtUtils::MakeMaker::prompt( "Do you plan to use ${feature}?" => ( $default ? 'yes' : 'no' ) ) =~ /^\s*(y)/i ) ? 1 : 0 );
      @{$prerequisite}[4] = $default;
    }

    update_prerequisites_table( $level, $default );

    if ( $proceed and ( $default == 1 || $default == 2 ) ) {
      if ( $dependency =~ /^ASNMTAP::Asnmtap::/ ) {
        my $t = uc($');
        $t =~ s/::/_/g;
        my $enabled = 't/'. $t .'_ENABLED';
        open (ENABLED, ">$enabled") or die "- activate test '$enabled' failed: $!\n";
        close (ENABLED);
        print "- activated test: '$enabled'\n";
      }

      foreach ( keys %$modules ) {
        my $version = $modules->{$_};
        next if ( $version =~ /^\*\d{2,2}(?:\d{2,2}(?:\d{2,2})?)?$/ );
        $PREREQ_PM{$_} = $version unless ( defined $PREREQ_PM{$_} and $PREREQ_PM{$_} >= $version );
      }
    }
  }
} while (! $proceed);

print "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ( $ASNMTAP_PLUGINS ) {
  require File::Copy;

  foreach my $prerequisite ( @prerequisites ) {
    my ($feature, $default, $directories, $files) = ( @{$prerequisite}[1], @{$prerequisite}[4..6] );

    if ( $default == 1 || $default == 2 ) {
      if ( defined $directories ) {
        print "\nCreate directories for '$feature':\n";
 
        foreach ( @$directories ) {
          my $directory = "$ASNMTAP_PATH/$_";

          unless ( -d $directory ) { 
            mkdir $directory or die "- invalid directory: '$directory'";
            chown ( $ASNMTAP_UID, $ASNMTAP_GID, $directory ) or die "- chown $ASNMTAP_UID:$ASNMTAP_GID $directory failed: $!";
          };

          print "- created (when not already exists): '$_'\n";
        }
      }

      if ( defined $files ) {
        print "\nCopy files for '$feature':\n";

        foreach ( @$files ) {
          my $file = @$_[0];
          my $mode = @$_[1];
          my $destination = $ASNMTAP_PATH .'/'. $file;
          File::Copy::copy ( $file, $destination ) or die "- copy '$file' failed: $!";
          chmod ( ( $mode eq 'x' ? 0750 : 0640 ), $destination) or die "- chmod $destination $file failed: $!";
          print "- copied file '$destination'\n";
        }
      }
    }
  }

  print "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ( $PERL_AUTOINSTALL ) {
  my ($module, $version, $installed);
  $module    = 'Module::AutoInstall';
  $version   = '1.01';
  $installed = eval ( "require $module; Exporter::require_version ( '$module', $version );" );
 
  if ( $installed ) {
    print "\nAutomatic install of dependencies via CPAN\n";

    eval ( "
       use Module::AutoInstall ( -config => { force => 1, do_once => 1 } ); 
       Module::AutoInstall->install( [], %PREREQ_PM );
    " );

    print "\n";
  } else {
    print "\n$module required for automatic install of dependencies via CPAN\n";
    print "\nperl -MCPAN -e 'install $module'\n\n";
  }
}

# Ok, now it is time to really generate the Makefile  - - - - - - - - - -

my @man3pods = qw (
  Asnmtap
  IO
  Time
  Asnmtap/Plugins
  Asnmtap/Plugins/Mail
  Asnmtap/Plugins/Modem
  Asnmtap/Plugins/Nagios
  Asnmtap/Plugins/SOAP
  Asnmtap/Plugins/WebTransact
  Asnmtap/Plugins/XML
);

# Asnmtap/Applications
# Asnmtap/Applications/CGI
# Asnmtap/Applications/Collector
# Asnmtap/Applications/Display

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

WriteMakefile(
  NAME              => 'ASNMTAP',
  AUTHOR            => "alex.peeters\@citap.be",
  ABSTRACT          => "Application System and Network Monitoring Tool Alex Peeters",
  VERSION           => $VERSION,
  PREREQ_PM         => \%PREREQ_PM,
  MAN3PODS          => { map { my $man3pod = $_; $man3pod =~ s/\//::/g; ("lib/ASNMTAP/$_.pod" => "\$(INST_MAN3DIR)/ASNMTAP::$man3pod.\$(MAN3EXT)") } @man3pods },
  ($] >= 5.005 ?
    (ABSTRACT       => 'Description ...',
     AUTHOR         => 'Alex Peeters <alex.peeters@citap.com>') : ()
    ),
  'dist'            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

package MY;

# What happens when we say 'make test'  - - - - - - - - - - - - - - - - -

sub test {
  q(
TEST_VERBOSE=0

test: all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)
  );
}

# Determine things that should *not* be installed - - - - - - - - - - - -

sub libscan {
  my ($self, $path) = @_;

  return '' if $path =~ m:\blib/ASNMTAP/Asnmtap/Applications:;
  return '' if $path =~ m:\betc/:;
  return '' if $path =~ m:\busr/:;
  return '' if $path =~ m:\bCVS/:;
  $path;
}

# Pass ASNMTAP version number to pod2man  - - - - - - - - - - - - - - - -

sub manifypods {
  my $self = shift;

  my $version = $self->{VERSION} || $VERSION;
  local ($_) = $self->SUPER::manifypods(@_);
  s/pod2man\s*$/pod2man --release ASNMTAP-$version/m;
  $_;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
