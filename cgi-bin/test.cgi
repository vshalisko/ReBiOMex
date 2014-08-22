#!/usr/bin/perl -w

BEGIN {
    my $base_module_dir = (-d '/home2/rebiomex/perl' ? '/home2/rebiomex/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use strict;
use locale;
use CGI qw (:standard escapeHTML escape);
use HTML::Template;

require 'tools.pl';

print "Content-type: text/html; charset=utf-8\n\n";
binmode STDOUT, ":utf8";

print &check_text('sdf123') . "\n";
print &check_number('12d3') . "\n";
print &check_date('2007-12-24') . "\n";

