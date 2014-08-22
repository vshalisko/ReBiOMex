#!/usr/bin/perl -w

# canasta.cgi - canasta processing
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

#use Carp; # carp - debug module, comment this to reduce log size
#$SIG{__WARN__} = \&carp;
#$SIG{__DIE__} = \&confess;

my ($etiquetes_new);

my $template = HTML::Template->new(filename => 'ibug.tmpl', max_includes => 20,filter => sub {
                            my $ref = shift;
                            ${$ref} = Encode::decode_utf8(${$ref});
          $ref = &whitespace_clean($ref);
                        });

require 'db_connection.pl';
my $dbh=&return_dbh($template);

require 'user_login.pl';
my ($user_identifier,$user_name,$user_access,$etiquetes);
($user_identifier,$user_name,$user_access,$etiquetes,$dbh) = &canasta_login_status($template,$dbh);

$etiquetes = &escape_etiquetes_list($etiquetes);

require 'db_requests.pl';

my ($clause);
my ($etiquetes_number) = 0;
my (%etiquetes_orden,%etiquetes_orden1) = ();


my $empty_canasta = param ("empty_canasta");
if ((defined $empty_canasta) && $user_name) {
  # update DB with empty value
  &add_canasta($user_identifier,0);
}

# prepare %etiquetes_orden filling it with negative or values for lines that should be modified (mod canasta established)
my $mod_canasta = &un(param ("mod_canasta"));
if ((defined $mod_canasta) && $user_name)
{
  $mod_canasta = &escape_etiquetes_list($mod_canasta);
  my @unit_list = &parse_unit_list($mod_canasta);
  foreach my $unit_pair (@unit_list) {
    my ($unit_id,$identification_id,$number,$specimen_id) = &parse_unit_pairs($unit_pair);
    if (defined $specimen_id) {
      $etiquetes_orden{$unit_id}{$identification_id}{$specimen_id} += $number;
    } else {
      $etiquetes_orden1{$unit_id}{$identification_id} += $number;
    }
  }
};

if ((defined $etiquetes) && $user_name && !(defined $empty_canasta)) {
  my @unit_list = &parse_unit_list($etiquetes);
  foreach my $unit_pair (@unit_list) {
    # first we need to record number of each etiquete type
    my ($unit_id,$identification_id,$number,$specimen_id) = &parse_unit_pairs($unit_pair);
    if (defined $specimen_id) {
      $etiquetes_orden{$unit_id}{$identification_id}{$specimen_id} += $number;
    } else {
      $etiquetes_orden1{$unit_id}{$identification_id} += $number;
    }
  }
  foreach my $unit_pair (@unit_list) {
    my ($unit_id,$identification_id,$number,$specimen_id) = &parse_unit_pairs($unit_pair);
    if ((defined $specimen_id) && (defined $etiquetes_orden{$unit_id}{$identification_id}{$specimen_id}) && ($etiquetes_orden{$unit_id}{$identification_id}{$specimen_id} > 0)) {
      # here appear error that we put several times same $clause parameters
        $clause .= "(unit.unit_id = '$unit_id' AND identification.identification_id = '$identification_id' AND specimen.specimen_id = '$specimen_id') OR ";
        # here appear error that we put several times max value for group
    } elsif ((defined $etiquetes_orden1{$unit_id}{$identification_id}) && ($etiquetes_orden1{$unit_id}{$identification_id} > 0)) {
        $clause .= "(unit.unit_id = '$unit_id' AND identification.identification_id = '$identification_id') OR ";
        # here appear error that we put several times max value for group
    }
  }
  if ($clause) {
    $clause =~ s/OR\s$//i;
    $clause = "(" . $clause . ") AND ";
  } else {
    # seems that there should be no data, so updating DB
    $clause = "";
    &add_canasta($user_identifier,0);
  }
}

# ===================================================================================================================================

