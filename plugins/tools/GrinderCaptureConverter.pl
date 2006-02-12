#!/usr/bin/perl -w
# ---------------------------------------------------------------------------------------------------------
# Copyright (c)2004-2005 Yves Van den Hove (yves.vandenhove@smals-mvm.be)
# ---------------------------------------------------------------------------------------------------------
# 2006-01-30 - Version 1.8: use constant EXP_FAULT, little bugfix, sub URLDecode()
# 2006-01-12 - Version 1.7: Qs_fixed for GET requests, /i for regexp, my @URLS, Perfdata_Label, Msg, Msg_fault
# 2005-09-06 - Version 1.6: No more .ico
# 2004-08-30 - Version 1.5: $directory
# 2004-08-30 - Version 1.4: Script now removes \n and \r
# 2004-08-30 - Version 1.3: No more .js, .css
# 2004-06-14 - Version 1.2: Webtransact output format
# 2004-06-11 - Version 1.1: List output format
# 2004-06-09 - Version 1.0: Original design
# ---------------------------------------------------------------------------------------------------------
# Last Update: 30/01/2006 13:00
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;
use Getopt::Long;
use vars qw($opt_i $opt_o $opt_f $opt_h $opt_v $PROGNAME);

my $PROGNAME = "GrinderCaptureConverter.pl";
my $prgtext  = "Grinder Capture Converter";
my $version  = "1.8";
my $debug    = 0;

my $infile;
my $outfile;
my $format;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output_webtransact ();
sub output_list ();
sub print_help ();
sub print_usage ();
sub print_revision ();

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Getopt::Long::Configure('bundling');

GetOptions (
  "i=s" => \$opt_i, "input-file=s"  => \$opt_i, # required
  "o=s" => \$opt_o, "output-file=s" => \$opt_o, # required
  "f:s" => \$opt_f, "format:s"      => \$opt_f, # optioneel
  "v"   => \$opt_v, "version"       => \$opt_v, # required
  "h"   => \$opt_h, "help"          => \$opt_h, # required
);

if ($opt_v) { print_revision(); exit(0); }
if ($opt_h) { print_help(); exit(0); }

