#!/usr/bin/perl -w

# This is the script for pdf etiquetes output, it left unmodified and separate from oter scripts, excepting small ones
# but it should be useful to make seperate string declarations file for pdf elements, like message.pl, to make strings correction much easy. 
# (Specially it is related o hash with declarations of possible herbariums, theorically this could not be a part of code, but should come from 
# somewhere in database... It is not a high priority ask, due to fact that this functionality of pdf output is mostly technical thing, just work at that oment. 
# So modifications Todo.
BEGIN {
    my $base_module_dir = (-d '/home2/rebiomex/perl' ? '/home2/rebiomex/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use locale;
use strict;
use utf8;
use CGI qw (:standard escapeHTML escape);
use PDF::API2;
use DBI;
use Cwd;
use HTML::Template;
use Encode;
use Locale::Recode;
require 'tools.pl';
require 'messages.pl';


# with respwct to this recode - it works, but should be better to leave all in Unicode, just output unicode pdf... Todo.
my  $cd = Locale::Recode->new (from => 'UTF-8', to   => 'ISO-8859-1');

use constant mm => 25.4/72;
use constant in =>    1/72;
use constant pt =>    1;

my $template = HTML::Template->new(filename => 'ibug.tmpl', max_includes => 20,filter => sub {
                            my $ref = shift;
                            ${$ref} = Encode::decode_utf8(${$ref});
          $ref = &whitespace_clean($ref);
                        });

require 'db_connection.pl';
my $dbh=&return_dbh($template);

# user_login is not necessary at that moment, this script get information in read-only mode with default read-only access
#require 'user_login.pl';
#my ($user_id,undef,undef,$access_mode) = &login_status($template,$dbh);
#$dbh=&reconnect_dbh($access_mode,$template,$dbh);

require 'db_requests.pl';
 
my (@result_array, @search_param);

my $unit_list = param ("unit_list");

$unit_list = &escape_etiquetes_list($unit_list);

if (defined $unit_list) {
  my @unit_list = &parse_unit_list($unit_list);
  foreach my $unit_pair (@unit_list) {
    my ($unit_id,$identification_id,$number,$specimen_id) = &parse_unit_pairs($unit_pair);
    if ($number < 1) { $number = 1; };
    push(@search_param, {PARAMETER => 'unit_id', VALUE => escapeHTML($unit_id)});
    push(@search_param, {PARAMETER => 'identification_id', VALUE => escapeHTML($identification_id)});
    push(@search_param, {PARAMETER => 'specimen_id', VALUE => escapeHTML($specimen_id)});
    # processing of each combination of input parameters

    while ($number > 0) { 
      my $result_hash = {
        unit_id => $unit_id,
        identification_id => $identification_id,
        specimen_id => $specimen_id,
        number => $number,
        result => &sql_request($unit_id,$identification_id,$specimen_id)
      };
      push(@result_array, $result_hash);
      $number--;
    }
  }
}

my $param = &parameter_processing(@result_array);

if (defined ${$result_array[0]{result}}->{unit_id}) # at least first element of array should contain request results 
{
  # we have some data to output, so attempt to generate pdf
  my $pdfref = &preparePDF(\$param);
  print "Content-type:application/pdf\n";
  print "Content-disposition: inline; name=etiquete".rand(32768).".pdf\n\n";
  #$pdfref->saveas('E:/perl/cgi-bin/blank.pdf');
  print $pdfref->stringify;
} 
else 
{
  # we have no data to putput so we need to inform about this in html form, as well some errors will appear there aspart of DB interaction
  $template->param(
    PAGE_TITLE => &messages('9009'),
    NO_MATCH => 1,
    SEARCH_PARAM => \@search_param,
  );
  print "Content-type: text/html; charset=utf-8\n\n";
  binmode STDOUT, ":utf8";
  print $template->output;
}

&disconnect_dbh($dbh,$template);
#print "Listo!\n";

exit (0);


sub sql_request {
    # prepare and output etiquete contents from database (request is limited to one element and additionaly it retuns only one element due to shift from result array)
    my $unit_id = shift;
    my $identification_id = shift;
    my $specimen_id = shift;
    my $clause = ();
    my @main_list_ref = ();
    if (defined $unit_id) {
      $clause .= "unit.unit_id = " . $dbh->quote($unit_id) . " AND\n";
    };
    if (defined $identification_id) {
      $clause .= "identification.identification_id = " . $dbh->quote($identification_id) . " AND\n";  
    };
    if (defined $specimen_id) {
      $clause .= "specimen.specimen_id = " . $dbh->quote($specimen_id) . " AND\n";  
    };
    if (defined $clause) { 
      @main_list_ref = &search_etiquetes_list($clause,$template,$dbh);
    }
    if ((scalar @main_list_ref) > 0) {
      return shift @main_list_ref;
    } else { 
      return undef;
    }
}


sub parameter_processing {
# this prepare information to be printed and output hash with parameters
  my @array = @_;
  my ($page,$params) = ();
  
  my %page_groups = (
    1 => {x => 11, y => 178},
    2 => {x => 108, y => 178},
    3 => {x => 11, y => 95},
    4 => {x => 108, y => 95},
    5 => {x => 11, y => 12},
    6 => {x => 108, y => 12},
  );

  # this should be changed to get this information from somewhere in database
  my %fields = (
        IBUG => {
          Header1   => 'UNIVERSIDAD DE GUADALAJARA',
          Header2  => 'Instituto de Botánica, Herbario L. M. Villarreal de Puga',
          Header3 => 'ZAPOPAN, JALISCO, MÉXICO',
        },
        GUADA => {
          Header1   => 'UNIVERSIDAD AUTONOMA DE GUADALAJARA',
          Header2  => '',
          Header3 => 'ZAPOPAN, JALISCO, MÉXICO',
        },
        ZEA => {
          Header1   => 'UNIVERSIDAD DE GUADALAJARA',
          Header2  => 'Centro Universitario de la Costa Sur ',
          Header3 => 'AUTLÁN DE NAVARRO, JALISCO, MÉXICO',
        },
        MEXU => {
          Header1   => 'UNIVERSIDAD NACIONAL AUTONOMA DE MÉXICO',
          Header2  => 'Instituto de Biología',
          Header3 => 'D. F., MÉXICO',
        },
        N_D => {
          Header1   => 'HERBARIO SIN DEFINIR',
          Header2  => '',
          Header3 => '',
        },
  );

  my $page_counter = 0;
  my $item_counter = 0;
  my $item_total_counter = 0;

  foreach my $item (@array) {
    # working with individual results from list
    
    $item_counter++;
    $item_total_counter++;

    my (  $genus, 
      $specie, 
      $family, 
      $type, 
      $identification_line,
      $common_name, 
      $country, 
      $state, 
      $municipality,
      $locality, 
      $alt, 
      $latlon, 
      $vegetation, 
      $collector,
      $collecting_date, 
      $identifier, 
      $herbarium, 
      $herbarium_number,
      $comment
    );

    if (defined ${$$item{result}}->{genus_id}) 
    {
      $genus = &get_genus(${$$item{result}}->{genus_id},$template,$dbh);
      $family = &get_family(${$$item{result}}->{genus_id},$template,$dbh);
      $identification_line = '<bi>'. $genus.'</bi>';
      if (defined ${$$item{result}}->{specie}) 
      {
        $specie = ${$$item{result}}->{specie};
        if (defined ${$$item{result}}->{identification_cualifier}) 
        {
                            $identification_line .=  '<b>'.${$$item{result}}->{identification_cualifier}.'</b>'; 
        };
      }
      else
      {
        $specie = ' <b>sp.</b>';
      }
                        $identification_line .=  '<bi>'.$specie.'</bi>'; 
  if (defined ${$$item{result}}->{infraspecific_epithet}) 
  {
    if (defined ${$$item{result}}->{specie} && ${$$item{result}}->{infraspecific_epithet} eq ${$$item{result}}->{specie}) 
    {
      # in case of coincidence between subspecibic & specific epithets, author name should appear before subspecie
      if (defined ${$$item{result}}->{author_id})
      {
        $identification_line .= ' <b>'.&get_author(${$$item{result}}->{author_id},$template,$dbh).'</b>';
      }
      elsif (defined ${$$item{result}}->{infraspecific_author_id})
      {
        # correcting error if no specie author, but infraspecific author only is defined
        $identification_line .= ' <b>'.&get_author(${$$item{result}}->{infraspecific_author_id},$template,$dbh).'</b>';
      }
      $identification_line .= ' '.${$$item{result}}->{infraspecific_flag}.' <bi>'.${$$item{result}}->{infraspecific_epithet}.'</bi>'; 
    }
    else
    {
      # in case of normal subspecie no specific author should appear, only subspecific
      $identification_line .= ' '.${$$item{result}}->{infraspecific_flag}.' <bi>'.${$$item{result}}->{infraspecific_epithet}.'</bi>'; 
      if (defined ${$$item{result}}->{infraspecific_author_id})
      {
        $identification_line .= ' <b>'.&get_author(${$$item{result}}->{infraspecific_author_id},$template,$dbh).'</b>';
      }
    }
  }
  else 
  {
    if (defined ${$$item{result}}->{author_id}) 
    {
      $identification_line .= ' <b>'.&get_author(${$$item{result}}->{author_id},$template,$dbh).'</b>';
    }
  }
  if (defined ${$$item{result}}->{name_addendum}) 
  {
    $identification_line .=  ' <b>'.${$$item{result}}->{name_addendum}.'</b>'; 
  }
    }         
    else
    {
      $identification_line = '<b>'.&messages('8009').'</b>';
    }
    # here it is necessary add hybrid identificacion !!!

                if (defined ${$$item{result}}->{common_name}) 
    {
      $common_name = ${$$item{result}}->{common_name};
    }
    $family = uc($family); 

    if (defined ${$$item{result}}->{municipality_id}) 
    {
      ($municipality,$state,$country) = &get_municipality(${$$item{result}}->{municipality_id},$template,$dbh);
    }
                if (defined ${$$item{result}}->{locality}) 
    {
      $locality .= ${$$item{result}}->{locality};
    }
                if (defined ${$$item{result}}->{microhabitat}) 
    {
      $locality .= ${$$item{result}}->{microhabitat};
    }
    if (defined ${$$item{result}}->{altitude}) 
    {
      $alt = ${$$item{result}}->{altitude}.' '.&messages('8010');
    }
    if ((defined ${$$item{result}}->{latitude}) && (defined ${$$item{result}}->{longitude})) 
    {
      my ($latitude, $longitude, $sign) = ();
      ($latitude,$sign) = &deg2sec(${$$item{result}}->{latitude});
      if ($sign eq "-" ) {$latitude .= "S";} else {$latitude .= "N";};
      ($longitude,$sign) = &deg2sec(${$$item{result}}->{longitude});
      if ($sign eq "-" ) {$longitude .= "W";} else {$longitude .= "E";};
      $latlon = $latitude.' '.$longitude;
    }
    if (defined ${$$item{result}}->{vegetation_type_id}) 
    {
      $vegetation = &get_vegetation(${$$item{result}}->{vegetation_type_id},$template,$dbh);
    }
    if (defined ${$$item{result}}->{collector_id}) 
    {
      $collector = &get_agent(${$$item{result}}->{collector_id},$template,$dbh);
      if (defined $collector) 
      {
        if (defined ${$$item{result}}->{collector_field_number}) 
        {
          $collector = '<i>' . $collector . '</i> '. ${$$item{result}}->{collector_field_number};
        }
        else
        {
          $collector = '<i>' . $collector . '</i> '. &messages('8007');
        }
      }
    }
    if (defined ${$$item{result}}->{collecting_date}) 
    {
      $collecting_date = ${$$item{result}}->{collecting_date};
    }
    if (defined ${$$item{result}}->{identifier_id}) 
    {
      $identifier = '<i>'.&get_agent(${$$item{result}}->{identifier_id},$template,$dbh).'</i>';
    }
                if (defined ${$$item{result}}->{herbarium_abbreviation}) 
    {
      $herbarium = ${$$item{result}}->{herbarium_abbreviation};
      $type = uc(${$$item{result}}->{type_status});
      if (! defined $fields{$herbarium}{'Header1'}) 
      {
        $fields{$herbarium}{'Header1'} = &messages('8011') .' '. $herbarium;
      }
      if (defined ${$$item{result}}->{herbarium_number}) 
      {
        $herbarium_number = $herbarium.' '.&messages('8012').': '.${$$item{result}}->{herbarium_number};
      } 
    } 
    else 
    {
      $herbarium = 'N_D';  # to find in hash values for unknown herbarium
    }

    if (defined ${$$item{result}}->{observations_plant_lifeform}) 
    {
      $comment .= ' ' . ${$$item{result}}->{observations_plant_lifeform};
    }
    if (defined ${$$item{result}}->{observations_plant_size}) 
    {
      $comment .= ' '. &messages('8013') .' '. ${$$item{result}}->{observations_plant_size};
    }
    if (defined ${$$item{result}}->{observations_plant_longevity}) 
    {
      $comment .= ' ' . ${$$item{result}}->{observations_plant_longevity};
    }
    if (defined ${$$item{result}}->{observations_plant_abundance}) 
    {
      $comment .= ' '. ${$$item{result}}->{observations_plant_abundance};
    }
    if (defined ${$$item{result}}->{observations_plant_fenology}) 
    {
      $comment .= ' '. ${$$item{result}}->{observations_plant_fenology};
    }
    if (defined $comment) 
    {
      $comment = &messages('8014') .' '. $comment;
                  if (defined ${$$item{result}}->{comment}) 
      {
        $comment .= ', ' . ${$$item{result}}->{comment};
      }

    } 
    else 
    {
                  if (defined ${$$item{result}}->{comment}) 
      {
        $comment .= ${$$item{result}}->{comment};
      }
    }


      my $group = {
        x => $page_groups{$item_counter}{x},
        y => $page_groups{$item_counter}{y},
        rect => [{                       
          x => '0',
          y => '0',
          w => '96',
          h => '82',
          color => 'gray',
          width => '0.1'
          }],
        line => [{
          x1 => '0.5',
          y1 => '62',
          x2 => '95.5',
          y2 => '62',
          color => 'black',
          width => '0.1'
          },
          {
          x1 => '0.5',
          y1 => '62.8',
          x2 => '95.5',
          y2 => '62.8',
          color => 'black',
          width => '0.6'
          }],
        label => [{
          # IdEjemplar
          x => '94',
          y => '64',
          font => 'Helvetica',
          style => 'Roman',
          size => '6',
          text => &messages('8015').':'. &un($$item{unit_id}),
          color => 'black',
          align => 'right'
          },
          {
          # herbarium number
          x => '2',
          y => '64',
          font => 'Helvetica',
          style => 'Roman',
          size => '6',
          text => &un($herbarium_number),
          color => 'black',
          align => 'left'
          },
          # family
          {
          x => '94',
          y => '49',
          font => 'Helvetica',
          style => 'Roman',
          size => '9',
          text => &un($family),
          align => 'right'
          },
          # type
          {
          x => '94',
          y => '45.5',
          font => 'Helvetica',
          style => 'Roman',
          size => '9',
          text => &un($type),
          align => 'right'
          },
          # common name label
          {
          x => '2',
          y => '49',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8016').':',
          align => 'left'
          },
          # state label
          {
          x => '2',
          y => '42',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8017').':',
          align => 'left'
          },
          # municipality label
          {
          x => '43',
          y => '42',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8018').':',
          align => 'left'
          },
          # locality label
          {
          x => '2',
          y => '35',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8019').':',
          align => 'left'
          },
          # lat/lon label
          {
          x => '2',
          y => '28',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8020').':',
          align => 'left'
          },
          # lat/lon
          {
          x => '18',
          y => '28',
          font => 'Helvetica',
          style => 'Roman',
          size => '9',
          text => &un($latlon),
          align => 'left'
          },
          # Alt label
          {
          x => '67',
          y => '28',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8021').':',
          align => 'left'
          },
          # Alt
          {
          x => '94',
          y => '28',
          font => 'Helvetica',
          style => 'Roman',
          size => '9',
          text => &un($alt),
          align => 'right'
          },
          # Vegetation label
          {
          x => '2',
          y => '23',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8022').':',
          align => 'left'
          },
          # Date label
          {
          x => '67',
          y => '23',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8023').':',
          align => 'left'
          },
          # Date
          {
          x => '94',
          y => '23',
          font => 'Helvetica',
          style => 'Roman',
          size => '9',
          text => &un($collecting_date),
          align => 'right'
          },
          # Notas label
          {
          x => '2',
          y => '16',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8024').':',
          align => 'left'
          },
          # Collector label
          {
          x => '2',
          y => '9',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8025').':',
          align => 'left'
          },
          # Identifier label
          {
          x => '2',
          y => '2',
          font => 'Helvetica',
          style => 'Bold',
          size => '8',
          text => &messages('8026').':',
          align => 'left'
          },
          {
          x => '94',
          y => '2',
          font => 'Helvetica',
          style => 'Roman',
          size => '5',
          text => "$$item{number}",
          color => 'black',
          align => 'right'
          },
          {
          x => '48',
          y => '78',
          font => 'Helvetica',
          style => 'Bold',
          text => $fields{$herbarium}{'Header1'},
          color => 'black',
          size => '8',
          align => 'center'
          },
          {
          x => '48',
          y => '74',
          font => 'Helvetica',
          style => 'Bold',
          text => $fields{$herbarium}{'Header2'},
          color => 'black',
          size => '9',
          align => 'center'
          },
          {
          x => '48',
          y => '70',
          font => 'Helvetica',
          style => 'Bold',
          text => $fields{$herbarium}{'Header3'},
          color => 'black',
          size => '8',
          align => 'center'
          },
          {
          x => '48',
          y => '65',
          font => 'Helvetica',
          style => 'Bold',
          text => &messages('8027') .' '. &un($country),
          color => 'black',
          size => '11',
          align => 'center'
          },
          {
          x => '94',
          y => '0.4',
          font => 'Helvetica',
          style => 'Roman',
          text => &messages('8028'),
          color => 'black',
          size => '2',
          align => 'right'
          }],
        paragraph => [
          # identification
          {
          x => '2',
          y => '57',
          font => 'Helvetica',
          style => 'Roman',
          text => &un($identification_line),
          align => 'left',
          size => '12',
          w => '94',
          h => '9',
          lead => '11'
          },
          # common name
          {
          x => '25',
          y => '49',
          font => 'Helvetica',
          style => 'Roman',
          text => &un($common_name),
          align => 'left',
          color => 'black',
          size => '9',
          w => '40',
          h => '8',
          lead => '10'
          },
                                        {
          # locality
          x => '17',
          y => '35',
          font => 'Helvetica',
          style => 'Roman',
          text => &un($locality),
          color => 'black',
          size => '9',
          w => '77',
          h => '8',
          lead => '10'
          },
          # municipality
          {
          x => '58',
          y => '42',
          font => 'Helvetica',
          style => 'Roman',
          text => &un($municipality),
          align => 'left',
          color => 'black',
          size => '9',
          w => '36',
          h => '8',
          lead => '10'
          },
          # state
          {
          x => '13',
          y => '42',
          font => 'Helvetica',
          style => 'Roman',
          text => &un($state),
          align => 'left',
          color => 'black',
          size => '9',
          w => '29',
          h => '8',
          lead => '10'
          },
          # vegetation
          {
          x => '19',
          y => '23',
          font => 'Helvetica',
          style => 'Roman',
          text => &un($vegetation),
          align => 'left',
          color => 'black',
          size => '9',
          w => '47',
          h => '8',
          lead => '10'
          },
          # notes
          {
          x => '12',
          y => '16',
          font => 'Helvetica',
          style => 'Roman',
          text => &un($comment),
          align => 'left',
          color => 'black',
          size => '7',
          w => '82',
          h => '8',
          lead => '10'
          },
          # collector
          {
          x => '9',
          y => '9',
          font => 'Helvetica',
          style => 'Roman',
          text => &un($collector),
          align => 'left',
          color => 'black',
          size => '9',
          w => '82',
          h => '8',
          lead => '10'
          },
          # identifier
          {
          x => '9',
          y => '2',
          font => 'Helvetica',
          style => 'Roman',
          text => &un($identifier),
          align => 'left',
          color => 'black',
          size => '9',
          w => '82',
          h => '4',
          lead => '10'
          }]
        };  

    push (@{$page->{group}}, $group);
    ${$page->{id}} = $page_counter;
    if (($item_counter >= 6) || ($item_total_counter >= scalar @array)) {
      # full page or last item
      push (@{$params->{page}}, $page); # saving of existing page object
      $page = undef;      # reseting of page object
            $page_counter++;
      $item_counter = 0;
    };
  }
  return $params;
}

sub preparePDF {
# this transform incoming hash to a set of pdf objects:
# pdf->page as a high-level object, each page can include
# text->label, text->paragraph, gfx->line, gfx->rectangle (hollow)
# outputs pdf object handler

  my $hashref = shift;

  my $pdf;
  $pdf = PDF::API2->new;

  my %font = (
        Helvetica => {
          Bold   => $pdf->corefont('Helvetica-Bold',    -encode => 'latin1'),
          Roman  => $pdf->corefont('Helvetica',         -encode => 'latin1'),
          Italic => $pdf->corefont('Helvetica-Oblique', -encode => 'latin1'),
          BoldItalic => $pdf->corefont('Helvetica-BoldOblique', -encode => 'latin1'),
        },
#         Courier => {
#           Bold   => $pdf->corefont('Courier-Bold',    -encode => 'latin1'),
#           Roman  => $pdf->corefont('Courier',         -encode => 'latin1'),
#         Italic => $pdf->corefont('Courier-Oblique', -encode => 'latin1'),
#         BoldItalic => $pdf->corefont('Courier-BoldOblique', -encode => 'latin1'),
#         },
#         Times => {
#           Bold   => $pdf->corefont('Times-Bold',        -encode => 'latin1'),
#         Roman  => $pdf->corefont('Times',             -encode => 'latin1'),
#         Italic => $pdf->corefont('Times-Italic',      -encode => 'latin1'),
#         BoldItalic => $pdf->corefont('Times-BoldItalic', -encode => 'latin1'),
#         },
  );

  foreach my $page (@{$$hashref->{page}}) {
  # group is the same as page

    my $page_obj = $pdf->page;

    $page_obj->mediabox(215.9/mm, 279.4/mm);
    $page_obj->cropbox (10/mm, 10/mm, 205.9/mm,262/mm);

    foreach my $group (@{$page->{group}}) {
      if ((defined $group->{x}) 
      && (defined $group->{y})) {
        # main frame of group, based only on left lower corner coord,
      # other elements in group are relative to this point
    
        foreach my $line (@{$group->{line}}) {
          if ((defined $line->{x1}) 
          && (defined $line->{y1})
          && (defined $line->{x2})
          && (defined $line->{y2})) {
          # lines processing, x1, x2, y1, y2 are necessary
          # width, color are optional
            my ($width, $color);
            my $g = $page_obj->gfx;
 
            if (defined $line->{width}) {
              $width = $line->{width};
            } else {
              $width = '0.2';
            }
            if (defined $line->{color}) {
              $color = $line->{color};
            } else {
              $color = 'black';
            }
            $g->strokecolor($color);
            $g->linewidth( $width/mm );
            $g->move(  ($group->{x}+$line->{x1})/mm, ($group->{y}+$line->{y1})/mm );
            $g->line(($group->{x}+$line->{x2})/mm, ($group->{y}+$line->{y2})/mm );
            $g->stroke;
          }
        }

        foreach my $rect (@{$group->{rect}}) {
          if ((defined $rect->{x}) 
          && (defined $rect->{y})
          && (defined $rect->{h})
          && (defined $rect->{w})) {
          # rectangles processing
          # x, x, h-height, y-width are necessary
          # width, color are optional

            my ($width, $color);
            my $g = $page_obj->gfx;

            if (defined $rect->{width}) {
              $width = $rect->{width};
            } else {
              $width = '0.2';
            }
            if (defined $rect->{color}) {
              $color = $rect->{color};
            } else {
              $color = 'black';
            }
            $g->strokecolor($color);
            $g->linewidth( $width/mm );
            $g->rect( ($group->{x}+$rect->{x})/mm, ($group->{y}+$rect->{y})/mm, $rect->{w}/mm, $rect->{h}/mm);
            $g->stroke;

          }
        }

        foreach my $label (@{$group->{label}}) {
          if ((defined $label->{text})
          && (defined $label->{x})
          && (defined $label->{y})) {
          # test processing: relative x, y are necessary, 
          # lead, size, color, align, font, style are optional
    
    # recode from unicode to latin1
    $cd->recode(&un($label->{text}));

            my ($size, $color, $align, $font, $style);
    
            if (defined $label->{style}) {
              $style = $label->{style};
            } else {
              $style = 'Roman';
            }
            if (defined $label->{font}) {
              $font = $label->{font};
            } else {
              $font = 'Helvetica';
            }
            if (defined $label->{size}) {
              $size = $label->{size};
            } else {
              $size = '7';
            }
            if (defined $label->{color}) {
              $color = $label->{color}
            } else {
              $color = 'black';
            }
            if (defined $label->{align}) {
              $align = $label->{align};
            } else {
              $align = 'left';
            }
            my $text = $page_obj->text;
            $text->font( $font{$font}{$style}, $size/pt);
            $text->fillcolor( $color );
            $text->translate( ($group->{x}+$label->{x})/mm, ($group->{y}+$label->{y})/mm );
            if ($align =~ m/justified/i) { 
        $text->text_justified( $label->{text} );
            } elsif ($align =~ m/right/i) {
              $text->text_right( $label->{text} );
            } elsif ($align =~ m/center/i) {
              $text->text_center( $label->{text} );
            } else {
              $text->text( $label->{text} );
            }
          }
        }

        foreach my $paragraph (@{$group->{paragraph}}) {
          if ((defined $paragraph->{text})
          && (defined $paragraph->{w})
          && (defined $paragraph->{h})
          && (defined $paragraph->{x})
          && (defined $paragraph->{y})) {
          # paragraph test processing: relative x, y, h-height, w-width 
          # are necessary, lead, size, color, align, font, style
          # are optional
            my ($lead, $size, $color, $align, $font, $style);

    # recode from unicode to latin1
    $cd->recode(&un($paragraph->{text}));

    
            if (defined $paragraph->{style}) {
              $style = $paragraph->{style};
            } else {
              $style = 'Roman';
            }
            if (defined $paragraph->{font}) {
              $font = $paragraph->{font};
            } else {
              $font = 'Helvetica';
            }

            if (defined $paragraph->{size}) {
              $size = $paragraph->{size};
            } else {
              $size = '7';
            }
            if (defined $paragraph->{lead}) {
              $lead = $paragraph->{lead};
            } else {
              $lead = '7';
            }
            if (defined $paragraph->{color}) {
              $color = $paragraph->{color}
            } else {
              $color = 'black';
            }
            if (defined $paragraph->{align}) {
              $align = $paragraph->{align};
            } else {
              $align = 'left';
            }
            
      my $text = $page_obj->text;
      $text->fillcolor( $color );
            &text_block(
              $pdf,
              $text,
              $paragraph->{text},
              \%font,
              -x => ($group->{x}+$paragraph->{x})/mm,
              -y => ($group->{y}+$paragraph->{y})/mm,
              -w => $paragraph->{w}/mm,
              -h => $paragraph->{h}/mm,
              -lead => $lead/pt,
              -parspace => 0/pt,
              -align => $align,
              -font => $font,
              -style => $style,
              -size => $size/pt,
            );
          }
        }
      }
    }
  }
  return $pdf;
}


sub text_block {
# pdf text block processing by "printaform"
# modified version to parse italic and bold of sintaxis <i>, </i>, <b>, </b>, <bi>, </bi>
# use externally dined font hash

    my $pdf_object = shift;
    my $text_object = shift;
    my $text = shift;
    my $fnt = shift;
    my %arg = @_;
    my ($xpos, $ypos, $endw, $align, $wordspace, $last_style); 

    if ($text ne '') {
  $text =~ s/<{1}(i|b|bi){1}>{1}/ <$1> /g;
  $text =~ s/<{1}(\/){1}(i|b|bi){1}>{1}/ <$1$2> /g;
    }
   
    # Get the text in paragraphs
    my @paragraphs = &trim(split(/\n/, &trim($text)));

    # set initial font
  $text_object->font( $$fnt{$arg{'-font'}}{$arg{'-style'}}, $arg{'-size'} );

    # calculate width of all words
    my $space_width = $text_object->advancewidth(' ');

    $ypos = $arg{'-y'};
    my @paragraph = &trim(split(/\s+/, shift(@paragraphs)));
    my $first_line = 1;
    my $first_paragraph = 1;

    # while we can add another line
    while ( $ypos >= $arg{'-y'} - $arg{'-h'} + $arg{'-lead'} ) {
        
        unless (@paragraph) {
            last unless scalar @paragraphs;
            @paragraph = split(/\s+/, shift(@paragraphs));

            $ypos -= $arg{'-parspace'} if $arg{'-parspace'};
            last unless $ypos >= $arg{'-y'} - $arg{'-h'};
            $first_line = 1;
            $first_paragraph = 0;
        }
        
        $xpos = $arg{'-x'};
        
        # while there's room on the line, add another word
        my (@line,@line_special) = ();

        my $line_width = 0;
        if ($first_line && exists $arg{'-hang'}) {
            my $hang_width = $text_object->advancewidth($arg{'-hang'});

            $text_object->translate( $xpos, $ypos );
            $text_object->text( $arg{'-hang'} );

            $xpos         += $hang_width;
            $line_width   += $hang_width;
            $arg{'-indent'} += $hang_width if $first_paragraph;
        }
        elsif ($first_line && exists $arg{'-flindent'}) {
            $xpos += $arg{'-flindent'};
            $line_width += $arg{'-flindent'};
        }
        elsif ($first_paragraph && exists $arg{'-fpindent'}) {
            $xpos += $arg{'-fpindent'};
            $line_width += $arg{'-fpindent'};
        }
        elsif (exists $arg{'-indent'}) {
            $xpos += $arg{'-indent'};
            $line_width += $arg{'-indent'};
        }

      # set initial font for line measuring
  if (defined $last_style) {
    $text_object->font( $$fnt{$arg{'-font'}}{$last_style}, $arg{'-size'} );
  } else {
        $text_object->font( $$fnt{$arg{'-font'}}{$arg{'-style'}}, $arg{'-size'} );
  };

                
        while ( @paragraph and $line_width + (scalar(@line) * $space_width) + $text_object->advancewidth($paragraph[0]) < $arg{'-w'} ) {
      if ($paragraph[0] =~ m/^(<{1}\/?(i|b|bi){1}>{1})$/) {
    # we have here special symbol and need to change current font to make correct measure
    push(@line_special, shift(@paragraph));
    if ($1 eq '<i>') { $text_object->font( $$fnt{$arg{'-font'}}{'Italic'}, $arg{'-size'} );
    } elsif ($1 eq '</i>') { $text_object->font( $$fnt{$arg{'-font'}}{$arg{'-style'}}, $arg{'-size'} );
    } elsif ($1 eq '<b>') { $text_object->font( $$fnt{$arg{'-font'}}{'Bold'}, $arg{'-size'} );
    } elsif ($1 eq '</b>') { $text_object->font( $$fnt{$arg{'-font'}}{$arg{'-style'}}, $arg{'-size'} );
    } elsif ($1 eq '<bi>') { $text_object->font( $$fnt{$arg{'-font'}}{'BoldItalic'}, $arg{'-size'} );
    } elsif ($1 eq '</bi>') { $text_object->font( $$fnt{$arg{'-font'}}{$arg{'-style'}}, $arg{'-size'} );
    }
      } else {
    # we do not have here special symbol and can use this symbol length
              $line_width += $text_object->advancewidth($paragraph[0]);
    my $current_word = shift(@paragraph);
              push(@line, $current_word);
    push(@line_special, $current_word);
      }
        }

    
        # calculate the space width
        if ($arg{'-align'} eq 'fulljustify' or ($arg{'-align'} eq 'justify' and @paragraph)) {
            if (scalar(@line) == 1) {
                @line = split(//,$line[0]);
            }
            $wordspace = ($arg{'-w'} - $line_width) / (scalar(@line) - 1);
            $align='justify';
        } else {
            $align=($arg{'-align'} eq 'justify') ? 'left' : $arg{'-align'};
            $wordspace = $space_width;
        }
        $line_width += $wordspace * (scalar(@line) - 1);

      # set initial font again, for output
  if (defined $last_style) {
    $text_object->font( $$fnt{$arg{'-font'}}{$last_style}, $arg{'-size'} );
  } else {
        $text_object->font( $$fnt{$arg{'-font'}}{$arg{'-style'}}, $arg{'-size'} );
  };
        
            # calculate the left hand position of the line
            if ($align eq 'right') {
                $xpos += $arg{'-w'} - $line_width;
            } elsif ($align eq 'center') {
                $xpos += ($arg{'-w'}/2) - ($line_width / 2);
            }

            foreach my $word (@line_special) {
                if ((defined $line[0]) && ($word eq $line[0])) {
      # we have normal word
                  $text_object->translate( $xpos, $ypos );
                  $text_object->text( $line[0] );
                  $xpos += ($text_object->advancewidth($line[0]) + $wordspace) if (@line_special);
      shift(@line);
    } else {
      # we have special symbol
      if ($word eq '<i>') { 
        $text_object->font( $$fnt{$arg{'-font'}}{'Italic'}, $arg{'-size'} );
              $last_style = 'Italic';
      } elsif ($word eq '</i>') { 
        $text_object->font( $$fnt{$arg{'-font'}}{$arg{'-style'}}, $arg{'-size'} );
              $last_style = $arg{'-style'};
      } elsif ($word eq '<b>') { 
        $text_object->font( $$fnt{$arg{'-font'}}{'Bold'}, $arg{'-size'} );
        $last_style = 'Bold';
      } elsif ($word eq '</b>') { 
        $text_object->font( $$fnt{$arg{'-font'}}{$arg{'-style'}}, $arg{'-size'} );
              $last_style = $arg{'-style'};
      } elsif ($word eq '<bi>') { 
        $text_object->font( $$fnt{$arg{'-font'}}{'BoldItalic'}, $arg{'-size'} );
        $last_style = 'BoldItalic';
      } elsif ($word eq '</bi>') { 
        $text_object->font( $$fnt{$arg{'-font'}}{$arg{'-style'}}, $arg{'-size'} );
              $last_style = $arg{'-style'};
      }
    }
            }

        $endw = $arg{'-w'}; # this is correct only for justified text, but it is necessary to add something more for other justifications
        $ypos -= $arg{'-lead'};
        $first_line = 0;
    }
    unshift(@paragraphs, join(' ',@paragraph)) if scalar(@paragraph);
    return ($endw, $ypos, join("\n", @paragraphs))
}


