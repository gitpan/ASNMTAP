#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/08, v1.7, WebtransactASNMTAP output format and Asnmtap v3.000.xxx compatible
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

use Getopt::Long;
use vars qw($opt_i $opt_o $opt_f $opt_h $opt_V $PROGNAME);

my $PROGNAME = "GrinderCaptureConverter.pl";
my $prgtext  = "Grinder 2.x Capture Converter for check_template-WebTransact.pl";
my $version  = "1.7";
my $debug    = 0;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $infile;
my $outfile;
my $format = "LIST";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output_webtransact ();
sub output_list ();
sub printRevision ($$);
sub printUsage ();
sub printHelp ();

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Getopt::Long::Configure('bundling');

GetOptions (
  "i=s" => \$opt_i, "input-file=s"  => \$opt_i, # required
  "o=s" => \$opt_o, "output-file=s" => \$opt_o, # required
  "f:s" => \$opt_f, "format:s"      => \$opt_f, # optioneel
  "V"   => \$opt_V, "version"       => \$opt_V, # required
  "h"   => \$opt_h, "help"          => \$opt_h, # required
);

if ($opt_V) { printRevision($PROGNAME, $version); exit 0; }
if ($opt_h) { printHelp (); exit 0; }

if ($opt_i) { $infile  = $opt_i; } else { print("\n$PROGNAME: No grinder input file specified!\n");  exit 0; }
if ($opt_o) { $outfile = $opt_o; } else { print("\n$PROGNAME: No output file specified!\n"); exit 0; }
if ($opt_f) { if ($opt_f eq "LIST" or $opt_f eq "WEBTRANSACT") { $format = $opt_f; } else { print("\n$PROGNAME: Wrong format specified!\n"); exit 0; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Bepalen van de directory
my $pos = (rindex($infile, "\\") || rindex($infile, "/") ) + 1;
my $directory = substr($infile, 0, $pos);

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
  chomp ($l);

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
  push (@urlArray,  "$url");
  push (@postArray, "$postType");
  push (@dataArray, "$postData");
}

if ($format eq "WEBTRANSACT") {
  output_webtransact ();
} else {
  output_list ();
}

exit(0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output_webtransact () {
  open (OUTFILE, ">$outfile") || die ("Could not open webtransact output file");
  print OUTFILE "\$message = \"...\";\n\n";
  print OUTFILE "my \@URLS = (\n";

  for(my $c = 0; $c < @urlArray; $c++) {
    if (! ( ($urlArray[$c] =~ /.css/) || ($urlArray[$c] =~ /.gif/) || ($urlArray[$c] =~ /.jpg/) || ($urlArray[$c] =~ /.js/) || ($urlArray[$c] =~ /.png/) || ($urlArray[$c] =~ /.swf/) ) ) {
      if($postArray[$c] eq "POST") {
        my @tArray1 = split(/&/, $dataArray[$c]);
        my $Qs_fixed;

        foreach my $line (@tArray1){
          my ($name, $value) = split(/=/, $line);
          if (! $value) { $value = ""; }
          $Qs_fixed .= $name . " => " . "\"" . $value . "\"" . ", ";    # laatste ',' staat er teveel !!!
        }

        print OUTFILE "  { Method => \"POST\", Url => \"$urlArray[$c]\", Qs_var => [], Qs_fixed => [$Qs_fixed], Exp => \"<NIHIL>\", Exp_Fault => \"<NIHIL>\", Msg => \"<NIHIL>\", Msg_Fault => \"<NIHIL>\" },\n";
      } else {
        if($dataArray[$c] eq "<NIHIL>") {
          print OUTFILE "  { Method => \"GET\",  Url => \"$urlArray[$c]\", Qs_var => [], Qs_fixed => [], Exp => \"<NIHIL>\", Exp_Fault => \"<NIHIL>\", Msg => \"<NIHIL>\", Msg_Fault => \"<NIHIL>\" },\n";
        } else {
          print OUTFILE "  { Method => \"GET\",  Url => \"$urlArray[$c]\", Qs_var => [], Qs_fixed => [$dataArray[$c]], Exp => \"<NIHIL>\", Exp_Fault => \"<NIHIL>\", Msg => \"<NIHIL>\", Msg_Fault => \"<NIHIL>\" },\n";
        }
      }
    }
  }

  print OUTFILE ");\n\n";
  print OUTFILE "\$x = ASNMTAP::Asnmtap::Plugins::WebTransact->new( \\\@URLS );\n";
  print OUTFILE "(\$returnCode, \$error, \$alert, \$result) = \$x->check( {}, timeout => \$TIMEOUT, debug => \$debug, debugfile => \$debugfile, prefixPath => \$PREFIXPATH, proxy => { server => \$proxyServer, account => \$proxyUsername, pass => \$proxyPassword }, newAgent => 1 );\n\n";
  close (OUTFILE);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output_list () {
  open (OUTFILE, ">$outfile") || die ("Could not open list output file");

  for(my $c = 0; $c < @urlArray; $c++) {
    if (! (($urlArray[$c] =~ /.gif/) || ($urlArray[$c] =~ /.jpg/) || ($urlArray[$c] =~ /.png/) || ($urlArray[$c] =~ /.css/) || ($urlArray[$c] =~ /.js/)) ) {
      if($postArray[$c] eq "POST") {
        print OUTFILE "$postArray[$c]" . " - " . $urlArray[$c] . "?" . $dataArray[$c] . "\n";
      } else {
        print OUTFILE "$postArray[$c]" . " - " . $urlArray[$c] . "\n";
      }
    }
  }

  close (OUTFILE);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printRevision ($$) {
  my $commandName = shift;
  my $pluginRevision = shift;
  $pluginRevision =~ s/^\$Revision: //;
  $pluginRevision =~ s/ \$\s*$//;

  print "
$commandName $pluginRevision

© Copyright 2003-2006 by Alex Peeters [alex.peeters\@citap.be]

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printUsage () {
  print "Usage: $PROGNAME -i <input-file> -o <output-file> [-f LIST|WEBTRANSACT] [-h help] [-V version]\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp () {
  printRevision($PROGNAME, $version);
  print "This is the plugin '$prgtext'\n";
  printUsage();

  print "
-i, input-file <input-file>
-o, --output-file <output-file>
-f, --format [LIST|WEBTRANSACT], default: LIST
-V, --version
-h, --help

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
