#!/usr/bin/perl -w

# ibug_unit.cgi - to make request and output of unit associated data
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


my $template = HTML::Template->new(filename => 'ibug.tmpl', max_includes => 20,filter => sub {
                            my $ref = shift;
                            ${$ref} = Encode::decode_utf8(${$ref});
          $ref = &whitespace_clean($ref);
                        });

require 'db_connection.pl';
my $dbh=&return_dbh($template);

require 'user_login.pl';
my ($user_identifier,$user_name,$user_access,$etiquetes);
(undef,$user_identifier,$user_name,$user_access,$etiquetes,$dbh) = &login_status($template,$dbh);

require 'db_requests.pl';

my $etiquetes_number = &etiquetes_number($etiquetes);

# == Canasta processing ============================================================================================================================= 
my $add_canasta = param ("add_canasta");
if ((defined $add_canasta) && (defined $user_name))
{
  $add_canasta = &escape_etiquetes_list($add_canasta);
  $add_canasta =~ /^\d+b\d+b(\d+)b?\d*$/i;
  $etiquetes_number += $1;
  my (undef,$user_name,$user_access,$etiquetes) = &get_user_login($user_identifier,$template,$dbh);   # gen username from user identifier using DB
   if (defined $user_name)
  {
    if (defined $etiquetes) {
      # there are some new etiquetes added to previous
      $etiquetes .= "a" . $add_canasta;
    } else {
      $etiquetes = $add_canasta;
    }
    &add_canasta($user_identifier,$etiquetes);
    $template->param(
      CANASTA => 1,
    );
  } 
};
# == End of Canasta processing ====================================================================================================================== 

# value to look for in unit_id
my $unit_id = &un(param ("unit_id"));
my $identification_id = &un(param ("identification_id"));

my $count = 0;  # number of entries printed so far
my $main_identification_id = ();
my ($clause,$user_id_creation,$date_creation) = (); # $user_id_creation & $date_creation - user table creator data
my (%record_modifications) = (); # hash for dataset modifications control (should be global)

# generating of SQL elements to search for

if (defined $unit_id) 
{
  $unit_id = &escape_numeric_input($unit_id);
  $clause .= "unit.unit_id = " . $dbh->quote($unit_id) . " AND\n";
}

if (defined $identification_id) 
{
  $identification_id = &escape_numeric_input($identification_id);
  $clause .= "identification.identification_id = " . $dbh->quote($identification_id) . " AND\n";  
}

