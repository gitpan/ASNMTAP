# ----------------------------------------------------------------------------------------------------------
# � Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
#  2006/01/01, v3.000.004, making Asnmtap v3.000.xxx compatible
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap::Plugins::WebTransact;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI::Carp qw(fatalsToBrowser set_message cluck);

use HTTP::Request::Common qw(GET POST HEAD);
use HTTP::Cookies;

use LWP::Debug;
use LWP::UserAgent;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%ERRORS %TYPE &_dumpValue);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { $ASNMTAP::Asnmtap::Plugins::WebTransact::VERSION = 3.000.004; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use constant FALSE => 0;
use constant TRUE  => ! FALSE;

use constant Field_Refs	=> { 
                             Method	        => { is_ref => FALSE, type => ''      },
                             Url            => { is_ref => FALSE, type => ''      },
                             Qs_var	        => { is_ref => TRUE,  type => 'ARRAY' },
                             Qs_fixed	    => { is_ref => TRUE,  type => 'ARRAY' },
                             Exp            => { is_ref => FALSE, type => 'ARRAY' },
                             Exp_Fault	    => { is_ref => FALSE, type => ''      },
                             Exp_Return     => { is_ref => TRUE,  type => 'HASH'  },
                             Msg            => { is_ref => FALSE, type => ''      },
                             Msg_Fault	    => { is_ref => FALSE, type => ''      },
                             Perfdata_Label => { is_ref => FALSE, type => undef   }
                           };

my (%returns, %downloaded, $ua);
keys %downloaded = 128;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _handleHttpdErrors { print "<hr><h1>ASNMTAP::Asnmtap::Plugins::WebTransact It's not a bug, it's a feature!</h1><p>Error: $_[0]</p><hr>"; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

set_message ( \&_handleHttpdErrors );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _error_message { $_[0] =~ s/\n/ /g; $_[0]; }

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub new {
  my ($object, $asnmtapInherited, $urls_ar) = @_;

  # $urls_ar is a ref to a list of hashes (representing a request record) in a partic format.

  # If a hash is __not__ in that format it's much better to cluck since it is
  # hard to interpret 'not an array ref' messages (from check::_make_req) caused
  # by mis spelled or mistaken field names.

  &_dumpValue ( $asnmtapInherited, $object .': attribute asnmtapInherited is missing.' ) unless ( defined $asnmtapInherited );

  &_dumpValue ( $urls_ar, $object .': URL list is not an array reference.' ) if ( ref $urls_ar ne 'ARRAY' );
  my @urls = @$urls_ar;

  foreach my $url ( @urls ) {
    &_dumpValue ( $url, $object .': Request record is not a hash.' ) if ( ref $url ne 'HASH' );
    my @keys = keys %$url;

    foreach my $key ( @keys ) {
      if ( ! exists Field_Refs->{$key} ) {
        warn "Expected keys: ", join " ", keys %{ (Field_Refs) };
        &_dumpValue ( $url, $object .": Unexpected key \"$key\" in record." );
      }

      my $ref_type = '';

      if ( ($ref_type = ref $url->{$key}) && ( $ref_type ne Field_Refs->{$key}{type} ) ) {
        warn "Expected key \"$key\" to be ", Field_Refs->{$key}{type} ? Field_Refs->{$key}{type} .' ref' : 'non ref', "\n";
        &_dumpValue ( $url, $object .": Field \"$key\" has wrong reference type" );
      }

      if ( ! ref $url->{$key} and Field_Refs->{$key}{is_ref} ) {
        warn "Expected key \"$key\" to be ", Field_Refs->{$key}{type} ? Field_Refs->{$key}{type} .' ref' : 'non ref', "\n";
        &_dumpValue ( $url, $object .": Key \"$key\" not a  reference" );
      }
    }
  }

  my $classname = ref ($object) || $object;
  my $accessor_stash_slot = $classname .'::'. 'get_urls';
  no strict 'refs';

  unless ( ref *$accessor_stash_slot{CODE} eq 'CODE' ) {
    foreach my $accessor ( qw(urls matches returns) ) {
      my $full_name = $classname .'::'. $accessor;

      *{$full_name} = sub { my $self = shift @_;
                            $self->{$accessor} = shift @_ if @_;
                            $self->{$accessor};
                          };

      foreach my $acc_pre (qw(get set)) {
        $full_name = $classname .'::'. $acc_pre .'_'. $accessor;
        *{$full_name} = $acc_pre eq 'get' ? sub { my $self = shift @_; $self->{$accessor} } : sub { my $self = shift @_; $self->{$accessor} = shift @_ };
      }
    }
  }

  bless { asnmtapInherited => $asnmtapInherited, urls => $urls_ar, matches => [], returns => {}, number_of_images_downloaded => 0 }, $classname;

  # The field urls contains a ref to a list of (hashes) records representing the web transaction.

  # self->_my_match() will update $self->{matches};
  # with the set of matches it finds by matching patterns with memory (ie patterns in paren) from
  # the Exp field against the request response.
  # An array ref to the array containing the matches is stored in the field 'matches'.

  # Qs_var = [ form_name_1 => 0, form_name_2 => 1 ..] will lead to a query_string like
  # form_name_1 = $matches[0] form_name_2 = $matches[1] .. in $self->_make_req() by
  # @matches = $self->matches(); and using 0, 1 etc as indices of @matches.
  
  # XXX FIXME
  # Construct the useragent object and cache it so that the check method can reuse it for
  # multiple lists of URLs
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub check {
  my ($self, $cgi_parm_vals_hr) = @_;

  my %defaults = ( custom           => undef,
                   newAgent         => TRUE,
                   openAppend       => TRUE,
                   cookies          => TRUE,
                   download_images  => FALSE,
                   indent_level     => 0,
                   fail_if_1        => TRUE );

  my %parms = (%defaults, @_);

  my $debug         = ${$self->{asnmtapInherited}}->getOptionsValue ( 'debug' );
  my $debugfile     = ${$self->{asnmtapInherited}}->getOptionsArgv ( 'debugfile' );
  my $openAppend    = $parms{openAppend};

  my $proxyServer   = ${$self->{asnmtapInherited}}->proxy ( 'server' );
  my $proxyUsername = ${$self->{asnmtapInherited}}->proxy ( 'username' );
  my $proxyPassword = ${$self->{asnmtapInherited}}->proxy ( 'password' );

  if ( $parms{newAgent} or ! defined $ua ) {
    $ua = LWP::UserAgent->new ();
    $ua->agent ( ${$self->{asnmtapInherited}}->browseragent () );
    $ua->timeout ( ${$self->{asnmtapInherited}}->timeout () );

    $ua->default_headers->push_header ( 'Accept-Language' => 'no, en' );
    $ua->default_headers->push_header ( 'Accept-Charset'  => 'iso-8859-1,*,utf-8' );
    $ua->default_headers->push_header ( 'Accept-Encoding' => 'gzip, deflate' );

    $ua->cookie_jar ( HTTP::Cookies->new ) if ( $parms{cookies} );
	$ua->proxy ( ['http', 'ftp'] => $proxyServer ) if ( defined $proxyServer );
    LWP::Debug::level('+') if ( $debug );
  }

  my $returnCode = $parms{fail_if_1} ? $ERRORS{OK} : $ERRORS{CRITICAL};
  my $indent_level = $parms{indent_level};
  my ($resp_string, $res, $found);

  foreach my $url_r ( @{ $self->{urls} } ) {
    ${$self->{asnmtapInherited}}->setEndTime_and_getResponsTime ( ${$self->{asnmtapInherited}}->pluginValue ('endTime') );

    my $url = $url_r->{Url} ? $url_r->{Url} : &_next_url ($res, $resp_string);
    my $req = $self->_make_req( $url_r->{Method}, $url, $url_r->{Qs_var}, $url_r->{Qs_fixed}, $cgi_parm_vals_hr );
	$req->proxy_authorization_basic( $proxyUsername, $proxyPassword ) if ( defined $proxyServer && defined $proxyUsername && defined $proxyPassword );
    my $req_as_string = $req->as_string;
    print STDERR ref ($self), '   ' x $indent_level, ' --> ', $req_as_string, "\n" if ( $debug );
    $res = $ua->request($req);
    print STDERR ref ($self), '   ' x $indent_level, ' --> ', $res->as_string, "\n" if ( $debug >= 2 );

    my $responseTime = ${$self->{asnmtapInherited}}->setEndTime_and_getResponsTime ( ${$self->{asnmtapInherited}}->pluginValue ('endTime') );
    print ref ($self), ': Response time: ', $responseTime, " - $url\n" if ( $debug );
    ${$self->{asnmtapInherited}}->appendPerformanceData ( "'". $url_r->{Perfdata_Label} ."'=". $responseTime ."ms;;;;" ) if ( defined $url_r->{Perfdata_Label} );

    $self->_write_debugfile ( $req_as_string, $res->as_string, $debugfile, $openAppend ) if ( defined $debugfile );

    if ( $parms{fail_if_1} ) {
      unless ( $res->is_success or $res->is_redirect ) {
        $resp_string = $res->as_string;
        $resp_string =~ s#'#_#g;

        # Deal with __Can't__ from LWP.
        # Otherwise notification fails because /bin/sh is called to
        # printf '$OUTPUT' and sh cannot deal with nested quotes (eg Can't echo ''')
        $returnCode = $ERRORS{CRITICAL};
        my $knownError = 0;
        my $errorMessage = "other than HTTP 200";

        for ( $resp_string ) {
          # ***************************************************************************
          # The 500 series of Web error codes indicate an error with the Web server   *
          # ***************************************************************************

          # The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message.
          # It's a fault in the server and happens all too frequently.
          /500 Can_t connect to/     && do { $knownError = 1; $errorMessage = "500 Can't connect to ..."; $returnCode = $ERRORS{UNKNOWN}; last; };
          /500 Connect failed/       && do { $knownError = 1; $errorMessage = "500 Connect failed"; $returnCode = $ERRORS{UNKNOWN}; last; };
          /500 proxy connect failed/ && do { $knownError = 1; $errorMessage = "500 Proxy connect failed"; $returnCode = $ERRORS{UNKNOWN}; last; };
          /500 Server Error/         && do { $knownError = 1; $errorMessage = "500 Server Error"; $returnCode = $ERRORS{UNKNOWN}; last; };
          /500 SSL read timeout/     && do { $knownError = 1; $errorMessage = "500 SSL read timeout"; $returnCode = $ERRORS{UNKNOWN}; last; };

          /Internal Server Error/    && do { $knownError = 0; $errorMessage = "500 Internal Server Error"; $returnCode = $ERRORS{UNKNOWN}; last; };

          # Function not implemented in Web server software. The request needs functionality not available on the server
          /501 (?:No Server|Not Implemented)/ && do { $errorMessage = "501 Not Implemented"; last; };

          # Bad Gateway: a server being used by this Web server has sent an invalid response.
          # The response by an intermediary server was invalid. This may happen if there is a problem with the DNS routing tables.
          /502 (?:Bad Gateway|Server Overload)/ && do { $knownError = 1; $errorMessage = "502 Bad Gateway"; last; };

          # Service temporarily unavailable because of currently/temporary overload or maintenance.
          /503 (?:Out of Resources|Service Unavailable)/ && do { $knownError = 1; $errorMessage = "503 Service Unavailable"; last; };

          # The server did not respond back to the gateway within acceptable time period
          /504 Gateway Time-?Out/ && do { $knownError = 1; $errorMessage = "504 Gateway Timeout"; last; };

          # The server does not support the HTTP protocol version that was used in the request message.
          /505 HTTP Version [nN]ot supported/ && do { $knownError = 1; $errorMessage = "505 HTTP Version Not Supported"; last; };

          # ***************************************************************************
          # The 400 series of Web error codes indicate an error with your Web browser *
          # ***************************************************************************

          # The request could not be understood by the server due to incorrect syntax.
          /400 Bad Request/ && do { $knownError = 1; $errorMessage = "400 Bad Request"; last; };

          # The client does not have access to this resource, authorization is needed
          /401 (?:Unauthorized|Authorization Required)/ && do { $knownError = 1; $errorMessage = "401 Unauthorized User"; last; };

          # Payment is required. Reserved for future use
          /402 Payment Required/ && do { $knownError = 1; $errorMessage = "402 Payment Required"; last; };

          # The server understood the request, but is refusing to fulfill it. Access to a resource is not allowed.
          # The most frequent case of this occurs when directory listing access is not allowed.
          /403 Forbidden/ && do { $knownError = 1; $errorMessage = "403 Forbidden Connection"; last; };

          # The resource request was not found. This is the code returned for missing pages or graphics.
          # Viruses will often attempt to access resources that do not exist, so the error does not necessarily represent a problem.
          /404 (?:Page )?Not Found/ && do { $knownError = 1; $errorMessage = "404 Page Not Found"; last; };

          # The access method (GET, POST, HEAD) is not allowed on this resource
          /405 Method Not Allowed/ && do { $knownError = 1; $errorMessage = "405 Method Not Allowed"; last; };

          # None of the acceptable file types (as requested by client) are available for this resource
          /406 Not Acceptable/ && do { $errorMessage = "406 Not Acceptable"; last; };

          # The client does not have access to this resource, proxy authorization is needed
          /407 Proxy Authentication Required/ && do { $knownError = 1; $errorMessage = "407 Proxy Authentication Required"; last; };

          # The client did not send a request within the required time period
          /408 Request Time(?:[- ])?[oO]ut/ && do { $knownError = 1; $errorMessage = "408 Request Timeout"; last; };

          # The request could not be completed due to a conflict with the current state of the resource.
          /409 Conflict/ && do { $knownError = 1; $errorMessage = "409 Conflict"; last; };

          # The requested resource is no longer available at the server and no forwarding address is known.
          # This condition is similar to 404, except that the 410 error condition is expected to be permanent.
          # Any robot seeing this response should delete the reference from its information store.
          /410 Gone/ && do { $knownError = 1; $errorMessage = "410 Gone"; last; };

          # The request requires the Content-Length HTTP request field to be specified
          /411 (?:Content )?Length Required/ && do { $knownError = 1; $errorMessage = "411 Length Required"; last; };

          # The precondition given in one or more of the request-header fields evaluated to false when it was tested on the server.
          /412 Precondition Failed/ && do { $knownError = 1; $errorMessage = "412 Precondition Failed"; last; };

          # The server is refusing to process a request because the request entity is larger than the server is willing or able to process.
          /413 Request Entity Too Large/ && do { $knownError = 1; $errorMessage = "413 Request Entity Too Large"; last; };

          # The server is refusing to service the request because the Request-URI is longer than the server is willing to interpret.
          # The URL is too long (possibly too many query keyword/value pairs)
          /414 Request[- ]URL Too Large/ && do { $knownError = 1; $errorMessage = "414 Request URL Too Large"; last; };

          # The server is refusing to service the request because the entity of the request is in a format not supported by the requested resource for the requested method.
          /415 Unsupported Media Type/  && do { $knownError = 1; $errorMessage = "415 Unsupported Media Type"; last; };

          # The portion of the resource requested is not available or out of range
          /416 Requested Range (?:Invalid|Not Satisfiable)/ && do { $knownError = 1; $errorMessage = "416 Requested Range Invalid"; last; };

          # The Expect specifier in the HTTP request header can not be met
          /417 Expectation Failed/ && do { $knownError = 1; $errorMessage = "417 Expectation Failed"; last; };
        }

        rename ($debugfile, "$debugfile-KnownError") if ( defined $debugfile and $knownError );
        ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $returnCode, alert => "'". $errorMessage ."' - ". $url_r->{Msg}, error => &_error_message( $req->method .' '. $req->uri ), result => $resp_string }, $TYPE{REPLACE} );
        return ( $returnCode );
      }
    } else {
      $returnCode = $ERRORS{OK} if $res->is_success;
    }

    $resp_string = $res->as_string;

    if ( $parms{custom} ) {
	  my ($returnCode, $knownError, $errorMessage) = $parms{custom}->( $resp_string );
      rename ($debugfile, "$debugfile-KnownError") if ( defined $debugfile and $knownError );

	  if ( $returnCode != $ERRORS{OK} and defined $errorMessage ) {
        ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $returnCode, alert => $errorMessage .' - '. $url_r->{Msg}, error => &_error_message ( $req->method .' '. $req->uri ), result => $resp_string }, $TYPE{REPLACE} );
        return ( $returnCode );
	  }
	}

    $self->_my_return ( $url_r->{Exp_Return}, $resp_string);

    if ( $self->_my_match ( $url_r->{Exp_Fault}, $resp_string) ) {
      my $fault_ind = $url_r->{Exp_Fault};
      my ($bad_stuff) = $resp_string =~ /($fault_ind.*\n.*\n)/;
      ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => $url_r->{Msg_Fault}, error => &_error_message ( $req->method .' '. $req->uri ), result => $bad_stuff }, $TYPE{REPLACE} );
      return ( $ERRORS{CRITICAL} );
    } elsif ( ! ($found = $self->_my_match ( $url_r->{Exp}, $resp_string)) ) {
      my $exp_type = ref $url_r->{Exp};
      my $exp_str = $exp_type eq 'ARRAY' ? "@{$url_r->{Exp}}" : $url_r->{Exp};
      ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "'". $url_r->{Msg} ."' - '". $exp_str ."' not in response", error => &_error_message ( $req->method .' '. $req->uri ), result => $resp_string }, $TYPE{REPLACE} );
      return ( $ERRORS{CRITICAL} );
    } elsif (ref $url_r->{Exp} eq 'ARRAY') {
      my $exp_array = @{$url_r->{Exp}};

      if ( $exp_array != $found ) {
        ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "'". $url_r->{Msg} ."' - '". ( $exp_array - $found ) ."' element(s) not in response", error => &_error_message ( $req->method .' '. $req->uri ), result => $resp_string }, $TYPE{REPLACE} );
        return ( $ERRORS{CRITICAL} );
      }
    }

    if ( $parms{download_images} ) {
      my ($image_dl_ok, $image_dl_msg, $number_imgs_dl ) = &_download_images ($res, \%parms, \%downloaded);

      unless ( $image_dl_ok ) {
        ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => $image_dl_msg }, $TYPE{REPLACE} );
        return ( $ERRORS{CRITICAL} );
      }

      $self->{number_of_images_downloaded} += $number_imgs_dl;
    }
  }

  ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $returnCode, alert => ( ( $parms{download_images} and ! $returnCode ) ? "downloaded $self->{number_of_images_downloaded} images" : undef ), error => ( $returnCode ? '?' : undef ), result => $resp_string }, $TYPE{REPLACE} );
  return ( $returnCode );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _make_req {
  my ($self, $method, $url, $qs_var_ar, $qs_fixed_ar, $name_vals_hr) = @_;

  # $qs_var_ar is an array reference containing the name value pairs of any parameters whose
  # value is known only at run time

  # the format of $qs_var_ar is [cgi_parm_name => val, cg_parm_name => val ..]
  # where cgi_parm_name is the name of a fill out form parameter and val is a string used as a
  # key in %$name_vals_hr to get the value of the cgi_parameter.

  # eg [p_tm_number, tmno] has the parameter name 'p_tm_number' and val 'tmno'.

  # If $name_vals_hr = { tmno = > 1 }, the query_sring becomes p_tm_number=1

  # when the val is a digit, that digit is interpreted as a relative match in the last
  # set of matches found by ->_my_match eg

  # [p_tm_number => 1] means get the second match (from the last set of matches)
  # and use it as the value of p_tm_number.

  # If the value is a array ref eg [p_tm_number, [0, sub { $_[0] .'Blah' }]
  # then the query_string becomes p_tm_number => $ar->[1]( $name_vals{$ar->[0]} )

  # qs_fixed is an array_ref containing name value pairs

  my ($req, @query_string, $query_string, @qs_var, @qs_fixed, %name_vals, @nvp);
  my @matches = @{ $self->matches() };
  @qs_var = @$qs_var_ar;
  @qs_fixed = @$qs_fixed_ar;
  %name_vals = %$name_vals_hr;

  # add the matches as (over the top if some of the name_val keys are eq '0', '1' ..) keys to  %name_vals
  @name_vals {0 .. $#matches} = @matches;
  @query_string = ();
  @nvp = ();
  $query_string = '';

  while ( my ($name, $val) = splice(@qs_fixed, 0, 2) ) { splice(@query_string, scalar @query_string, 0, ($name, $val)); }

  # a cgi var name must be in qs_var for it's value to be changed (otherwise it doesn't get in the form query string)

  while ( my ($name, $val) = splice(@qs_var, 0, 2) ) {
    @nvp = ref $val eq 'ARRAY' ? ( $name, &{ $val->[1] }($name_vals{$val->[0]}) ) : ( $name, $name_vals{$val} );
    splice(@query_string, scalar @query_string, 0, @nvp);
  }

  if ( $method eq 'GET' ) {
    while ( my ($name, $val) = splice(@query_string, 0, 2) ) { $query_string .= "$name=$val&"; }

    if ($query_string) {
      chop($query_string);
      $req = GET $url .'?'. $query_string;
    } else {
      $req = GET $url;
    }
  } elsif ( $method eq 'POST' ) {
    $req = POST $url, [ @query_string ];
  } elsif ( $method eq 'HEAD' ) {
    $req = HEAD $url;
  } else { # do something to indicate no such method
    &_dumpValue ( $self, ref $self .": Unexpected method \"$method\" for url \"$url\"" );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _my_match {
  my ($self, $pat, $str) = @_;

  my $found = 0;
  my @matches = ();

  if ( ref $pat eq 'ARRAY') {
    my $debug = ${$self->{asnmtapInherited}}->getOptionsValue ( 'debug' );

    foreach my $p (@$pat) {
      print ref ($self) ."::_my_match: ? $p\n" if ( $debug >= 3 );

      if ( my @match = ($str =~ m#$p#) ) {
        print ref ($self) ."::_my_match: = @match\n" if ( $debug >= 3 );
        push (@matches, @match) if (scalar (@match));
        $found++;
      }
    }

    $self->matches ( \@matches );
  } else {
    $found = ($str =~ m#$pat#);
  }

  return $found;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _my_return {
  my ($self, $pat, $str) = @_;

  if ( ref $pat eq 'HASH') {
    my $debug = ${$self->{asnmtapInherited}}->getOptionsValue ( 'debug' );

    while ( my ($key, $value) = each ( %{$pat} ) ) {
      print ref ($self) ."::_my_return: ? $key => $value\n" if ( $debug >= 3 );

      if ( my @match = ($str =~ m#$value#g) ) {
        print ref ($self) ."::_my_return: = @match\n" if ( $debug >= 3 );
        $returns {$key} = (scalar (@match) == 1) ? $match[0] : [ @match ];
      } else {
        $returns {$key} = undef;
      }

      $self->returns ( \%returns );
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _write_debugfile {
  my ($self, $req_as_string1, $req_as_string2, $debugfile, $openAppend) = @_;

  my $rvOpen = open (HTTPDUMP, ($openAppend ? '>>' : '>') . $debugfile);

  if ($rvOpen) {
    $req_as_string2 =~ s/(window.location.href)/\/\/$1/gi;

    # RFC 1738 -> [ |$|&|+|,|\/|:|;|=|?|@|.|\-|!|*|'|(|)|\w]+
    $req_as_string2 =~ s/(<META *HTTP-EQUIV *= *\"Refresh\" +CONTENT *= *\"0; *URL *=[ |$|&|+|,|\/|:|;|=|?|@|.|\-|!|*|'|(|)|\w]+\">)/<!--$1-->/img;

    # comment <SCRIPT></SCRIPT>
    $req_as_string2 =~ s/<SCRIPT/<!--<SCRIPT/gi;
    $req_as_string2 =~ s/<\/SCRIPT>/<\/SCRIPT>-->/gi;

    print HTTPDUMP '<HR>', $req_as_string1, "\n";
    print HTTPDUMP '<HR>', $req_as_string2, "\n";
    close(HTTPDUMP);
  } else {
    print ref ($self) .": Cannot open $debugfile to print debug information\n";
  }
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub _download_images {
  my ($res, $parms_hr, $downloaded_hr)  = @_;

  require HTML::LinkExtor;
  require URI::URL;
  URI::URL->import(qw(url));

  my @imgs = ();

  my $cb = sub {
    my ($tag, %attr) = @_;
    return if $tag ne 'img';           # we only look closer at <img ...>
    push (@imgs, $attr{src});
  };

  my $p = HTML::LinkExtor->new($cb);
  $p->parse($res->as_string);

  my $base = $res->base;
  my @imgs_abs = grep ! $downloaded_hr->{$_}++, map { my $x = url($_, $base)->abs; } @imgs;
  my @img_urls = map { Method => 'GET', Url => $_->as_string, Qs_var => [], Qs_fixed => [], Exp => '.',  Exp_Fault => 'NeverInAnImage' }, @imgs_abs;

  # url() returns an array ref containing the abs url and the base.
  if ( my $number_of_images_not_already_downloaded = scalar @img_urls ) {
    my $img_trx = __PACKAGE__->new(\@img_urls);
    my %image_dl_parms = (%$parms_hr, fail_if_1 => FALSE, download_images => FALSE, indent_level => 1);
    return ( $img_trx->check( {}, %image_dl_parms), $number_of_images_not_already_downloaded );
  } else {
    return ( $ERRORS{OK}, 'Downloaded all __zero__ images found in '. $res->base, 0 );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _next_url {
  my ($resp, $resp_string) = @_;

  # FIXME. Some applications (eg IIS module for SAP R3) have an action field relative to hostname.
  # Others (eg ADDS v2) have use a refresh header with relative to hostname/path ..

  if ( $resp_string =~ m#META\s+http-equiv="refresh"\s+content="\d+;\s+url=([^"]+)"# ) {
    my $rel_url = $1;
    my $base = $resp->base;
    $base =~ m#(http://.+/).+?$#;
    my $url =  $1 . $rel_url;
    return $url;
  } elsif ( $resp_string =~ m#form name="[^"]+"\s+method="post"\s+action="([^"]+)"#i or $resp_string =~ m#form\s+method="post"\s+action="([^"]+)"#i ) {
    # Attachmate eVWP product doesn't have a form name.
    my $rel_url = $1;
    my $base = $resp->base;
    $base =~ m#(http://.+?)/#;	 		            # only want hostname
    my $url =  $1 . $rel_url;
    return $url;
  } else {
    return '';
  }
}

# Destructor  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DESTROY { print (ref ($_[0]), "::DESTROY: ()\n") if ( ${$_[0]->{asnmtapInherited}}->getOptionsValue ( 'debug' ) ) }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

is a Perl module that provides WebTransact functions used by ASNMTAP-based plugins.

=head1 DESCRIPTION

This module implements a check of a Web Transaction.

A Web transaction is a sequence of web pages, often fill out forms,
that accomplishes an enquiry or an update. Common examples are database
searches and registration activities.

=head1 AUTHOR

Stanley Hopcroft [Stanley.Hopcroft@IPAustralia.Gov.AU]
Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2003 Stanley.Hopcroft@IPAustralia.Gov.AU

ASNMTAP::Asnmtap::Plugins::WebTransact is based on 'Nagios::WebTransact' v0.14.1 from Stanley Hopcroft [Stanley.Hopcroft@IPAustralia.Gov.AU]

=head1 SEE ALSO

ASNMTAP::Asnmtap::Plugins::WebTransact.pod
