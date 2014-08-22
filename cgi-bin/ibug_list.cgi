#!/usr/bin/perl -w

# ibug_list.cgi - to make request and output list data
BEGIN {
    my $base_module_dir = (-d '/home2/rebiomex/perl' ? '/home2/rebiomex/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use strict;
use locale;
use CGI qw (:standard escapeHTML escape);
use HTML::Template;
use Encode;
require 'tools.pl';
require 'messages.pl';
require 'param_sql.pl';

my $template = HTML::Template->new(filename => 'ibug.tmpl', max_includes => 20,filter => sub {
                            my $ref = shift;
                            ${$ref} = Encode::decode_utf8(${$ref});
          $ref = &whitespace_clean($ref);
                        });

require 'db_connection.pl';
my $dbh=&return_dbh($template);

require 'user_login.pl';

my ($user_identifier,$user_name,$user_access,$etiquetes) = ();
(undef,$user_identifier,$user_name,$user_access,$etiquetes,$dbh) = &login_status($template,$dbh);

require 'db_requests.pl';

my ($search_param_list,$search_string,$clause) = &get_list_search_params($template,$dbh); # forming search parameter strings

my (@main_list_ref) = ();


if ($clause) 
{
  # prev/next related code
  my $position = &escape_numeric_input(param('position')) || 0;   # getting current position in table 
  my $limit = "LIMIT $position, 101";             # add current position in to search clause
  if (param("collector")) 
  {
    @main_list_ref = &search_main_list($limit,$clause,$template,$dbh); # slow request
  }
  else 
  {
    @main_list_ref = &search_main_list_simple($limit,$clause,$template,$dbh); # fast request
  }
    my $current_count = scalar @main_list_ref ;
  if ($current_count == 1) 
  { 
    $template->param(CURRENT_UNIQUE => 1,); 
  }
  if ($position <= 1) 
  { 
    $template->param(NO_PREVIOUS_FLAG => 1,); 
  }
  if (defined $main_list_ref [100]) 
  {
    # search retured line 100 - we can have next
    $#main_list_ref  = 99;         # leaving only first 99 lines, from 0 to 98
    my $next = $position + 100;
    $current_count--;
    $template->param(NEXT => $next,);
  }
  my $previuous = $position - 100;
  if ($previuous <= 0) 
  {
    $template->param(PREVIOUS => 0,);
  } 
  else 
  {
    $template->param(PREVIOUS => $previuous,);
  };
  $template->param(
        CURRENT_LOW => $position + 1,
        CURRENT_HIGH => $position + $current_count, 
        ); 
    # end of prev/next related code

  if ($current_count) # checks if we have at least one value in result array
  {
    # if we have something in array
    my @main_list = ();
    foreach my $main_ref (@main_list_ref) 
    {
      my %main = ();
      if (defined $$main_ref->{unit_id}) 
      {
        $main{UNIT_ID} = escapeHTML(&un($$main_ref->{unit_id}));
      }
      if (defined $$main_ref->{identification_id}) 
      {
        $main{IDENTIFICATION_ID} = escapeHTML(&un($$main_ref->{identification_id}));
      }
      if (defined $$main_ref->{genus_id}) 
      {
        # if genus_id is defined than we can output all related to preferred identification
        $main{GENUS} = escapeHTML(&un(&get_genus($$main_ref->{genus_id},$template,$dbh)));
        if (defined $$main_ref->{specie}) 
        {
          $main{SPECIE} = escapeHTML(&un($$main_ref->{specie}));
        } 
        else 
        {
          $main{SPECIE} = &messages('8003');
        }
        if (defined $$main_ref->{author_id} && (!defined $$main_ref->{infraspecific_epithet})) 
        {
          $main{AUTHOR} = escapeHTML(&un(&get_author($$main_ref->{author_id},$template,$dbh)));
        }
        if (defined $$main_ref->{name_addendum}) 
        {
          $main{NAME_ADDENDUM} = escapeHTML(&un($$main_ref->{name_addendum}));
        }
        if (defined $$main_ref->{identification_cualifier}) 
        {
          $main{IDENTIFICATION_CUALIFIER} = escapeHTML(&un($$main_ref->{identification_cualifier}));
        }
        if (defined $$main_ref->{infraspecific_epithet}) 
        {
          $main{INFRASPECIFIC_EPITHET} = escapeHTML(&un($$main_ref->{infraspecific_epithet}));
          if (defined $$main_ref->{infraspecific_flag}) 
          {
            $main{INFRASPECIFIC_FLAG} = escapeHTML(&un($$main_ref->{infraspecific_flag}));
          }
          if (defined $$main_ref->{specie} && ($$main_ref->{specie} eq $$main_ref->{infraspecific_epithet}))
          {
            if ((defined $$main_ref->{author_id})) 
            {
              $main{AUTHOR} = escapeHTML(&un(&get_author($$main_ref->{author_id},$template,$dbh)));
            } 
            elsif ((defined $$main_ref->{infraspecific_author_id}))
            {
              # correcting error if no specie author, but infraspecific author only is defined
              $main{AUTHOR} = escapeHTML(&un(&get_author($$main_ref->{infraspecific_author_id},$template,$dbh)));
            }
          }
          else
          {
            if (defined $$main_ref->{infraspecific_author_id}) 
            {
              $main{INFRASPECIFIC_AUTHOR} = escapeHTML(&un(&get_author($$main_ref->{infraspecific_author_id},$template,$dbh)));
            }
          }
        }
        if (defined $$main_ref->{hybrid_specie}) 
        {
          $main{HYBRID_SPECIE} = escapeHTML(&un($$main_ref->{hybrid_specie}));
          if (defined $$main_ref->{hybrid_genus_id}) 
          {
            $main{HYBRID_GENUS} = escapeHTML(&un(&get_genus($$main_ref->{hybrid_genus_id},$template,$dbh)));
          }
          if (defined $$main_ref->{hybrid_flag}) 
          {
            $main{HYBRID_FLAG} = escapeHTML(&un($$main_ref->{hybrid_flag}));
          } 
          else 
          {
            $main{HYBRID_FLAG} = 'x';
          }
          if (defined $$main_ref->{hybrid_author_id}) 
          {
            $main{HYBRID_AUTHOR} = escapeHTML(&un(&get_author($$main_ref->{hybrid_author_id},$template,$dbh)));
          }
        }
        if (defined $$main_ref->{genus_id}) 
        {
          $main{FAMILIA} = escapeHTML(&un(&get_family($$main_ref->{genus_id},$template,$dbh)));
        }
      } 
      else 
      {
        # if genus is not defined than we have nothing to do with identification
      }
      if (defined $$main_ref->{observations_plant_common_name}) 
      {
        $main{COMMON_NAME} = escapeHTML(&un($$main_ref->{observations_plant_common_name}));
      }
      if (defined $$main_ref->{collector_id}) 
      {
        my $collector = &get_agent($$main_ref->{collector_id},$template,$dbh);
        if (defined $collector) # it can be undef
        {
          $main{COLLECTOR} = escapeHTML(&un($collector));
          if (defined $$main_ref->{collector_field_number}) 
          {
            $main{COLLECTOR_FIELD_NUMBER} = escapeHTML(&un($$main_ref->{collector_field_number}));
          }
          else
          {
            $main{COLLECTOR_FIELD_NUMBER} = &messages('8007');
          }
        }
        else
        {
          $main{COLLECTOR} = &messages('8006');
        }
        if (defined $$main_ref->{collecting_date}) 
        {
          $main{COLLECTING_DATE} = escapeHTML(&un(&format_date($$main_ref->{collecting_date})));
        }
      }
      if (defined $$main_ref->{municipality_id}) 
      {
        my ($munic,$state,$country) = &get_municipality($$main_ref->{municipality_id},$template,$dbh);
        ($main{MUNICIPALITY},$main{STATE},$main{COUNTRY}) = (&un($munic),&un($state),&un($country));
      }
      if (defined $$main_ref->{herbarium_abbreviation}) 
      {
        $main{HERBARIUM_ABBREVIATION} = escapeHTML(&un($$main_ref->{herbarium_abbreviation}));
      }
      if (defined $$main_ref->{type_status}) 
      {
        $main{TYPE_STATUS} = escapeHTML(&un("\u$$main_ref->{type_status}"));
      }
      if (defined $$main_ref->{herbarium_number}) 
      {
        $main{HERBARIUM_NUMBER} = escapeHTML(&un($$main_ref->{herbarium_number}));
      }
      if (defined $$main_ref->{database_abbreviation}) 
      {
        $main{DATABASE_ABBREVIATION} = escapeHTML(&un($$main_ref->{database_abbreviation}));
      }
      if (defined $$main_ref->{count_status}) 
      {
        $main{COUNT_STATUS} = escapeHTML(&un($$main_ref->{count_status}));
      }
      push(@main_list, \%main);
    }
    $template->param(MAIN_LIST => \@main_list);
  } 
  else 
  {
    # if we have empty array
    $template->param(NO_MATCH => 1,);
  }
  $template->param(
    PAGE_TITLE => &messages('9008'),
    SEARCH_PARAM => \@$search_param_list,
    SEARCH_STRING => $search_string,
    UNIT_OUT => 0,
    UNIT_REQUEST => 0,
    LIST_OUT => 1,
    LIST_REQUEST => 0,
  );

} 
else 
{
  # if not defined any search parameter than output query form
  $template->param(
    PAGE_TITLE => &messages('9007'),
    UNIT_OUT => 0,
    UNIT_REQUEST => 0,
    LIST_OUT => 0,
    LIST_REQUEST => 1,
  );

}

&disconnect_dbh($dbh,$template);

# page output

print "Content-type: text/html; charset=utf-8\n\n";
binmode STDOUT, ":utf8";
print $template->output;

exit (0);