if ($clause) 
{
  my @unit_list_ref = &search_unit_list($clause,$template,$dbh);
  my $matches = scalar @unit_list_ref;
  if ($matches > 1)
  {
    # warning message for the reason that we have unexpected matching, only one record normallu could match each request
    my $warning = "<br />". &messages('1030');
    $template->param(WARNING => &un($warning));
  }
    # processing of main query results, if we have a list of results, than only first value is processed
  # =============== main querry results ===================================================
  my $entity_ref = shift @unit_list_ref;
  if ($entity_ref) 
  {
    $main_identification_id = $$entity_ref->{identification_id}; # id of main identification to exclude from list of alternative identifications
    # Taxon & identifier with preferred identification or principal identification
    if (defined $$entity_ref->{preferred_flag}) 
    {
      $template->param(PREFERRED_FLAG => &un($$entity_ref->{preferred_flag}));  
    }
    if (defined $$entity_ref->{subgeneric_id}) 
    {
      $template->param(SUBGENERIC_ID => &un($$entity_ref->{subgeneric_id}));
#========= status list ==============================================================
    my @status_list_ref = &status_list($$entity_ref->{subgeneric_id},$template,$dbh); 
    if (scalar @status_list_ref) # checks if we have at least one reference
    {
      my @status_list = ();
      foreach my $status_ref (@status_list_ref) 
      {
        my %status = ();
        $status{SUBGENERIC_ID} = escapeHTML(&un($$entity_ref->{subgeneric_id}));
        if (defined $$status_ref->{pubid}) 
        {
          $status{PUBID} = escapeHTML(&un($$status_ref->{pubid}));
        }
        if (defined $$status_ref->{status_detail} && defined $$status_ref->{pubabbreviation}) 
        {
          $status{STATUS} = escapeHTML(&un($$status_ref->{status_detail}));
          $status{PUBABBREVIATION} = escapeHTML(&un($$status_ref->{pubabbreviation}));
          if (defined $$status_ref->{pubdate}) 
          {
            $status{PUBDATE} = escapeHTML(&un($$status_ref->{pubdate}));
          }
        }
        if (defined $$status_ref->{comment}) 
        {
          $status{STATUS_COMMENT} = escapeHTML(&un($$status_ref->{comment}));
        }
        push(@status_list, \%status);
      }
      $template->param(STATUS_LIST => \@status_list);
    }
#=========== end of status list ============================================================
    }
    if (defined $$entity_ref->{genus_id}) 
    {
      $template->param(GENUS => escapeHTML(&un(&get_genus($$entity_ref->{genus_id},$template,$dbh))));
      $template->param(FAMILY => escapeHTML(&un(&get_family($$entity_ref->{genus_id},$template,$dbh))));
    }
    else 
    {
      $template->param(GENUS => &messages('8001'),);
    }
    if (defined $$entity_ref->{specie}) 
    {
      $template->param(SPECIE => escapeHTML(&un($$entity_ref->{specie})));
    }
    else 
    {
      $template->param(SPECIE => &messages('8003'),)
    }
    if ((defined $$entity_ref->{author_id}) && (!defined $$entity_ref->{infraspecific_epithet})) 
    {
  # specie author if there is no infraspecific author, othercase decision depending on infraspecific epithet
      $template->param(AUTHOR => escapeHTML(&un(&get_author($$entity_ref->{author_id},$template,$dbh))));
    }
    if (defined $$entity_ref->{name_addendum}) 
    {
      $template->param(NAME_ADDENDUM => escapeHTML(&un($$entity_ref->{name_addendum})));
    }
    if (defined $$entity_ref->{identification_cualifier}) 
    {
      $template->param(IDENTIFICATION_CUALIFIER => escapeHTML(&un($$entity_ref->{identification_cualifier})));
    }
    if (defined $$entity_ref->{infraspecific_epithet}) 
    {
      # Infraspecific output
      $template->param(INFRASPECIFIC => '1');
      $template->param(INFRASPECIFIC_EPITHET => escapeHTML(&un($$entity_ref->{infraspecific_epithet})));
      if (defined $$entity_ref->{specie} && ($$entity_ref->{specie} eq $$entity_ref->{infraspecific_epithet}))
      {
    # no infraspecific author, but specie author
    if ((defined $$entity_ref->{author_id})) 
    {
      $template->param(AUTHOR => escapeHTML(&un(&get_author($$entity_ref->{author_id},$template,$dbh))));
    } elsif ((defined $$entity_ref->{infraspecific_author_id}))
    {
      # correcting error if no specie author, but infraspecific author only is defined
      $template->param(AUTHOR => escapeHTML(&un(&get_author($$entity_ref->{infraspecific_author_id},$template,$dbh))));
    }
      }
      else
      {
    if (defined $$entity_ref->{infraspecific_author_id}) 
    {
      $template->param(INFRASPECIFIC_AUTHOR => escapeHTML(&un(&get_author($$entity_ref->{infraspecific_author_id},$template,$dbh))));
    }
      }
      if (defined $$entity_ref->{infraspecific_flag}) 
      {
        $template->param(INFRASPECIFIC_FLAG => escapeHTML(&un($$entity_ref->{infraspecific_flag})));
      }
    }
    if (defined $$entity_ref->{hybrid_genus_id}) 
    {
      # Hybrid specie output
      $template->param(HYBRID => '1');
      if (defined $$entity_ref->{hybrid_flag}) 
      {
        $template->param(HYBRID_FLAG => escapeHTML(&un($$entity_ref->{hybrid_flag})));
      }
      else
      {
        $template->param(HYBRID_FLAG => 'x');
      }
      if (defined $$entity_ref->{hybrid_genus_id}) 
      {
        $template->param(HYBRID_GENUS => escapeHTML(&un(&get_genus($$entity_ref->{hybrid_genus_id},$template,$dbh))));
        $template->param(HYBRID_FAMILY => escapeHTML(&un(&get_family($$entity_ref->{hybrid_genus_id},$template,$dbh))));
      }
      else
      {
        $template->param(HYBRID_GENUS => &messages('8001'),);
      }
      if (defined $$entity_ref->{hybrid_specie}) 
      {
        $template->param(HYBRID_SPECIE => escapeHTML(&un($$entity_ref->{hybrid_specie})));
      } 
      else
      {
        $template->param(HYBRID_SPECIE => &messages('8003'),)
      }
      if (defined $$entity_ref->{hybrid_author_id}) 
      {
        $template->param(HYBRID_AUTHOR => escapeHTML(&un(&get_author($$entity_ref->{hybrid_author_id},$template,$dbh))));
      }
    }
    if (defined $$entity_ref->{identifier_id}) 
    {
      # Identifier relaed data
      if ((defined $$entity_ref->{identifier_id}) && ($$entity_ref->{identifier_id} ne 1))
      {
        $template->param(IDENTIFIER => escapeHTML(&un(&get_agent($$entity_ref->{identifier_id},$template,$dbh))));
      }
      else 
      {
        $template->param(IDENTIFIER => &messages('8004'),);
      }
      if (defined $$entity_ref->{identification_date}) 
      {
        $template->param(IDENTIFICATION_DATE => escapeHTML(&un(&format_date($$entity_ref->{identification_date}))));
      }
      if (defined $$entity_ref->{identifier_role}) 
      {
        $template->param(IDENTIFIER_ROLE => escapeHTML(ucfirst(&un($$entity_ref->{identifier_role}))));
      }
      else 
      {
        $template->param(IDENTIFIER_ROLE => &messages('8005'),);
      }
    }
    if (defined $$entity_ref->{database_id}) 
    {
       $template->param(DATABASE => escapeHTML(&un(&get_database($$entity_ref->{database_id},$template,$dbh))));
    }
    if (defined $$entity_ref->{unit_identifier}) 
    {
      $template->param(UNIT_IDENTIFIER => escapeHTML(&un($$entity_ref->{unit_identifier})));
    }
    if (defined $$entity_ref->{unit_universal_identifier}) 
    {
      $template->param(UNIT_UNIVERSAL_IDENTIFIER => escapeHTML(&un($$entity_ref->{unit_universal_identifier})));
    }
    if (defined $$entity_ref->{record_base}) 
    {
      $template->param(RECORD_BASE => escapeHTML(&un($$entity_ref->{record_base})));
    }
    if ((defined $$entity_ref->{collector_id}) && ($$entity_ref->{collector_id} ne 1)) 
    {
      $template->param(COLLECTOR => escapeHTML(&un(&get_agent($$entity_ref->{collector_id},$template,$dbh))));
    }
    else 
    {
      $template->param(COLLECTOR => &messages('8006'),);
    }
    if (defined $$entity_ref->{collector_field_number}) 
    {
      $template->param(COLLECTOR_FIELD_NUMBER => escapeHTML(&un($$entity_ref->{collector_field_number})));
    }
    else 
    { 
      if ($$entity_ref->{collector_id} ne 1) 
      {
        $template->param(COLLECTOR_FIELD_NUMBER => &messages('8007'),);
      }
    }
    if (defined $$entity_ref->{collecting_date}) 
    {
      $template->param(COLLECTING_DATE => escapeHTML(&un(&format_date($$entity_ref->{collecting_date}))));
    }
    if (defined $$entity_ref->{project_id}) 
    {
      $template->param(PROJECT => escapeHTML(&un(&get_project($$entity_ref->{project_id},$template,$dbh))));
    }
    if (defined $$entity_ref->{municipality_id}) 
    {
      my ($municipality,$state,$country) = &get_municipality($$entity_ref->{municipality_id},$template,$dbh);
      $template->param(MUNICIPALITY => escapeHTML(&un($municipality)));
      $template->param(STATE => escapeHTML(&un($state)));
      $template->param(COUNTRY => escapeHTML(&un($country)));
    }
    if (defined $$entity_ref->{locality}) 
    {
      $template->param(LOCALITY => escapeHTML(&un($$entity_ref->{locality})));
    }
    if (defined $$entity_ref->{altitude}) 
    {
      my $altitude = $$entity_ref->{altitude}.' m';
      $template->param(ALTITUDE => escapeHTML(&un($altitude)));
    }
    if ((defined $$entity_ref->{latitude}) && (defined $$entity_ref->{longitude})) 
    {
      # Coordinates processing
      my ($latitude, $longitude, $sign) = ();
      ($latitude,$sign) = &deg2sec($$entity_ref->{latitude});
      if ($sign eq "-" ) {$latitude .= "S";} else {$latitude .= "N";};
      ($longitude,$sign) = &deg2sec($$entity_ref->{longitude});
      if ($sign eq "-" ) {$longitude .= "W";} else {$longitude .= "E";};
      $template->param(COORDINATES => 1);
      $template->param(LATITUDE => escapeHTML(&un($latitude)));
      $template->param(LONGITUDE => escapeHTML(&un($longitude)));
    }
    if ((defined $$entity_ref->{microhabitat}) || (defined $$entity_ref->{vegetation_type_id})) 
    {
      # Ecology related data
      $template->param(ECOLOGY => 1);
      if (defined $$entity_ref->{microhabitat}) 
      {
        $template->param(MICROHABITAT => escapeHTML(&un($$entity_ref->{microhabitat})));
      }
      if (defined $$entity_ref->{vegetation_type_id}) 
      {
        $template->param(VEGETATION => escapeHTML(&un(&get_vegetation($$entity_ref->{vegetation_type_id},$template,$dbh))));
      }
    } 
    if ((defined $$entity_ref->{observations_plant_common_name}) || (defined $$entity_ref->{observations_plant_use})) 
    {
      # Etnobotany related data (should be rewritten - observations and etnobotanical data will appear as separate tables)
      $template->param(ETNOBOTANY => 1);
      if (defined $$entity_ref->{observations_plant_use}) 
      {
        $template->param(OBSERVATIONS_PLANT_USE => escapeHTML(&un($$entity_ref->{observations_plant_use})));
      }
      if (defined $$entity_ref->{observations_plant_common_name}) 
      {
        $template->param(OBSERVATIONS_PLANT_COMMON_NAME => escapeHTML(&un($$entity_ref->{observations_plant_common_name})));
      }
    }
      # Observations related data (should be rewritten - observations and etnobotanical data will appear as separate tables)
    if (defined $$entity_ref->{observations_plant_lifeform}) 
    {
      $template->param(OBSERVATIONS_PLANT_LIFEFORM => escapeHTML(&un($$entity_ref->{observations_plant_lifeform})));
    }
    if (defined $$entity_ref->{observations_plant_size}) 
    {
      $template->param(OBSERVATIONS_PLANT_SIZE => escapeHTML(&un($$entity_ref->{observations_plant_size})));
    }
    if (defined $$entity_ref->{observations_plant_longevity}) 
    {
      $template->param(OBSERVATIONS_PLANT_LONGEVITY => escapeHTML(&un($$entity_ref->{observations_plant_longevity})));
    }
    if (defined $$entity_ref->{observations_plant_abundance}) 
    {
      $template->param(OBSERVATIONS_PLANT_ABUNDANCE => escapeHTML(&un($$entity_ref->{observations_plant_abundance})));
    }
    if (defined $$entity_ref->{observations_plant_fenology}) 
    {
      $template->param(OBSERVATIONS_PLANT_FENOLOGY => escapeHTML(&un($$entity_ref->{observations_plant_fenology})));
    }
    if (defined $$entity_ref->{observations_plant_nutrition}) 
    {
      $template->param(OBSERVATIONS_PLANT_NUTRITION => escapeHTML(&un($$entity_ref->{observations_plant_nutrition})));
    }
    if (defined $$entity_ref->{comment} || defined $$entity_ref->{identification_comment}) 
    {
      my $comment = '';
      if (defined $$entity_ref->{comment}) { $comment .= $$entity_ref->{comment}; };
      if (defined $$entity_ref->{identification_comment}) { $comment .= " ". $$entity_ref->{identification_comment}; };
      $template->param(COMMENT => escapeHTML(&un(scalar &trim($comment))));
    }
    
  
    # process data related to record origin and modification
    if ((defined $$entity_ref->{user_id_creation}) && (defined $$entity_ref->{date_creation})) 
    {
      $record_modifications{$$entity_ref->{user_id_creation}} = $$entity_ref->{date_creation};
      $user_id_creation = $$entity_ref->{user_id_creation};
      $date_creation = $$entity_ref->{date_creation};
    } 
    &record_modifications($entity_ref,'user_id','date_mod');
    &record_modifications($entity_ref,'ident_user_id_creation','ident_date_creation');
  }
  # =============== end of main querry results ===================================================
  
  if ($matches > 0) # if result of main unit query was positive we need to get some additional things from datbase
  {

    # =============== references list ===================================================     
    # request and output of references
    # loop structure should be used in template
    my @reference_list_ref = &reference_list($unit_id,$template,$dbh); 
    
    
    # bibliographyc references related code (should be rewritten, due to the fact that references coud be associated to records directly, they are not exceptionaly related to identification process)
    # it should be list of references instead
    if (defined $$entity_ref->{reference_id}) 
    {
#      $template->param(REFERENCE => 1);
      my ($reference_string,undef,undef,undef,undef) = &get_reference($$entity_ref->{reference_id},$template,$dbh);
    $reference_string = $reference_string . ' - ' . &messages('3013');
      my $reference_identification = {reference => $reference_string,};
      push (@reference_list_ref, \$reference_identification)
    }    
    
    
    if (scalar @reference_list_ref) # checks if we have at least one reference
    {
      my @reference_list = ();
      foreach my $reference_ref (@reference_list_ref) 
      {
        my %reference = ();
        $reference{UNIT_ID} = escapeHTML(&un($unit_id));
        $reference{IDENTIFICATION_ID} = escapeHTML(&un($main_identification_id));
        if (defined $$reference_ref->{reference}) 
        {
          $reference{REFERENCE} = escapeHTML(&un($$reference_ref->{reference}));
        }
        if (defined $$reference_ref->{comment}) 
        {
          $reference{REFERENCE_COMMENT} = escapeHTML(&un($$reference_ref->{comment}));
        }
        push(@reference_list, \%reference);
      }
      $template->param(REFERENCES_LIST => \@reference_list);
    }
    # =============== end of references list =================================================== 
    
    # =============== named areas list ===================================================     
    # request and output of named areas
    # loop structure should be used in template
    my @areas_list_ref = &areas_list($unit_id,$template,$dbh); 
    if (scalar @areas_list_ref) # checks if we have at least one named area
    {
      my @areas_list = ();
      foreach my $area_ref (@areas_list_ref) 
      {
        my %area = ();
        $area{UNIT_ID} = escapeHTML(&un($unit_id));
        $area{IDENTIFICATION_ID} = escapeHTML(&un($main_identification_id));
        if (defined $$area_ref->{named_area}) 
        {
          $area{AREA} = escapeHTML(&un($$area_ref->{named_area}));
        }
        if (defined $$area_ref->{named_area_type}) 
        {
          $area{AREA_TYPE} = escapeHTML(&un($$area_ref->{named_area_type}));
        }
        if (defined $$area_ref->{comment}) 
        {
          $area{AREA_COMMENT} = escapeHTML(&un($$area_ref->{comment}));
        }
        push(@areas_list, \%area);
      }
      $template->param(AREAS_LIST => \@areas_list);
    }
    # =============== end of named areas list =================================================== 
        
    # =============== specimens list ===================================================
    # request and output of specimen list
    # loop structure should be used
    my @specimen_list_ref = &specimen_list($unit_id,$template,$dbh); 
    if (scalar @specimen_list_ref) # checks if we have at least one specimen
    {
      my @specimen_list = ();
      foreach my $specimen_ref (@specimen_list_ref) 
      {
        my %specimen = ();
        $specimen{UNIT_ID} = escapeHTML(&un($unit_id));
        $specimen{IDENTIFICATION_ID} = escapeHTML(&un($main_identification_id));
        if (defined $user_name) {
          $specimen{USER_LOGIN} = 1;
        }
        if (defined $user_access && ($user_access eq 'curador')) {
          $specimen{CURADOR} = 1;
        }       
        if (defined $$specimen_ref->{specimen_id}) 
        {
          $specimen{SPECIMEN_ID} = escapeHTML(&un($$specimen_ref->{specimen_id}));
        }
        if (defined $$specimen_ref->{herbarium_abbreviation}) 
        {
          $specimen{HERBARIUM_ABBREVIATION} = escapeHTML(&un($$specimen_ref->{herbarium_abbreviation}));
          $template->param(SPECIMEN_LIST => 1);
        }
        if (defined $$specimen_ref->{herbarium_number}) 
        {
          $specimen{HERBARIUM_NUMBER} = escapeHTML(&un($$specimen_ref->{herbarium_number}));
        }
        if (defined $$specimen_ref->{type_status}) 
        {
          $specimen{TYPE_STATUS} = escapeHTML(&un($$specimen_ref->{type_status}));
          $template->param(SPECIMEN_LIST => 1);
        }
        if (defined $$specimen_ref->{comment}) 
        {
          $specimen{SPECIMEN_COMMENT} = escapeHTML(&un($$specimen_ref->{comment}));
        }
        &record_modifications($specimen_ref,'user_id_creation','date_creation');
        # ========================= specie image related code ==============================================================
        # specie image related code - late it is necessary to add request that returns collectoe id & etc. data
        # add check of file existence, add check of number of images; 
        # loop structure should be used in template
        my @specimen_image_list_ref = &specimen_image_list($$specimen_ref->{specimen_id},$template,$dbh);
        if (scalar @specimen_image_list_ref) 
        {
          my @specimen_image_list = ();
          foreach my $specimen_image_ref (@specimen_image_list_ref)
          {
            my %specimen_image = ();
            # specimen_id, specimen_image_id - to add in template with purpose to output web page instead of picture on href
            # as well later add type specimen identifications output
            if (defined $$specimen_image_ref->{herbarium_abbreviation}) 
            {
              $specimen_image{HERBARIUM_ABBREVIATION} = escapeHTML(&un($$specimen_image_ref->{herbarium_abbreviation}));
            }
            if (defined $$specimen_image_ref->{herbarium_number}) 
            {
              $specimen_image{HERBARIUM_NUMBER} = escapeHTML(&un($$specimen_image_ref->{herbarium_number}));
            }
            if (defined $$specimen_image_ref->{type_status}) 
            {
              $specimen_image{TYPE_STATUS} = escapeHTML(&un($$specimen_image_ref->{type_status}));
            }
            if (defined $$specimen_image_ref->{comment}) 
            {
              $specimen_image{COMMENT} = escapeHTML(&un($$specimen_image_ref->{comment}));
            }
            if (defined $$specimen_image_ref->{specimen_comment}) 
            {
              $specimen_image{SPECIMEN_COMMENT} = escapeHTML(&un($$specimen_image_ref->{specimen_comment}));
            }
            if (defined $$specimen_image_ref->{imagen}) 
            {
              if (-e &paths('R005').$$specimen_image_ref->{imagen}.".jpg") 
              {
                $specimen_image{FULL_IMAGE} = &paths('R002') . $$specimen_image_ref->{imagen} . ".jpg";
              }
              if (-e &paths('R006').$$specimen_image_ref->{imagen}.".jpg") 
              {
                $specimen_image{LORES_IMAGE} = &paths('R003') . $$specimen_image_ref->{imagen} . ".jpg";
              }
              if (-e &paths('R007').$$specimen_image_ref->{imagen}.".png") 
              {
                $specimen_image{THUMB_IMAGE} = &paths('R004') . $$specimen_image_ref->{imagen} . ".png";
              }
            }
            &record_modifications($specimen_image_ref,'user_id_creation','date_creation');
            push(@specimen_image_list, \%specimen_image);
          }
          $specimen{SPECIMEN_IMAGE} =  \@specimen_image_list;
        }
        # ========================= end of specie image related code ==============================================================
        push(@specimen_list, \%specimen);
      }
      $template->param(SPECIMEN => \@specimen_list);
    }
    # =============== end of specimens list ===================================================
    
    # ============== alternative identifications list ========================================================
    # request and output of alternative identifications list (excepting identification already present in main unit querry results, identified by $main_identification_id)
    # loop structure should be used in template
    my @identification_list_ref = &identification_list($unit_id,$main_identification_id,$template,$dbh); 
    if (scalar @identification_list_ref) # checks if we have at least one alternaive identification
    {
      my @identification_list = ();
      foreach my $identification_ref (@identification_list_ref) 
      {
        my %identification = ();
        if (defined $$identification_ref->{unit_id}) 
        {
          $identification{ALT_UNIT_ID} = escapeHTML(&un($$identification_ref->{unit_id}));
        }
        if (defined $$identification_ref->{identification_id}) 
        {
          $identification{ALT_IDENTIFICATION_ID} = escapeHTML(&un($$identification_ref->{identification_id}));
        }
        if (defined $$identification_ref->{preferred_flag}) 
        {
          $identification{ALT_PREFERRED_FLAG} = escapeHTML(&un($$identification_ref->{preferred_flag}));
        }
        if (defined $$identification_ref->{subgeneric_id}) 
        {
          $identification{ALT_SUBGENERIC_ID} = escapeHTML(&un($$identification_ref->{subgeneric_id}));
        }
        if (defined $$identification_ref->{non_flag}) 
        {
          $identification{ALT_NON_FLAG} = escapeHTML(&un($$identification_ref->{non_flag}));
        }
#        if (defined $$identification_ref->{type_identification_flag})   # should be changed due to removing of type_identification_field from identifications table
#        {
#          $identification{ALT_TYPE} = escapeHTML(&un($$identification_ref->{type_identificaton_flag}));
#        }
        if (defined $$identification_ref->{stored_under_flag}) 
        {
          $identification{ALT_STORED_UNDER} = escapeHTML(&un($$identification_ref->{stored_under_flag}));
        }
        if (defined $$identification_ref->{genus_id}) 
        {
          $identification{ALT_GENUS} = escapeHTML(&un(&get_genus($$identification_ref->{genus_id},$template,$dbh)));
          if (defined $$identification_ref->{name_addendum}) 
          {
            $template->param(NAME_ADDENDUM => escapeHTML(&un($$identification_ref->{name_addendum})));
          }
          if (defined $$identification_ref->{identification_cualifier}) 
          {
            $template->param(IDENTIFICATION_CUALIFIER => escapeHTML(&un($$identification_ref->{identification_cualifier})));
          }
        }
        if (defined $$identification_ref->{specie}) 
        {
          $identification{ALT_SPECIE} = escapeHTML(&un($$identification_ref->{specie}));
        } 
        else 
        {
          $identification{ALT_SPECIE} = &messages('8003');
        }
        if (defined $$identification_ref->{author_id}) 
        {
          $identification{ALT_AUTHOR} = escapeHTML(&un(&get_author($$identification_ref->{author_id},$template,$dbh)));
        }
        if (defined $$identification_ref->{infraspecific_epithet}) 
        {
          $identification{ALT_INFRASPECIFIC_EPITHET} = escapeHTML(&un($$identification_ref->{infraspecific_epithet}));
          if (defined $$identification_ref->{infraspecific_flag}) 
          {
            $identification{ALT_INFRASPECIFIC_FLAG} = escapeHTML($$identification_ref->{infraspecific_flag});
          }
          if (defined $$identification_ref->{infraspecific_author_id}) 
          {
            $identification{ALT_INFRASPECIFIC_AUTHOR} = escapeHTML(&un(&get_author($$identification_ref->{infraspecific_author_id},$template,$dbh)));
          }
        }
        if (defined $$identification_ref->{hybrid_genus_id}) 
        {
          $identification{ALT_HYBRID_GENUS} = &get_genus(&un($$identification_ref->{hybrid_genus_id},$template,$dbh));
          if (defined $$identification_ref->{hybrid_flag}) 
          {
            $identification{ALT_HYBRID_FLAG} = escapeHTML(&un($$identification_ref->{hybrid_flag}));
          }
          else
          {
            $identification{ALT_HYBRID_FLAG} = 'x';
          }
          if (defined $$identification_ref->{hybrid_specie}) 
          {
            $identification{ALT_HYBRID_SPECIE} = escapeHTML(&un($$identification_ref->{hybrid_specie}));
          }
          else
          {
            $identification{ALT_HYBRID_SPECIE} = &messages('8003');
          }
          if (defined $$identification_ref->{hybrid_author_id}) 
          {
            $identification{ALT_HYBRID_AUTHOR} = escapeHTML(&un(&get_author($$identification_ref->{hybrid_author_id},$template,$dbh)));
          }
        }
        if (defined $$identification_ref->{identifier_id}) 
        {
          $identification{ALT_IDENTIFIER} = escapeHTML(&un(&get_agent($$identification_ref->{identifier_id},$template,$dbh)));
          if (defined $$identification_ref->{identifier_role}) 
          {
            $identification{ALT_ROLE} = escapeHTML(ucfirst(&un($$identification_ref->{identifier_role})));
          }
          else
          {
            $identification{ALT_ROLE} = &messages('8005');
          }
          if (defined $$identification_ref->{identification_date}) 
          {
            $identification{ALT_DATE} = escapeHTML(&un(&format_date($$identification_ref->{identification_date})));
          }
        }
        &record_modifications($identification_ref,'user_id_creation','date_creation');
        push(@identification_list, \%identification);
      }
      $template->param(ALT_IDENTIFICATION => \@identification_list);
    }
    # ==================== end of alternative identifications list ================================================
    
    # ===================== origin and modifications secuence =========================================
    # Output record modifications secuence (accumulative from unit, identification, specimen, specimen_image)
    # record modification should be shown only if it differs from record origin, but this is controlled at tmplate level
    if ((scalar {%record_modifications}) > 0) # in any way we should have at least one value in %record_modifications, related to first creator
    {
      if ((defined $user_id_creation) && ($user_id_creation ne 1)) 
      {
        $template->param(RECORD_CREATOR => escapeHTML(&un(&get_user_name($user_id_creation,$template,$dbh))));
        if (defined $date_creation) 
        {
          if ($date_creation ne '0000-00-00')
          {
            $template->param(RECORD_CREATION_DATE => escapeHTML(&un($date_creation)));
          }
        }
        if (defined $record_modifications{$user_id_creation}) # purge record for creator
        {
          if (
            defined $date_creation    # but first check if it is not later than same user modification date
            && 
            (
              ($date_creation eq '0000-00-00') 
              || 
              (&cmp_date($date_creation,$record_modifications{$user_id_creation}) > 0)
            ) 
            && 
            ($record_modifications{$user_id_creation} ne '0000-00-00')
          ) 
          {
            $template->param(RECORD_CREATION_DATE => escapeHTML(&un(&format_date($record_modifications{$user_id_creation}))));
          }
          delete ($record_modifications{$user_id_creation});
        }
      }
      my @modificators_list = ();
      foreach my $modificator (sort keys %record_modifications) 
      {
        my %modificators = ();
         $modificators{RECORD_MODIFICATOR} = escapeHTML(&un(&get_user_name($modificator,$template,$dbh)));
        if ($record_modifications{$modificator} ne '0000-00-00')
        {
          $modificators{RECORD_MODIFICATION_DATE} = escapeHTML(&un(&format_date($record_modifications{$modificator})));
        }
         push (@modificators_list, \%modificators);
      }
      $template->param(RECORD_MODIFICATION => \@modificators_list);
    }
    # ============== end of origin and modifications secuence  =================================================
  } 
  else 
  {
    # if the main querry result was empty we need to prepare no-match an possybly error messages
    $template->param( NO_MATCH => 1,);
    $main_identification_id = $identification_id; # for output of error
  }

  $template->param(
        PAGE_TITLE => &messages('9006') . ' ' . $unit_id,
        UNIT_ID => $unit_id,
        IDENTIFICATION_ID => $main_identification_id,
        UNIT_OUT => 1,
        UNIT_REQUEST => 0,
        LIST_OUT => 0,
        LIST_REQUEST => 0,
        ETIQUETES_NUMBER => escapeHTML($etiquetes_number),
        );

} 
else 
{
  # if $clause was empty than we need to output unit query form
  $template->param(
      PAGE_TITLE => &messages('9007'),
      UNIT_OUT => 0,
      UNIT_REQUEST => 1,
      LIST_OUT => 0,
      LIST_REQUEST => 0,
      ETIQUETES_NUMBER => escapeHTML($etiquetes_number),
  );
}

