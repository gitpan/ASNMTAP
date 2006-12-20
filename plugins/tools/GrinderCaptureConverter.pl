#!/usr/bin/perl -w
# ---------------------------------------------------------------------------------------------------------
#
# Copyright (c)2004-2006 Yves Van den Hove (yves\@vandenhove.tk) & Alex Peeters (alex.peeters\@citap.com)
#
# ---------------------------------------------------------------------------------------------------------
# 2006-12-05 - Version 1.14: No more .bmp
# 2006-11-27 - Version 1.13: Support for robots.txt and automatic numbering for Perfdata_Label
# 2006-03-10 - Version 1.12: "POST" --> 'POST', "GET" --> 'GET', bug fixed for missing 0 in values
# 2006-02-22 - Version 1.11: " --> '
# 2006-02-21 - Version 1.10: Variables are now quoted, little optimalisations
# 2006-02-20 - Version 1.9:  Changes for compatibility with new Webtransact library
# 2006-02-20 - Version 1.9:  Changes for compatibility with new library
# 2006-01-30 - Version 1.8:  use constant EXP_FAULT, little bugfix, sub URLDecode()
# 2006-01-12 - Version 1.7:  Qs_fixed for GET requests, /i for regexp, my @URLS, Perfdata_Label, Msg, Msg_fault
# 2005-09-06 - Version 1.6:  No more .ico
# 2004-08-30 - Version 1.5:  $directory
# 2004-08-30 - Version 1.4:  Script now removes \n and \r
# 2004-08-30 - Version 1.3:  No more .js, .css
# 2004-06-14 - Version 1.2:  Webtransact output format
# 2004-06-11 - Version 1.1:  List output format
# 2004-06-09 - Version 1.0:  Original design
# ---------------------------------------------------------------------------------------------------------
# Last Update: 05/12/2006 16:13
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;
use Getopt::Long;
use vars qw($opt_i $opt_o $opt_f $opt_h $opt_v $PROGNAME);

my $PROGNAME = "GrinderCaptureConverter.pl";
my $prgtext  = "Grinder Capture Converter";
my $version  = "1.14";
my $debug    = 0;

my $infile;
my $outfile;
my $format;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output_webtransact();
sub output_list();
sub print_help();
sub print_usage();
sub print_revision();

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
if ($opt_h) { print_help();     exit(0); }

if ($opt_i) { $infile  = $opt_i; } else { print_revision(); print_usage(); print("$PROGNAME: No grinder input file specified!\n\n");  exit(0); }
if ($opt_o) { $outfile = $opt_o; } else { print_revision(); print_usage(); print("$PROGNAME: No output file specified!\n\n"); exit(0); }
if ($opt_f) { if ($opt_f eq "L" or $opt_f eq "W") { $format = $opt_f; } else { print_revision(); print_usage(); print("$PROGNAME: Wrong format specified!\n\n"); exit(0); } } else { $format = "W"; }

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
  print OUTFILE "\@URLS = (\n";

  for(my $c = 0, my $t = 1; $c < @urlArray; $c++) 
  {
    if (! ($urlArray[$c] =~ /(\.(gif|jpg|png|css|ico|js|bmp)|(robots\.txt))$/i) ) 
	{
      if($postArray[$c] eq "POST") 
	  {
         my @tArray1 = split(/&/, $dataArray[$c]);
		 my(undef, $tFilename) = $urlArray[$c] =~ m/(.*\/)(.*)$/;
         my $Qs_fixed;
         foreach my $line (@tArray1)
		 {
         	my ($name, $value) = split(/=/, $line);
         	if (! defined $value) { $value = ""; }
         	$Qs_fixed .= "'" . URLDecode($name) . "'" . " => " . "'" . URLDecode($value) . "'" . ", ";
         }  
	     $Qs_fixed = substr($Qs_fixed, 0, -2);
         print OUTFILE "  { Method => 'POST', Url => \"" . URLDecode($urlArray[$c]) . "\", Qs_var => [], Qs_fixed => [$Qs_fixed], Exp => '<NIHIL>', Exp_Fault => EXP_FAULT, Msg => '$tFilename', Msg_Fault => MSG_FAULT, Perfdata_Label => '[". sprintf("%02d", $t++) ."] $tFilename' },\n";
      } 
	  else 
	  {
      	 my ($tUrl, $tParams)  = split(/\?/, $urlArray[$c]);
      	 my(undef, $tFilename) = $tUrl =~ m/(.*\/)(.*)$/; 	
      	 my @tArray1 = split(/&/, $tParams) if (defined $tParams && $tParams ne '');
         my $Qs_fixed;
         if(@tArray1) 
		 {
	        foreach my $line (@tArray1)
			{
	       	   my ($name, $value) = split(/=/, $line);
	           if (! defined $value) { $value = ""; }
	           $Qs_fixed .= "'" . URLDecode($name) . "'" . " => " . "'" . URLDecode($value) . "'" . ", ";
	        }          	
		 } 
		 else 
		 {
	    	$Qs_fixed="";
		 }
	     $Qs_fixed = substr($Qs_fixed, 0, -2);
         print OUTFILE "  { Method => 'GET',  Url => \"" . URLDecode($tUrl) . "\", Qs_var => [], Qs_fixed => [$Qs_fixed], Exp => '<NIHIL>', Exp_Fault => EXP_FAULT, Msg => '$tFilename', Msg_Fault => MSG_FAULT, Perfdata_Label => '[". sprintf("%02d", $t++) ."] $tFilename' },\n";
      }
    }
  }

  print OUTFILE ");\n\n";
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
    if (! ($urlArray[$c] =~ /(\.(gif|jpg|png|css|ico|js|bmp)|(robots\.txt))$/i) ) {
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

sub print_usage() {
  print "Usage: $PROGNAME \n        -i <input-file> \n        -o <output-file> \n       [-f L|W], W default \n       [-v version] \n       [-h help]\n\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_revision() {
  print "\nThis is $PROGNAME, v$version\n";
  print "Copyright (c) 2004-2006 Yves Van den Hove\n\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help() {
  print_revision();
  print_usage();
  print "Send an email to yves\@vandenhove.tk if you have any questions regarding the use of this software.\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
