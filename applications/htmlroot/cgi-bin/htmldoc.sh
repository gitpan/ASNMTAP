#!/bin/sh
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/05/01, v3.000.008, htmldoc.sh for ASNMTAP making Asnmtap v3.000.xxx compatible
# ---------------------------------------------------------------------------------------------------------
# Compatible with HTMLDOC v1.8.25 from http://www.htmldoc.org/ or http://www.easysw.com/htmldoc
#
# http://${SERVER_NAME}/cgi-bin/htmldoc.sh/cgi-bin/detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl?$QUERY_STRING
#                      <--------------------------------------- ${PATH_INFO} -------------------------------------->
# ----------------------------------------------------------------------------------------------------------

# The "options" variable contains any options you want to pass to HTMLDOC.
options='--bodyimage /opt/asnmtap-3.000.xxx/applications/htmlroot/img/logos/bodyimage.gif --charset iso-8859-1 --format pdf14 --size A4 --landscape --browserwidth 1280 --top 10mm --bottom 10mm --left 10mm --right 10mm --fontsize 10.0 --fontspacing 1.2 --headingfont Helvetica --bodyfont Helvetica --headfootsize 10.0 --headfootfont Helvetica --embedfonts --pagemode fullscreen --permissions no-copy,print --no-links --color --quiet --webpage --header ... --footer ...'

HTMLDOC_NOCGI=1; export HTMLDOC_NOCGI

# Tell the browser to expect a PDF file...
echo "Content-Type: application/pdf"
echo ""

# Run HTMLDOC to generate the PDF file...
htmldoc -t pdf $options http://${SERVER_NAME}:${SERVER_PORT}${PATH_INFO}?$QUERY_STRING

# ----------------------------------------------------------------------------------------------------------