if ((defined $clause) && $clause) {
  my @main_list_ref = &canasta_main_list($clause,$template,$dbh);

    if (scalar @main_list_ref) # checks if we have at least one value in result array
    {
      # if we have something in array
      my @main_list = ();
      foreach my $main_ref (@main_list_ref) 
      {
        my %main = ();
  if (defined $$main_ref->{unit_id} && defined $$main_ref->{identification_id} && defined $etiquetes_orden{$$main_ref->{unit_id}}{$$main_ref->{identification_id}}{$$main_ref->{specimen_id}}) {
          $main{ETIQUETES_NUMBER} =  $etiquetes_orden{$$main_ref->{unit_id}}{$$main_ref->{identification_id}}{$$main_ref->{specimen_id}};
    $etiquetes_number += $etiquetes_orden{$$main_ref->{unit_id}}{$$main_ref->{identification_id}}{$$main_ref->{specimen_id}};
    $etiquetes_new .= $$main_ref->{unit_id} . "b" . $$main_ref->{identification_id}. "b" . $etiquetes_orden{$$main_ref->{unit_id}}{$$main_ref->{identification_id}}{$$main_ref->{specimen_id}} . "b" . $$main_ref->{specimen_id} . "a";
    $main{SPECIMEN_DEFINED} = 1;
        } elsif (defined $$main_ref->{unit_id} && defined $$main_ref->{identification_id} && defined $etiquetes_orden1{$$main_ref->{unit_id}}{$$main_ref->{identification_id}}) {
          $main{ETIQUETES_NUMBER} =  $etiquetes_orden1{$$main_ref->{unit_id}}{$$main_ref->{identification_id}};
    $etiquetes_number += $etiquetes_orden1{$$main_ref->{unit_id}}{$$main_ref->{identification_id}};
    $etiquetes_new .= $$main_ref->{unit_id} . "b" . $$main_ref->{identification_id}. "b" . $etiquetes_orden1{$$main_ref->{unit_id}}{$$main_ref->{identification_id}} . "a";
  };
 
  if (defined $$main_ref->{unit_id}) {
          $main{UNIT_ID} = escapeHTML(&un($$main_ref->{unit_id}));
        };
  if (defined $$main_ref->{specimen_id}) {
          $main{SPECIMEN_ID} = escapeHTML(&un($$main_ref->{specimen_id}));
        };
        if (defined $$main_ref->{identification_id}) {
          $main{IDENTIFICATION_ID} = escapeHTML(&un($$main_ref->{identification_id}));
        };

        if (defined $$main_ref->{genus_id}) 
        {
          # if genus_id is defined than we can output all related to preferred identification
          $main{GENUS} = escapeHTML(&un(&get_genus($$main_ref->{genus_id},$template,$dbh)));
          if (defined $$main_ref->{specie}) {
            $main{SPECIE} = escapeHTML(&un($$main_ref->{specie}));
          } else {
            $main{SPECIE} = &messages('8003');
          };
          if (defined $$main_ref->{author_id} && (!defined $$main_ref->{infraspecific_epithet})) 
          {
            $main{AUTHOR} = escapeHTML(&un(&get_author($$main_ref->{author_id},$template,$dbh)));
          };
          if (defined $$main_ref->{name_addendum}) 
          {
            $main{NAME_ADDENDUM} = escapeHTML(&un($$main_ref->{name_addendum}));
          };
          if (defined $$main_ref->{identification_cualifier}) 
          {
            $main{IDENTIFICATION_CUALIFIER} = escapeHTML(&un($$main_ref->{identification_cualifier}));
          };
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
          if (defined $$main_ref->{hybrid_specie}) {
            $main{HYBFID_SPECIE} = escapeHTML(&un($$main_ref->{hybrid_specie}));
            if (defined $$main_ref->{hybrid_genus_id}) {
              $main{HYBRID_GENUS} = escapeHTML(&un(&get_genus($$main_ref->{hybrid_genus_id},$template,$dbh)));
            };
            if (defined $$main_ref->{hybrid_flag}) {
              $main{HYBRID_FLAG} = escapeHTML(&un($$main_ref->{hybrid_flag}));
            } else {
              $main{HYBRID_FLAG} = 'x';
            };
            if (defined $$main_ref->{hybrid_author_id}) {
              $main{HYBRID_AUTHOR} = escapeHTML(&un(&get_author($$main_ref->{hybrid_author_id},$template,$dbh)));
            };
          };
          if (defined $$main_ref->{genus_id}) {
            $main{FAMILIA} = escapeHTML(&un(&get_family($$main_ref->{genus_id},$template,$dbh)));
          };
        } else {
          # if genus is not defined than we have nothing to do with identification
        };
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
          };
        }
        if (defined $$main_ref->{municipality_id}) 
        {
    my ($munic,$state,$country) = &get_municipality($$main_ref->{municipality_id},$template,$dbh);
    ($main{MUNICIPALITY},$main{STATE},$main{COUNTRY}) = (&un($munic),&un($state),&un($country));
        };
  if (defined $$main_ref->{herbarium_abbreviation}) 
        {
    $main{HERBARIUM_ABBREVIATION} = escapeHTML(&un($$main_ref->{herbarium_abbreviation}));
        };
  if (defined $$main_ref->{type_status}) 
        {
    $main{TYPE_STATUS} = escapeHTML(&un("\u$$main_ref->{type_status}"));
        };
  if (defined $$main_ref->{herbarium_number}) 
        {
    $main{HERBARIUM_NUMBER} = escapeHTML(&un($$main_ref->{herbarium_number}));
        };  

        push(@main_list, \%main);
      };
      $template->param(MAIN_LIST => \@main_list);
      
      # check if etiquete order line is ordened and actualized, if not - rewrite
    if ($etiquetes_new) {
    $etiquetes_new =~ s/a$//i;
  }
  if (!($etiquetes eq $etiquetes_new) && (defined $user_name)) {
    &add_canasta($user_identifier,$etiquetes_new);
  }
  
    } else {
      # if we have empty array
      $template->param(
    NO_MATCH => 1,
  );
    };
}

&disconnect_dbh($dbh,$template);



  $template->param(
    PAGE_TITLE => &messages('9014'),
    CANASTA_CONTENTS => 1,
    IMPRIMIR_ETIQUETES => $etiquetes,
    ETIQUETES_NUMBER => escapeHTML($etiquetes_number),
  );

# page output

print "Content-type: text/html; charset=utf-8\n\n";
binmode STDOUT, ":utf8";
print $template->output;

exit (0);


# ===================================================================================================================================

sub add_canasta {
  # sub to add etiquetes substrings to canasta (field in tacle lodin in DB)
  my ($user_identifier,$etiquetes) = @_;
  my $sth_1;
  if ($etiquetes) {
    $sth_1 = $dbh->prepare (qq{
      UPDATE login SET etiquetes_ordened = '$etiquetes' 
      WHERE user_identifier = '$user_identifier'
    }) or &sql_error_out(&messages('1021'),$template);
  } else {
    $sth_1 = $dbh->prepare (qq{
      UPDATE login SET etiquetes_ordened = NULL 
      WHERE user_identifier = '$user_identifier'
    }) or &sql_error_out(&messages('1021'),$template);
  }
  $sth_1->execute()  or &sql_error_out(&messages('1022'),$template);
  $sth_1->finish() or &sql_error_out(&messages('1023'),$template);
 }




