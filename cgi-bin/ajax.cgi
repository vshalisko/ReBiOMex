#!/usr/bin/perl -w

#ajax.cgi - script to respond simple small ajax requests
BEGIN {
    my $base_module_dir = (-d '/home2/rebiomex/perl' ? '/home2/rebiomex/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use strict;
use locale;
use utf8;
use CGI qw (:standard escapeHTML escape);
use HTML::Template;
use Data::Random::String;
use Encode;
require 'tools.pl';
require 'messages.pl';
require 'param_sql.pl';

# though output is not templated, we still need to include template for the reason that 
# common db_request routins and some other require template for error output
# db_connection.pl and user_login.pl require it as well
# we use special almost empty template ajax.tmpl to process this
my $template = HTML::Template->new(filename => 'ajax.tmpl', max_includes => 20,filter => sub {
                            my $ref = shift;
                            ${$ref} = Encode::decode_utf8(${$ref});
          $ref = &whitespace_clean($ref);
                        });

require 'db_connection.pl';
my $dbh=&return_dbh($template);

require 'user_login.pl';
my (undef,undef,undef,$access_mode) = &login_status($template,$dbh);

my $mode_ajax = param("mode"); # variable thas stores ajax request mode (i. e. what request should be processed)

my $result_ajax = '';

if (defined $mode_ajax && ($mode_ajax eq 'list_record_number'))
{
  # looking for record number in main_list request
  my ($search_param_list,$search_string,$clause) = &get_list_search_params($template,$dbh); # forming search parameter strings
  if ($clause) {
    my @main_list_ref = &get_main_list_record_number($clause,$template,$dbh);
    foreach my $main_ref (@main_list_ref) 
    {
      if (defined $$main_ref->{record_number}) 
      {
        $result_ajax = $$main_ref->{record_number};
      }
      else
      {
        $result_ajax = '???';
      }
    }
  }     
}

if (defined $mode_ajax && ($mode_ajax eq 'get_control_select') && param("field_name"))
{
  # generate list for input control in base of table SELECT
  # input parameter should include 3-4 letter string $string to search and name of column and table where to search
  # strings to use in SELECT statement:
  # SELECT something_id, something FROM sometable WHERE smething LIKE '$string%' OR something LIKE '% $string%'
  # output list than shuld be processed to form list control with combined values like
  # 'J. A. Vázquez (ID=2873)', and real values in options like something_id
  
  # PROBLEM: instead of 2 separate requests here should be only one
  
  my $table = &escape_input(param("table")) || ''; # name of table
  my $column = &escape_input(param("column")) || ''; # name of column with values
  my $id_column = &escape_input(param("id_column")) || ''; # name of column with ID's
  my $search_string = &escape_input_1(param("search_string")) || ''; # text substring to search
  my $search_ids = &escape_input(param("search_ids")) || ''; # list of comma separates ID's  for most frequent values (for future implementation)
  my $actual_id = &escape_numeric_input(param("actual_id")) || ''; # actual active value ID
  my $field_name = &escape_input(param("field_name")) || $id_column; # selector name for form (should not be empty)
  my $extended_search = &escape_numeric_input(param("extended_search")) || '';
  my $multiple = &escape_numeric_input(param("multiple")) || '';

  if ($table && $column && $id_column && ($search_string || $search_ids  || $actual_id))
  {
    # look in table and form respective control element
    $id_column = &escape_input($id_column);
    $column = &escape_input($column);
    $table = &escape_input($table);
    my $search_count = 0;
    my ($selected_flag,@list,%duplicates_hash); # %duplicates_hash to control repiting values (as we combine two different requests in one)
    if ($search_ids || $actual_id)  # first SQL request by IDs
    {
      # looking for values basing on id's - it should appear at the top of the list
      my (@search_ids);
      my $sql_string = 'SELECT '.$id_column.', '.$column; 
      $sql_string .= ' FROM '.$table.' WHERE ';
      if ($search_ids) 
      {
        @search_ids = &escape_numeric_input(&parse_csv($search_ids)); # list context
      }
      if ($actual_id) 
      {
        push (@search_ids, &escape_numeric_input($actual_id));
      }
      foreach my $search_id (@search_ids)
      {
        $sql_string .= $id_column.' = \''.&escape_input($search_id).'\' OR '; 
      }
      $sql_string .= '0 ORDER BY '.$column.', '.$id_column; # terminal value for OR

      my (@sql_result_ref) = &main_list(&un($sql_string),$template,$dbh);
      if (scalar @sql_result_ref )
      {
        foreach my $sql_result_ref (@sql_result_ref)
        {
          my %list_values;
          $list_values{ID_VALUE} = escapeHTML(&un($$sql_result_ref->{$id_column}));
          $list_values{VALUE} = escapeHTML(&un($$sql_result_ref->{$column}));
          $list_values{CACHED} = 1; # all values received by id is for most frequent uses or for active value
          $duplicates_hash{$list_values{ID_VALUE}} = $list_values{VALUE};
          if (!$selected_flag && ($list_values{ID_VALUE} eq &escape_numeric_input($actual_id)))
          {
            $list_values{SELECTED} = 1;
            $selected_flag = 1;
          }
          push (@list, \%list_values);
          $search_count++;
        }
      }
    }   
    if ($search_string) # second SQL request by search_string
    {
      # looking for values containing substring
      my $sql_string = 'SELECT '.$id_column.', '.$column; 
      $sql_string .= ' FROM '.$table.' WHERE '.$column;
      $sql_string .= ' LIKE \''.Encode::encode_utf8($search_string);  # seems that this encode_utf8 allows to search for UTF8 characters
      if ($search_string && !($search_string=~m/%$/))
      {
        $sql_string .= '%\'';
      }
      else
      {
        $sql_string .= '\'';
      }
      if ($extended_search)
      {
        $sql_string .= ' OR '.$column.' LIKE \'% '.Encode::encode_utf8($search_string); # seems that this encode_utf8 allows to search for UTF8 characters
        if ($search_string && !($search_string=~m/%$/))
        {
          $sql_string .= '%\'';
        }
        else
        {
          $sql_string .= '\'';
        }
      }

      $sql_string .= ' ORDER BY '.$column.', '.$id_column;
      
      # &sql_error_out("AJAX debugging: $sql_string",$template); # debug
      
      my (@sql_result_ref) = &main_list($sql_string,$template,$dbh);
      if (scalar @sql_result_ref )
      {
        foreach my $sql_result_ref (@sql_result_ref)
        {
          my %list_values;
          $list_values{ID_VALUE} = escapeHTML(&un($$sql_result_ref->{$id_column}));
          $list_values{VALUE} = escapeHTML(&un($$sql_result_ref->{$column}));
          if (!$selected_flag && ($list_values{VALUE} eq $search_string)) 
          {
            $list_values{SELECTED} = 1;
            $selected_flag = 1;
          }
          #if (!defined $duplicates_hash{$list_values{ID_VALUE}}) # check if we already have the same value in selected by id part
          #{
            push (@list, \%list_values);
            $search_count++;
          #}
        }
      }
      
      if ($search_count == 0)
      {
        # empty list was returned after search
        $template->param(
          EMPTY_LIST => 1,
          WARNING => &messages('1032'),
          );
      }
      
    }
    if (!scalar @list)
    {
      @list = ({ID_VALUE => '',});
    }
    $template->param(
      CONTROL_LIST => \@list,
      FIELD_NAME => $field_name,
      MULTIPLE => $multiple,
    );
    # request should be tested before
    # SELECT something_id, something FROM sometable WHERE smething LIKE '$string%' OR something LIKE '% $string%'
  }
  else
  {
    if ($table && $column && $id_column)
    {
      # there is no search parameters, but reference table is defined
      $template->param(
        CONTROL_LIST =>[{ID_VALUE => '',}] ,
        FIELD_NAME => $field_name,
      );
    }
    else
    {
      # insuficient parameters to requet table- warning
      $template->param(
        WARNING => &messages('1031'),
      );
    }
  }
}

&disconnect_dbh($dbh,$template);

$template->param(
      AJAX_RESULT => $result_ajax,
      );

my $unique_id = Data::Random::String->create_random_string(length=>'32', contains=>'alphanumeric');

# http output
# this script output should not be cached
print "Content-type: text/html; charset=utf-8\nETag: $unique_id\nCache-control: no-cache, must-revalidate\nPragma: no-cache\nExpires: Mon, 01 Jan 2007 01:00:00 GMT\n\n";
binmode STDOUT, ":utf8";
print $template->output;

exit (0);