if ($opt_i) { $infile  = $opt_i; } else { print("$PROGNAME: No grinder input file specified!");  exit(0); }
if ($opt_o) { $outfile = $opt_o; } else { print("$PROGNAME: No output file specified!"); exit(0); }
if ($opt_f) { if ($opt_f eq "L" or $opt_f eq "W") { $format = $opt_f; } else { print("$PROGNAME: Wrong format specified!"); exit(0); } } else { $format = "L"; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Bepalen van de directory
$infile =~ /^((?:.*)\/)/;
my $directory = (defined $1) ? $1 : '';

# Openen van de inputfile
open (INFILE, "<$infile") || die ("Could not open grinder input file");

# Inlezen van de inputfile
my @inArray = <INFILE>;

# Sluiten van de file
close (INFILE);

# Variabelen nodig voor de verwerking
my @urlArray;
my @postArray;
my @dataArray;
my $url;
my $postType;
my $postData;
my $written = 1;

# De bruikbare lijnen uitfilteren
foreach my $l (@inArray){
  $l =~ s/\r//g;
  $l =~ s/\n//g;
  if ($l =~ /.parameter.url=/) {
    # De vorige url pushen
    if (! $written) {
      push (@postArray, "$postType");
      push (@urlArray,  "$url");
      push (@dataArray, "$postData");
      $written = 1;
    }

    # De nieuwe url bepalen
    my $pos = index($l, "=") + 1;
    $url = substr($l, $pos);
    $postType = "GET ";
    $postData = "<NIHIL>";
    $written = 0;
  } elsif ($l =~ /.parameter.header.If-Modified-Since=/) {
    $postType = "GET ";
    $written = 0;
  } elsif ($l =~ /.parameter.header.Content-Type=/) {
    $postType = "POST";
    $written = 0;
  } elsif ($l =~ /.parameter.post=/) {
    my $pos = index($l, "=") + 1;
    open (POSTFILE, $directory . substr($l, $pos)) || die ("Could not open post file");
    $postData = <POSTFILE>;
    close (POSTFILE);
  }
}

if (! $written) {
   #chop($url);
   push (@urlArray,  "$url");
   push (@postArray, "$postType");
   push (@dataArray, "$postData");
}

if ($format eq "W") {
   output_webtransact ();
} else {
   output_list ();
}

exit(0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output_webtransact () {
  open (OUTFILE, ">$outfile") || die ("Could not open webtransact output file");
  print OUTFILE "use WebTransactSmalsMvM;\n\n";
  print OUTFILE "my \$x;\n";
  print OUTFILE "my \$rc;\n\n";
  print OUTFILE "use constant EXP_FAULT => \"<NIHIL>\";\n\n";
  print OUTFILE "my \@URLS = (\n";

  for(my $c = 0; $c < @urlArray; $c++) {
    if (! ($urlArray[$c] =~ /.gif|.jpg|.png|.css|.ico$|.js$/i) ) {
      if($postArray[$c] eq "POST") {
        my @tArray1 = split(/&/, $dataArray[$c]);
				my(undef, $tFilename) = $urlArray[$c] =~ m/(.*\/)(.*)$/;
        my $Qs_fixed;
        foreach my $line (@tArray1){
          my ($name, $value) = split(/=/, $line);
          if (! $value) { $value = ""; }
          $Qs_fixed .= URLDecode($name) . " => " . "\"" . URLDecode($value) . "\"" . ", ";
        }  
        chop($Qs_fixed); chop($Qs_fixed);
        print OUTFILE "  { Method => \"POST\", Url => \"" . URLDecode($urlArray[$c]) . "\", Qs_var => [], Qs_fixed => [$Qs_fixed], Exp => \"<NIHIL>\", Exp_Fault => \"<NIHIL>\", Msg => \"$tFilename\", Msg_Fault => \"$tFilename\", Perfdata_Label => \"$tFilename\" },\n";
      } else {
      	my ($tUrl, $tParams) = split(/\?/, $urlArray[$c]);
      	my(undef, $tFilename) = $tUrl =~ m/(.*\/)(.*)$/; 	
      	my @tArray1 = split(/&/, $tParams) if (defined $tParams && $tParams ne '');
        my $Qs_fixed;
        if(@tArray1) {
	        foreach my $line (@tArray1){
	          my ($name, $value) = split(/=/, $line);
	          if (! $value) { $value = ""; }
	          $Qs_fixed .= URLDecode($name) . " => " . "\"" . URLDecode($value) . "\"" . ", ";
	        }          	
	      } else {
	      	$Qs_fixed="";
	      }
	      chop($Qs_fixed); chop($Qs_fixed);
        print OUTFILE "  { Method => \"GET\",  Url => \"" . URLDecode($tUrl) . "\", Qs_var => [], Qs_fixed => [$Qs_fixed], Exp => \"<NIHIL>\", Exp_Fault => EXP_FAULT, Msg => \"$tFilename\", Msg_Fault => \"$tFilename\", Perfdata_Label => \"$tFilename\" },\n";
      }
    }
  }

  print OUTFILE ");\n\n";
  print OUTFILE "\$x = Nagios::WebTransactSmalsMvM->new( \\\@URLS );\n";
  print OUTFILE "(\$rc, \$error, \$alert, \$result) = \$x->check( {}, timeout => \$TIMEOUT, debug => \$debug, httpdump => \$httpdump, proxy => { server => \$proxyServer, account => \$proxyUsername, pass => \$proxyPassword } );\n\n";
  print OUTFILE "\$message = \"...\";\n";
  print OUTFILE "exit_status ( \$status, \$debug, \$logging, \$httpdump, \$STATE{\$rc}, \$message, \$alert, \$error, \$result );\n\n";
  close (OUTFILE);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub URLDecode {
    my $theURL = $_[0];
    $theURL =~ tr/+/ /;
    $theURL =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
    $theURL =~ s/<!--(.|\n)*-->//g;
    return $theURL;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output_list () {
  open (OUTFILE, ">$outfile") || die ("Could not open list output file");

  for(my $c = 0; $c < @urlArray; $c++) {
    if (! ($urlArray[$c] =~ /.gif|.jpg|.png|.css|.ico$|.js$/i)  ) {
      if($postArray[$c] eq "POST") {
        print OUTFILE "$postArray[$c]" . " - " . URLDecode($urlArray[$c]) . "?" . URLDecode($dataArray[$c]) . "\n";
      } else {
        print OUTFILE "$postArray[$c]" . " - " . URLDecode($urlArray[$c]) . "\n";
      }
    }
  }

  close (OUTFILE);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage () {
  print "Usage: $PROGNAME \n        -i <input-file> \n        -o <output-file> \n       [-f L|W], L default \n       [-v version] \n       [-h help]\n\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_revision() {
  print "\nThis is $PROGNAME, v$version\n";
  print "Copyright (c) 2004-2006 Yves Van den Hove\n\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help () {
  print_revision();
  print_usage();
  print "Send an email to yves.vandenhove\@smals-mvm.be if you have any questions regarding the use of this software.\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

