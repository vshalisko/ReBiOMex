#!/usr/bin/perl -w

# investigador interface 
BEGIN {
    my $base_module_dir = (-d '/home2/rebiomex/perl' ? '/home2/rebiomex/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use Carp; # carp - debug module, comment this to reduce log size
$SIG{__WARN__} = \&carp;
$SIG{__DIE__} = \&confess;

use strict;
use locale;
use CGI qw (:standard escapeHTML escape);
use HTML::Template;
use Encode;
require 'tools.pl';
require 'messages.pl';

our $script_name = 'investigador.cgi'; # making it as a global variable to let table processing.pl script to use it and pass to template

my $template = HTML::Template->new(filename => 'ibug_access.tmpl', max_includes => 20,filter => sub {
                            my $ref = shift;
                            ${$ref} = Encode::decode_utf8(${$ref});
          $ref = &whitespace_clean($ref);
                        });

require 'db_connection.pl';
my $pre_dbh=&return_dbh($template);

require 'user_login.pl';
my ($user_id,undef,undef,$access_mode) = &login_status($template,$pre_dbh);

my $dbh=&reconnect_dbh($access_mode,$template,$pre_dbh);

require 'db_table_definitions.pl';

my $table = &un(param("table")) || ''; # define table to work with
my $action = &un(param("action")) || 'start';  # define action to realize


# selector of table subs
if ($table eq "wizard_step_1") {
  &w_step_1($action,$table,$user_id,$template,$dbh);
  $template->param(WIZARD_CAPTURE => 1);
  $template->param(WIZARD_CAPTURE_1 => 1);
 } elsif ($table eq "wizard_step_2") {
  &w_step_2($action,$table,$user_id,$template,$dbh);
  $template->param(WIZARD_CAPTURE => 1);
  $template->param(WIZARD_CAPTURE_2 => 1);
 } elsif ($table eq "wizard_step_3") {
  &w_step_3($action,$table,$user_id,$template,$dbh);
  $template->param(WIZARD_CAPTURE => 1);
  $template->param(WIZARD_CAPTURE_3 => 1);
} elsif ($table eq "view_specimen") {
  &v_specimen($action,$table,$user_id,$template,$dbh);
  $template->param(WIZARD_CAPTURE => 1);
  $template->param(WIZARD_CAPTURE_5 => 1);
} elsif ($table eq "view_normal_identifications") {
  &v_normal_identifications($action,$table,$user_id,$template,$dbh);
  $template->param(WIZARD_CAPTURE => 1);
  $template->param(WIZARD_CAPTURE_4 => 1);
} elsif ($table eq "view_reference") {
  &v_reference($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_specimen_full") {
  &v_specimen_full($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_unit_collector") {
  &v_unit_collector($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_unit_collector_full") {
  &v_unit_collector_full($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_species") {
  &v_species($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_type_identifications") {
  &v_type_identifications($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_assignation_named_area") {
  &v_assignation_named_area($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_assignation_reference") {
  &v_assignation_reference($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_method_identification") {
  &t_method($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_method_collecting") {
  &t_method($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "view_specimen_images") {
  &v_specimen_images($action,$table,$user_id,$template,$dbh);
} else {
  # if no table is defined than we need to output interface of initial table selection
  $template->param(TABLE_SELECT_OUTPUT => 1);
}

$template->param(
  PAGE_TITLE => &messages('9012').' '.&messages('9020').$table,
  INVESTIGADOR_INTERFACE => 1,
  SCRIPT_NAME => $script_name,
  TABLE_NAME => $table,
  );

&disconnect_dbh($dbh,$template);

# page output

print "Content-type: text/html; charset=utf-8\n\n";
binmode STDOUT, ":utf8";
print $template->output;

exit (0);

