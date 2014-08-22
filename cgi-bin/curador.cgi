#!/usr/bin/perl -w

# curador interface 
# to modify reference tables
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

our $script_name = 'curador.cgi'; # making it as a global variable to let table processing.pl script to use it and pass to template

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
  if (param("s_unit")) {
    $template->param(WIZARD_CAPTURE => 1);
    $template->param(WIZARD_CAPTURE_5 => 1);
  }
} elsif ($table eq "view_normal_identifications") {
  &v_normal_identifications($action,$table,$user_id,$template,$dbh);
  if (param("s_unit")) {
    $template->param(WIZARD_CAPTURE => 1);
    $template->param(WIZARD_CAPTURE_4 => 1);
  }
} elsif ($table eq "vegetation") {
  &t_vegetation($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "municipality") {
  &t_municipality($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "country") {
  &t_country($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "method") {
  &t_method($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "project") {
  &t_project($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "named_area") {
  &t_named_area($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "herbarium") {
  &t_herbarium($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "regnum") {
  &t_regnum($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "familia") {
  &t_familia($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "genus") {
  &t_genus($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "subgeneric") {
  if ($action eq "depuration") {
    &depuration_subgeneric($action,$user_id,$template,$dbh); # curator only tool for table depuration
  } else {
    &t_subgeneric($action,$table,$user_id,$template,$dbh);
  }
} elsif ($table eq "author") {
  &t_author($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "reference") {
  &t_reference($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "publication") {
  &t_publication($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "teams") {
  if ($action eq "regeneration") {
    &regeneration_teams($action,$user_id,$template,$dbh); # curator only tool for col_det_agent table regeneration
  } else {
    &t_teams($action,$table,$user_id,$template,$dbh);
  }
} elsif ($table eq "persons") {
  &t_persons($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "institution") {
  &t_institution($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "user") {
  &t_user($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "assignation_named_area") {
  &t_assignation_named_area($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "assignation_reference") {
  &t_assignation_reference($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "assignation_status") {
  &t_assignation_status($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "identification") {
  &t_identification($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "specimen") {
  &t_specimen($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "unit") {
  &t_unit($action,$table,$user_id,$template,$dbh);
} elsif ($table eq "specimen_image") {
  &t_specimen_image($action,$table,$user_id,$template,$dbh);
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
  PAGE_TITLE => &messages('9011').' '.&messages('9020').$table,
  CURADOR_INTERFACE => 1,
  SCRIPT_NAME => $script_name,
  TABLE_NAME => $table,
  );

&disconnect_dbh($dbh,$template);

# page output

print "Content-type: text/html; charset=utf-8\n\n";
binmode STDOUT, ":utf8";
print $template->output;



sub depuration_subgeneric {
  # removing of duplicate records in subgeneric table
  my ($action,$user_id,$template,$dbh) = @_;
  require 'db_table_processing.pl';
  my $good_id = &trim(param("depuration_subgeneric_good_id"));
  my @bad_ids = &trim(param("depuration_subgeneric_bad_ids"));
  
  my $table_to_update_1 = "identification";
  my $column_to_update_table_1 = "subgeneric_id";
  my $table_to_delete = "subgeneric";
  my $column_table_to_delete = "subgeneric_id";
  
  if ($good_id && scalar @bad_ids > 0)
  {
    my $depuration_record_count = 0;
    my $depuration_delete_count = 0;
    foreach my $bad_id (@bad_ids)
    {
      # updating
      my $search_string = "FROM $table_to_update_1 WHERE $column_to_update_table_1 = '$bad_id'";
      my $update_string = "UPDATE $table_to_update_1 SET $column_to_update_table_1 = '$good_id', user_id = '$user_id', date_mod = CURDATE() WHERE $column_to_update_table_1 = '$bad_id'";
      my ($updated_count,$update_ext_key) = &record_update(0,$update_string,$search_string,$template,$dbh); # non strict update
      $depuration_record_count = $depuration_record_count + $updated_count;
      # deleting
      my $delete_string = "FROM $table_to_delete WHERE $column_table_to_delete = '$bad_id'";
      my ($deleted_count,$delete_ext_key) = &record_delete($delete_string,$template,$dbh);
      $depuration_delete_count = $depuration_delete_count +$deleted_count;
    }
    $template->param(ACTION_DEPURATION_REPORT => 1);
    $template->param(DEPURATION_RECORD_COUNT => $depuration_record_count);
    $template->param(DEPURATION_RECORD_TABLE => $table_to_update_1);
    $template->param(DEPURATION_DELETE_COUNT => $depuration_delete_count);
    $template->param(DEPURATION_DELETE_TABLE => $table_to_delete);
  }
  else
  {
    $template->param(ACTION_DEPURATION_REPORT => 1);
    $template->param(ACTION_DEPURATION_PROBLEM => 1);
  }

}

sub regeneration_teams {
  my ($action,$user_id,$template,$dbh) = @_;
  require 'db_requests_extended.pl';
  my ($regeneration_report) = &regenerate_col_det_agent($template,$dbh);
    $template->param(ACTION_REGENERATION_TABLE => "col_det_agent");	  
    $template->param(ACTION_REGENERATION_REPORT => 1);
    $template->param(ACTION_REGENERATION_RESULT => escapeHTML($regeneration_report));
  if (!$regeneration_report) {
	  $template->param(ACTION_REGENERATION_PROBLEM => 1);	
  } 
}

exit (0);