&disconnect_dbh($dbh,$template);

# page output
print "Content-type: text/html; charset=utf-8\n\n";
binmode STDOUT, ":utf8";
print $template->output;

exit (0);



sub add_canasta {
  # sub to add etiquetes substrings to canasta (field in tacle lodin in DB)
  my ($user_identifier,$etiquetes) = @_;
  my $sth_1 = $dbh->prepare (qq{
    UPDATE login SET etiquetes_ordened = '$etiquetes' 
    WHERE user_identifier = '$user_identifier'
  }) or &sql_error_out(&messages('1021'),$template);
  $sth_1->execute()  or &sql_error_out(&messages('1022'),$template);
  $sth_1->finish() or &sql_error_out(&messages('1023'),$template);
 }

sub record_modifications {
  # sub to put new records into modification control hash
  my ($dataset,$modificator_id_string,$modification_date_string) = @_;  
  if (
    (defined $$dataset->{$modificator_id_string}) 
    && 
    (defined $$dataset->{$modification_date_string}) 
    && 
    ($$dataset->{$modificator_id_string} ne 1) # user_id 1 is for undefined user
    &&
    ($$dataset->{$modificator_id_string} ne 37)    # user_id 37 is for comon VITEX user, it was used for substitution and should be ommited for modifications records
    && 
    ($$dataset->{$modificator_id_string} ne 45)    # user_id 45 is for comon ReBiOMex user
    &&
    (
      !(exists $record_modifications{$$dataset->{$modificator_id_string}}) # if we have a new user_id at least we'll record it
      || 
      (
        (&cmp_date($record_modifications{$$dataset->{$modificator_id_string}},$$dataset->{$modification_date_string}) < 0)
        && 
        ($record_modifications{$$dataset->{$modificator_id_string}} ne '0000-00-00') # nothing to do with changing existing modifications if date is undefined
      )
    )
  ) 
  # substituting record origin date with modification date for the same user if the modification date is earlier
  {
    $record_modifications{$$dataset->{$modificator_id_string}} = $$dataset->{$modification_date_string};
  }

}