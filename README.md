ExtractText
===========

This is a SpamAssassin plugin which attempts to read the content within binary files 
(like Word Documents) and allow SpamAssassin to score the contents of them.


The original source code was downloaded in December 2012 from :

http://whatever.truls.org/spamassassin.text.shtml#ExtractText.pm


Installation
============

Copy ExtractText.pm to e.g. /etc/spamassassin/

Edit /etc/spamassassin/local.cf and specify something like :


    loadplugin Mail::SpamAssassin::Plugin::ExtractText /etc/spamassassin/ExtractText.pm

    extracttext_mime_magic    yes
    extracttext_external      antiword     {CS:UTF-8} /usr/bin/antiword -t -w 0 -m UTF-8.txt ${file}
    extracttext_use           antiword     .doc application/(?:vnd\\.?)?ms-?word.*


Then test using something like :

    $ cat something-containing-a-doc-attachment.eml | spamassassin --debug > output.txt 2>&1

Then examine the contents of 'output.txt'.

Requirements 
============

On e.g. Debian Squeeze, you'll want to install the following :

    $ apt-get install libio-string-perl libipc-run3-perl libfile-mimeinfo-perl antiword

Other Bits
========

The plugin may support extraction from other file formats (the source files from the original .zip appear to support this) but we've not
investigated these.

YMMV and it may explode.


LICENSE
=======

Original source code was not clearly licensed. Refer to http://whatever.truls.org/ 
