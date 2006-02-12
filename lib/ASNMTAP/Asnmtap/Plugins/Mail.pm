# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/02/08, v3.000.004, package ASNMTAP::Asnmtap::Plugins::Mail Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

# Class name  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package ASNMTAP::Asnmtap::Plugins::Mail;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(carp cluck);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

no warnings 'deprecated';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(:ASNMTAP :_HIDDEN);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::Mail::ISA         = qw(Exporter);

  %ASNMTAP::Asnmtap::Plugins::Mail::EXPORT_TAGS = ( ALL => [ qw() ] );

  @ASNMTAP::Asnmtap::Plugins::Mail::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::Mail::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::Mail::VERSION     = 3.000.004;
}

# Constructor & initialisation  - - - - - - - - - - - - - - - - - - - - -

sub new (@) {
  my $classname = shift;

  if (! defined $classname) { my @c = caller; die "Syntax error: Class name expected after new at $c[1] line $c[2]\n" }
  if (  ref     $classname) { my @c = caller; die "Syntax error: Can't construct new ".ref($classname)." from another object at $c[1] line $c[2]\n" }

  use fields;

  my $self = fields::phash ( _asnmtapInherited   => undef,
                             _SMTP               => 
                               { 
                                 smtp            => 'localhost',
                                 port            => 25,
                                 retries         => 3,
                                 delay           => 1,
                                 mime            => 0,
                                 tz              => undef,
                                 debug           => 0
							   },
                             _POP3               =>
                               {
                                 pop3            => undef,
                                 port            => 110,
                                 username        => undef,
                                 password        => undef,
                                 timeout         => 120,
                                 debug           => 0
                               },
                             _mailType           => 0,
                             _text               => 
                               {
                                 SUBJECT         => 'ASNMTAP',
                                 from            => 'From:',
                                 to              => 'To:',
                                 subject         => 'Subject:',
                                 status          => 'Status'
                               },
                             _mail               => 
                               {
                                 from            => undef,
                                 to              => undef,
                                 status          => undef,
                                 body            => undef
                               }
                             );

  my %args = @_;

  $self->{_asnmtapInherited}        = $args{_asnmtapInherited}      if ( exists $args{_asnmtapInherited} );

  if ( exists $args{_SMTP} ) {
    $self->{_SMTP}->{smtp}          = $args{_SMTP}->{smtp}          if ( exists $args{_SMTP}->{smtp} );
    $self->{_SMTP}->{port}          = $args{_SMTP}->{port}          if ( exists $args{_SMTP}->{port} );
    $self->{_SMTP}->{retries}       = $args{_SMTP}->{retries}       if ( exists $args{_SMTP}->{retries} );
    $self->{_SMTP}->{delay}         = $args{_SMTP}->{delay}         if ( exists $args{_SMTP}->{delay} );
    $self->{_SMTP}->{mime}          = $args{_SMTP}->{mime}          if ( exists $args{_SMTP}->{mime} );
    $self->{_SMTP}->{tz}            = $args{_SMTP}->{tz}            if ( exists $args{_SMTP}->{tz} );
    $self->{_SMTP}->{debug}         = $args{_SMTP}->{debug}         if ( exists $args{_SMTP}->{debug} );
  }

  if ( exists $args{_POP3} ) {
    $self->{_POP3}->{pop3}          = $args{_POP3}->{pop3}          if ( exists $args{_POP3}->{pop3} );
    $self->{_POP3}->{port}          = $args{_POP3}->{port}          if ( exists $args{_POP3}->{port} );
    $self->{_POP3}->{username}      = $args{_POP3}->{username}      if ( exists $args{_POP3}->{username} );
    $self->{_POP3}->{password}      = $args{_POP3}->{password}      if ( exists $args{_POP3}->{password} );
    $self->{_POP3}->{timeout}       = $args{_POP3}->{timeout}       if ( exists $args{_POP3}->{timeout} );
    $self->{_POP3}->{debug}         = $args{_POP3}->{debug}         if ( exists $args{_POP3}->{debug} );
  }

  $self->{_mailType}                = $args{_mailType}              if ( exists $args{_mailType} );

  if ( exists $args{_text} ) {
    $self->{_text}->{SUBJECT}       = $args{_text}->{SUBJECT}       if ( exists $args{_text}->{SUBJECT} );
    $self->{_text}->{from}          = $args{_text}->{from}          if ( exists $args{_text}->{from} );
    $self->{_text}->{to}            = $args{_text}->{to}            if ( exists $args{_text}->{to} );
    $self->{_text}->{subject}       = $args{_text}->{subject}       if ( exists $args{_text}->{subject} );
    $self->{_text}->{status}        = $args{_text}->{status}        if ( exists $args{_text}->{status} );
  }

  if ( exists $args{_mail} ) {
    $self->{_mail}->{from}          = $args{_mail}->{from}          if ( exists $args{_mail}->{from} );
    $self->{_mail}->{to}            = $args{_mail}->{to}            if ( exists $args{_mail}->{to} );
    $self->{_mail}->{status}        = $args{_mail}->{status}        if ( exists $args{_mail}->{status} );
    $self->{_mail}->{body}          = $args{_mail}->{body}          if ( exists $args{_mail}->{body} );
  }

  bless ($self, $classname);
  $self->_init();
  return ($self);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _init {
  my $asnmtapInherited = $_[0]->{_asnmtapInherited};
  unless ( defined $asnmtapInherited ) { cluck ( 'ASNMTAP::Asnmtap::Plugins::Mail: asnmtapInherited missing' ); exit $ERRORS{UNKNOWN} }

  carp ('ASNMTAP::Asnmtap::Pluginw::MAIL: _init') if ( $$asnmtapInherited->{_debug} );

  unless ( defined $$asnmtapInherited->{_programName} and $$asnmtapInherited->{_programName} ne 'NOT DEFINED' ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing parent object attribute mName' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $$asnmtapInherited->{_programDescription} and $$asnmtapInherited->{_programDescription} ne 'NOT DEFINED' ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing parent object attribute mDescription' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $$asnmtapInherited->getOptionsArgv('environment') ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing parent object command line option -e|--environment' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  $_[0]->[ $_[0]->[0]{_environment_} = @{$_[0]} ] = 'LOCAL';

  for ( $$asnmtapInherited->getOptionsArgv('environment') ) {
    /P/ && do { $_[0]->{_environment_} = "PROD";  last; };
    /S/ && do { $_[0]->{_environment_} = "SIM";   last; };
    /A/ && do { $_[0]->{_environment_} = "ACC";   last; };
    /T/ && do { $_[0]->{_environment_} = "TEST";  last; };
    /D/ && do { $_[0]->{_environment_} = "DEV";   last; };
    /L/ && do { $_[0]->{_environment_} = "LOCAL"; last; };
  }

  if ( $$asnmtapInherited->getOptionsValue('debug') ) {
    $_[0]->{_SMTP}->{debug} = $$asnmtapInherited->getOptionsValue('debug') if ( $_[0]->{_SMTP}->{debug} < $$asnmtapInherited->getOptionsValue('debug') );
    $_[0]->{_POP3}->{debug} = $$asnmtapInherited->getOptionsValue('debug') if ( $_[0]->{_POP3}->{debug} < $$asnmtapInherited->getOptionsValue('debug') );
  }

  $_[0]->{_POP3}->{timeout} = $$asnmtapInherited->timeout() if ( $_[0]->{_POP3}->{timeout} == 120 );

  unless ($_[0]->{_mailType} =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Parameter _mailType must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $_[0]->{_mail}->{from} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL parameter _mail => {from => ...}' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $_[0]->{_mail}->{to} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL parameter _mail => {to => ...}' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $_[0]->{_mail}->{status} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL parameter _mail => {status => ...}' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $_[0]->{_mail}->{body} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL parameter _mail => {body => ...}' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  $_[0]->[ $_[0]->[0]{_subject_} = @{$_[0]} ] = $_[0]->{_text}->{SUBJECT} .' / '. $_[0]->{_text}->{from} .' '. $_[0]->{_mail}->{from} .' '. $_[0]->{_text}->{to} .' '. $_[0]->{_mail}->{to};

  unless ( $_[0]->{_mailType} ) {
    $_[0]->[ $_[0]->[0]{_branding_}  = @{$_[0]} ] = '<'. $$asnmtapInherited->{_programName} .'> <'. $$asnmtapInherited->{_programDescription} .'>';
    $_[0]->[ $_[0]->[0]{_timestamp_} = @{$_[0]} ] = 'Timestamp <'. $_[0]->{_mail}->{from} .'>:';
    $_[0]->[ $_[0]->[0]{_status_}    = @{$_[0]} ] = $_[0]->{_text}->{status} .' <'. $_[0]->{_mail}->{status} .'>';
  }

  if ( $$asnmtapInherited->{_debug} ) {
    use Data::Dumper;
    print "\n". ref ($_[0]) .": Now we'll dump data\n\n", Dumper ( $_[0] ), "\n\n";
  }
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub sending_fingerprint_mail {
  &_checkAccObjRef ( $_[0] ); &_checkReadOnly0;

  my $asnmtapInherited = $_[0]->{_asnmtapInherited};
  return ( $$asnmtapInherited->pluginValue ('stateValue') ) unless ( exists $_[0]->{_subject_} );

  use Mail::Sendmail qw(sendmail %mailcfg);
  $mailcfg {smtp}    = $_[0]->{_SMTP}->{smtp};
  $mailcfg {port}    = $_[0]->{_SMTP}->{port};
  $mailcfg {retries} = $_[0]->{_SMTP}->{retries};
  $mailcfg {delay}   = $_[0]->{_SMTP}->{delay};
  $mailcfg {mime}    = $_[0]->{_SMTP}->{mime};
  $mailcfg {tz}      = $_[0]->{_SMTP}->{tx} if ( defined $_[0]->{_SMTP}->{tx} );
  $mailcfg {debug}   = $$asnmtapInherited->getOptionsValue ('debug');

  my $message;

  if ( $_[0]->{_mailType} ) {
    use Time::Local;
    my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin, $currentSec) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1,0]);
    my $mailEpochtime = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);
    $message = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE FingerprintEmail SYSTEM \"dtd/FingerprintEmail-1.0.dtd\"><FingerprintEmail><Schema Value=\"1.0\"/><Fingerprint From=\"". $_[0]->{_mail}->{from} ."\" To=\"". $_[0]->{_mail}->{to} ."\" Destination=\"ASNMTAP\" Plugin=\"". $$asnmtapInherited->{_programName} ."\" Description=\"". $$asnmtapInherited->{_programDescription} ."\" Environment=\"". $_[0]->{_environment_} ."\" Date=\"$currentYear/$currentMonth/$currentDay\" Time=\"$currentHour:$currentMin:$currentSec\" Epochtime=\"$mailEpochtime\" Status=\"". $_[0]->{_mail}->{status} ."\" /></FingerprintEmail>\n";
  } else {
    use ASNMTAP::Time qw(&get_datetimeSignal);
    $message = $_[0]->{_subject_} ."\n". $_[0]->{_branding_} ."\n". $_[0]->{_timestamp_} ." ". get_datetimeSignal() ."\n". $_[0]->{_status_} ."\n";
  }

  $message .= $_[0]->{_mail}->{body} ."\n";
  my %mail = ( To => $_[0]->{_mail}->{to}, From => $_[0]->{_mail}->{from}, Subject => $_[0]->{_subject_}, Message => $message );

  my $returnCode = (sendmail %mail) ? $ERRORS{OK} : $ERRORS{CRITICAL};

  unless ( $returnCode ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'email sended' }, $TYPE{APPEND} );
  } else {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'sending mail failed' }, $TYPE{APPEND} );
  }

  print "\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log, "\n" if ( $$asnmtapInherited->getOptionsValue('debug') );
  return ( $returnCode );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub receiving_fingerprint_mails {
  my $self = shift; &_checkAccObjRef ( $self ); 

  my $asnmtapInherited = $self->{_asnmtapInherited};

  return ( $$asnmtapInherited->pluginValue ('stateValue') ) unless ( exists $self->{_subject_} );

  my %defaults = ( custom          => undef,
                   customArguments => undef,
                   numberOfLines   => 7,
                   receivedState   => 0,
                   outOfDate       => undef
                 );

  my %parms = (%defaults, @_);

  if ( $self->{_mailType} ) {
    unless ( defined $parms{outOfDate} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL receiving_fingerprint_mails parameter {outOfDate => ...}' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  }

  use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

  $self->[ $self->[0]{defaultArguments} = @{$self} ] = { date => undef, day => undef, month => undef, year => undef, time => undef, hour => undef, min => undef, sec => undef, numberOfMatches => undef, result => undef };

  if ( defined $self->{_POP3}->{pop3} ) {
    unless ( defined $self->{_POP3}->{username} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing Mail POP3 parameter username' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    unless ( defined $self->{_POP3}->{password} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing Mail POP3 parameter password' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
	
    use Net::POP3;
    my $pop3 = Net::POP3->new(Host => ( ref $self->{_POP3}->{pop3} eq 'ARRAY' ? $self->{_POP3}->{pop3} : $self->{_POP3}->{pop3} ), Port => $self->{_POP3}->{port}, Timeout => $self->{_POP3}->{timeout}, Debug => ($self->{_POP3}->{debug} >= 3) ? 1 : 0);

    my $servers = ref $self->{_POP3}->{pop3} eq 'ARRAY' ? "@{$self->{_POP3}->{pop3}}" : $self->{_POP3}->{pop3};

    unless( $pop3 ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Cannot connect to POP3 server(s): $servers" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    my $numberOfMails = $pop3->login( $self->{_POP3}->{username}, $self->{_POP3}->{password} );

    unless ( defined $numberOfMails ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Cannot login to POP3 server(s): $servers" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    my $returnCode = $ERRORS{DEPENDENT};

    if ( $numberOfMails ) {
      $self->{defaultArguments}->{numberOfMatches} = 0;

      use constant HEADER => '<?xml version="1.0" encoding="UTF-8"?>';
      use constant SYSTEM => 'dtd/FingerprintEmail-1.0.dtd';
      use constant FOOTER => '</FingerprintEmail>';
      my $fingerprintXML  = HEADER .'<!DOCTYPE FingerprintEmail SYSTEM "'. SYSTEM .'"><FingerprintEmail>';

      my $msgnums = $pop3->list;
      my $debug = $$asnmtapInherited->getOptionsValue('debug');

      foreach my $msgnum (keys %$msgnums) {
        print ref ($self), "::receiving_fingerprint_mails(): message number $msgnum\n" if ( $debug );

        my $msg = ( $parms{numberOfLines} ? $pop3->top($msgnum, $parms{numberOfLines}) : $pop3->top($msgnum) );

        my ($fromNotFound, $toNotFound, $subjectNotFound, $fingerprintFound) = (1, 1, 1, 3);

        my ($messageNotFound, $brandingNotFound, $timestampNotFound, $statusNotFound, $xmlNotFound) = (0, 0, 0, 0, 0);

        if ( $parms{numberOfLines} ) {
          $statusNotFound = 1;

          if ( $self->{_mailType} ) {
            ($xmlNotFound, $fingerprintFound) = (1, $fingerprintFound + 2);
          } else {
            ($messageNotFound, $brandingNotFound, $timestampNotFound, $fingerprintFound) = (1, 1, 1, $fingerprintFound + 4);
          }
        }

        $self->{defaultArguments}->{result} = '';

        my $msgline;
        my $msglineMerge = 0;

        my ($mimeVersion, $contentTypeTextPlainCharset, $contentTransferEncoding, $contentDisposition);

        foreach my $msgbuffer (@$msg) {
          chomp ($msgbuffer);
          if ($msgbuffer eq '') { next; }

          if ( ( $self->{_mailType} ? $xmlNotFound : $messageNotFound ) or ! $parms{numberOfLines} ) {
            if (!defined $mimeVersion and $msgbuffer =~ /^Mime-Version: (.+)$/i) {
              $mimeVersion = $1;
              print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $mimeVersion >\n" if ($debug);
              next;
            } elsif (!defined $contentTypeTextPlainCharset and $msgbuffer =~ /^Content-type: text\/plain; charset=(.+)$/i) {
              $contentTypeTextPlainCharset = $1;
              print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $contentTypeTextPlainCharset >\n" if ($debug);
              next;
            } elsif (!defined $contentTransferEncoding and $msgbuffer =~ /^Content-Transfer-Encoding: (.+)$/i) {
              $contentTransferEncoding = $1;
              print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $contentTransferEncoding >\n" if ($debug);
              next;
            } elsif (!defined $contentDisposition and $msgbuffer =~ /^Content-Disposition: (.+)$/i) {
              $contentDisposition = $1;
              print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $contentDisposition >\n" if ($debug);
              next;
            }
          }

          if ( defined $contentTransferEncoding ) {            # RFC 1521
            if ( $contentTransferEncoding =~ /(?:7bit|quoted-printable|base64|8bit|binary|x-token)/i ) {
              if ($msgbuffer =~ /=$/) {
                $msglineMerge = 1;
                chop($msgbuffer);
                $msgline = $msgbuffer;
                next;
    	      } elsif ($msglineMerge) {
                $msglineMerge = 0;
                $msgbuffer = $msgline . $msgbuffer;
              } 
            }
          }

          $msgline = $msgbuffer;

          if ( $fromNotFound ) {
            if ($msgline =~ /^$self->{_text}->{from}/) {
              print "From .... : $msgline\n" if ($debug);
              $fromNotFound = ( $msgline !~ /^$self->{_text}->{from}\s+$self->{_mail}->{from}$/ );
              my $label = $fromNotFound ? '    (?)' : '(match)';
              print "  $label : $self->{_text}->{from} $self->{_mail}->{from}\n" if ($debug);
              unless ( $fromNotFound ) { $fingerprintFound--; next; }
            }
          }

		  if ( $toNotFound ) {
            if ($msgline =~ /^$self->{_text}->{to}/) {
              print "To ...... : $msgline\n" if ($debug);
              $toNotFound = ( $msgline !~ /^$self->{_text}->{to}\s+$self->{_mail}->{to}$/ );
              my $label = $toNotFound ? '    (?)' : '(match)';
              print "  $label : $self->{_text}->{to} $self->{_mail}->{to}\n" if ($debug);
              unless ( $toNotFound ) { $fingerprintFound--; next; }
            }
          }

	  	  if ( $subjectNotFound ) {
            if ($msgline =~ /^$self->{_text}->{subject}/) {
              print "Subject . : $msgline\n" if ($debug);
              $subjectNotFound = ( $msgline !~ /^$self->{_text}->{subject}\s+$self->{_subject_}$/ );
              my $label = $subjectNotFound ? '    (?)' : '(match)';
              print "  $label : $self->{_text}->{subject} $self->{_subject_}\n" if ($debug);
              unless ( $subjectNotFound ) { $fingerprintFound--; next; }
		    }
          }

          if ( ( $self->{_mailType} ? $xmlNotFound : $fingerprintFound ) and $parms{numberOfLines} and ! ( $fromNotFound or $toNotFound or $subjectNotFound ) ) {
            if ( $self->{_mailType} ) {
              if ( $msgline =~ /\Q$fingerprintXML\E/ ) {
			    $xmlNotFound = 0; $fingerprintFound--;
  	 	        print "XML ..... : $msgline\n  (match) : $msgline\n" if ( $debug );
                my ( $returnCode, $xml ) = extract_XML ( asnmtapInherited => $self->{_asnmtapInherited}, resultXML => $msgline, headerXML => HEADER, footerXML => FOOTER, validateDTD => 0, filenameDTD => SYSTEM );

                unless ( $returnCode ) {
                  if ( $xml->{Fingerprint}{From} eq $self->{_mail}->{from} and $xml->{Fingerprint}{To} eq $self->{_mail}->{to} and $xml->{Fingerprint}{Destination} eq 'ASNMTAP' and $xml->{Fingerprint}{Plugin} eq $$asnmtapInherited->{_programName} and $xml->{Fingerprint}{Description} eq $$asnmtapInherited->{_programDescription} and $xml->{Fingerprint}{Environment} eq $self->{_environment_} ) {
                    use Date::Calc qw(check_date);

                    $self->{defaultArguments}->{date}  = 0;
                    $self->{defaultArguments}->{day}   = 0;
                    $self->{defaultArguments}->{month} = 0;
                    $self->{defaultArguments}->{year}  = 0;

                    $self->{defaultArguments}->{time}  = 0;
                    $self->{defaultArguments}->{hour}  = 0;
                    $self->{defaultArguments}->{min}   = 0;
                    $self->{defaultArguments}->{sec}   = 0;

                    my $currentTimeslot = timelocal ( (localtime)[0,1,2,3,4,5] );
                    my ($checkEpochtime, $checkDate, $checkTime) = ($xml->{Fingerprint}{Epochtime}, $xml->{Fingerprint}{Date}, $xml->{Fingerprint}{Time});
                    my ($checkYear, $checkMonth, $checkDay) = split (/\/|-/, $checkDate);
                    my ($checkHour, $checkMin, $checkSec) = split (/:/, $checkTime);
                    my $xmlEpochtime = timelocal ( $checkSec, $checkMin, $checkHour, $checkDay, ($checkMonth-1), ($checkYear-1900) );
                    print "$checkEpochtime, $xmlEpochtime ($checkDate, $checkTime), $currentTimeslot - $checkEpochtime = ". ($currentTimeslot - $checkEpochtime) ." > ". $parms{outOfDate} ."\n" if ( $debug );

                    if (! (check_date($checkYear, $checkMonth, $checkDay) or check_time($checkHour, $checkMin, $checkSec))) {
                      $returnCode = $ERRORS{CRITICAL};
                      $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => "Date or Time into Fingerprint XML are wrong: $checkDate $checkTime" }, $TYPE{APPEND} );
                    } elsif ( $checkEpochtime != $xmlEpochtime ) {
                      $returnCode = $ERRORS{CRITICAL};
                      $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => "Epochtime difference from Date and Time into Fingerprint XML are wrong: $checkEpochtime != $xmlEpochtime ($checkDate $checkTime)" }, $TYPE{APPEND} );
                    } elsif ( $currentTimeslot - $checkEpochtime > $parms{outOfDate} * 2 ) {
                      $returnCode = $ERRORS{CRITICAL};
                      $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => "Result into Fingerprint XML are out of date: $checkDate $checkTime" }, $TYPE{APPEND} );
                    } elsif ( $currentTimeslot - $checkEpochtime > $parms{outOfDate} ) {
                      $returnCode = $ERRORS{WARNING};
                      $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => "Result into Fingerprint XML are out of date: $checkDate $checkTime" }, $TYPE{APPEND} );
                    } else {
 				      ($self->{defaultArguments}->{date}, $self->{defaultArguments}->{time}) = ($checkDate, $checkTime);
                      ($self->{defaultArguments}->{day}, $self->{defaultArguments}->{month}, $self->{defaultArguments}->{year}) = split(/[\/|-]/, $checkDate);
                      ($self->{defaultArguments}->{hour}, $self->{defaultArguments}->{min}, $self->{defaultArguments}->{sec}) = split(/:/, $checkTime);
                    }

                    $statusNotFound = ( $xml->{Fingerprint}{Status} ne $self->{_mail}->{status} );
                    my $label = $statusNotFound ? '    (?)' : '(match)';
                    print "  $label : $self->{_text}->{status} < $self->{_mail}->{status} >\n" if ( $debug );
                    unless ( $statusNotFound ) { $fingerprintFound--; last; }
                  } else {
                    if ( $debug ) {
                      print "  (match) : From ". $xml->{Fingerprint}{From} ."\n" if ($xml->{Fingerprint}{From} eq $self->{_mail}->{from});
                      print "  (match) : To ". $xml->{Fingerprint}{To} ."\n" if ($xml->{Fingerprint}{To} eq $self->{_mail}->{to});
                      print "  (match) : Destination ". $xml->{Fingerprint}{Destination} ."\n" if ($xml->{Fingerprint}{Destination} eq 'ASNMTAP');
                      print "  (match) : Plugin ". $xml->{Fingerprint}{Plugin} ."\n" if ($xml->{Fingerprint}{Plugin} eq $$asnmtapInherited->{_programName});
                      print "  (match) : Description ". $xml->{Fingerprint}{Description} ."\n" if ($xml->{Fingerprint}{Description} eq $$asnmtapInherited->{_programDescription});
                      print "  (match) : Environment ". $xml->{Fingerprint}{Environment} ."\n" if ($xml->{Fingerprint}{Environment} =~ /^$self->{_environment_}/i);
                    }

                    last;
                  }
                }
          
			    next;
  		      }
            } else {
     		  if ( $messageNotFound ) {
                if ($msgline =~ /^$self->{_subject_}/) {
      	 	      print "Header .. : $msgline\n  (match) : $msgline\n" if ($debug);
    			  $messageNotFound = 0; $fingerprintFound--; next;
    		    }
              }

    		  if ( $brandingNotFound ) {
                if ( $msgline =~ /$$asnmtapInherited->{_programName}/ ) {
                  if ( $debug ) {
                    my $msglineDebug = $msgline; $msglineDebug =~ s/</< /g; $msglineDebug =~ s/>/ >/g;
      	            print "Branding  : $msglineDebug\n";
                  }

                  $brandingNotFound = ( $msgline !~ /^$self->{_branding_}$/ );
                  my $label = $brandingNotFound ? '    (?)' : '(match)';

                  if ( $debug ) {
                    my $msglineDebug = $msgline; $msglineDebug =~ s/</< /g; $msglineDebug =~ s/>/ >/g;
		            print "  $label : $msglineDebug\n";
                  }

                  unless ( $brandingNotFound ) { $fingerprintFound--; next; }
		        }
              }

	    	  if ( $timestampNotFound ) {
		        if ( $msgline =~ /^$self->{_timestamp_}/ ) {
                  (undef, $msgline) = split(/: /, $msgline, 2);
                  ($self->{defaultArguments}->{date}, $self->{defaultArguments}->{time}) = split(/ /, $msgline);
                  ($self->{defaultArguments}->{day}, $self->{defaultArguments}->{month}, $self->{defaultArguments}->{year}) = split(/[\/|-]/, $self->{defaultArguments}->{date});
                  ($self->{defaultArguments}->{hour}, $self->{defaultArguments}->{min}, $self->{defaultArguments}->{sec}) = split(/:/, $self->{defaultArguments}->{time});
                  print "Timestamp : $msgline  ". $self->{defaultArguments}->{date}. "  ". $self->{defaultArguments}->{time} ."\n  (match) : $msgline ". $self->{defaultArguments}->{day} .'/'. $self->{defaultArguments}->{month} .'"/'. $self->{defaultArguments}->{year} .'  '. $self->{defaultArguments}->{hour} .':'. $self->{defaultArguments}->{min} .':'. $self->{defaultArguments}->{sec} ."\n" if ( $debug );                  $timestampNotFound = 0; $fingerprintFound--; next;
                }
              }

	    	  if ( $fingerprintFound == 1 and $statusNotFound ) {
      		    if ( $msgline =~ /^$self->{_text}->{status}/ ) {
                  if ( $debug ) {
                    my $msglineDebug = $msgline; $msglineDebug =~ s/</< /g; $msglineDebug =~ s/>/ >/g;
                    print "Status .. : $msglineDebug\n";
                  }

                  $statusNotFound = ( $msgline !~ /^$self->{_text}->{status}\s*<$self->{_mail}->{status}>$/ );
                  my $label = $statusNotFound ? '    (?)' : '(match)';
                  print "  $label : $self->{_text}->{status} < $self->{_mail}->{status} >\n" if ($debug);
                  unless ( $statusNotFound ) { $fingerprintFound--; last; }
                }
              }
            }
          }

          unless ( $fingerprintFound ) {
            $self->{defaultArguments}->{result} .= "$msgline\n";
            print "- - - - - : $msgline\n" if ($debug);
            last;
          }

		  print ". . . . . : $msgline\n" if ($debug >= 2);
        }

        if ( $fingerprintFound == 0 ) {
          $self->{defaultArguments}->{result} = '';

          my $foundBody = 0;

          $msg = $pop3->get($msgnum);

          foreach my $msgline (@$msg) {
            if ( $foundBody ) {
              $self->{defaultArguments}->{result} .= $msgline;
            } else {
              $foundBody = ( $self->{_mailType} ? $msgline =~ /\Q$fingerprintXML\E/ : $msgline =~ /^$self->{_text}->{status}\s*<$self->{_mail}->{status}>$/ );
            }
          }

          if ( defined $contentTransferEncoding ) {              # RFC 1521
            if ($contentTransferEncoding =~ /7bit/i ) {
            } elsif ( $contentTransferEncoding =~ /quoted-printable/i ) {
              use MIME::QuotedPrint;
              $self->{defaultArguments}->{result} = decode_qp($self->{defaultArguments}->{result});
            } elsif ( $contentTransferEncoding =~ /base64/i ) {
              use MIME::Base64;
              $self->{defaultArguments}->{result} = decode_base64($self->{defaultArguments}->{result});
            } elsif ( $contentTransferEncoding =~ /8bit/i ) {
            } elsif ( $contentTransferEncoding =~ /binary/i ) {
            } elsif ( $contentTransferEncoding =~ /x-token/i ) {
            }
          } 

          if ( defined $parms{custom} ) {
            $returnCode = ( defined $parms{customArguments} ) ? $parms{custom}->($self, $self->{_asnmtapInherited}, $pop3, $msgnum, $parms{customArguments}) : $parms{custom}->($self, $self->{_asnmtapInherited}, $pop3, $msgnum);
          } else {
            $self->{defaultArguments}->{numberOfMatches}++;
            $pop3->delete( $msgnum ) if (! ( $debug or $$asnmtapInherited->getOptionsValue('onDemand') ) );
          }
        }

        $self->{defaultArguments}->{date}  = undef;
        $self->{defaultArguments}->{day}   = undef;
        $self->{defaultArguments}->{month} = undef;
        $self->{defaultArguments}->{year}  = undef;
        $self->{defaultArguments}->{time}  = undef;
        $self->{defaultArguments}->{hour}  = undef;
        $self->{defaultArguments}->{min}   = undef;
        $self->{defaultArguments}->{sec}   = undef;
      }
    }

    if ( defined $self->{defaultArguments}->{numberOfMatches} and $self->{defaultArguments}->{numberOfMatches} ) {
      $returnCode = $parms{receivedState} ? $ERRORS{CRITICAL} : $ERRORS{OK};
      $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => $self->{defaultArguments}->{numberOfMatches}. ' email(s) received' }, $TYPE{APPEND} );
    } else {
      $returnCode = $parms{receivedState} ? $ERRORS{OK} : $ERRORS{CRITICAL};
      $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => 'No emails received' }, $TYPE{APPEND} );
    }
	
    $pop3->quit;
    return ( $returnCode, $self->{defaultArguments}->{numberOfMatches} );
  } else {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'NO EMAIL CLIENT SPECIFIED !!!' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }
}

# Destructor  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DESTROY { print (ref ($_[0]), "::DESTROY: ()\n") if ( exists $$_[0]->{_asnmtapInherited} and $$_[0]->{_asnmtapInherited}->{_debug} ); }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Mail is a Perl module that provides Mail functions used by ASNMTAP-based plugins.

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Plugins

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
