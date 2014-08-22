#!/usr/bin/perl -w

# xml_export.cgi - simple templated output - temporary
BEGIN {
    my $base_module_dir = (-d '/home2/rebiomex/perl' ? '/home2/rebiomex/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use strict;
use locale;
use CGI qw (:standard escapeHTML escape);
use HTML::Template;
use Encode;
use XML::Generator;
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
my (undef,undef,undef,$access_mode) = &login_status($template,$dbh);


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

my $XML = XML::Generator->new(':pretty');

my $dwrNS = [ dwr => 'http://rs.tdwg.org/dwc/xsd/simpledarwincore/' ];
my $dwcNS = [ dwc => 'http://rs.tdwg.org/dwc/terms/' ];
my $dctermsNS = [ dcterms  => 'http://purl.org/dc/terms/' ];

my ($municipality,$state,$country) = &get_municipality(${$result_array[0]{result}}->{municipality_id},$template,$dbh);

my $collector = '';
if (${$result_array[0]{result}}->{collector_id}) {
	$collector = &un(&get_agent(${$result_array[0]{result}}->{collector_id},$template,$dbh));
}
if (${$result_array[0]{result}}->{collector_field_number}) {
	$collector .= ' ' . ${$result_array[0]{result}}->{collector_field_number};
} else {
	$collector .= ' s. n.';
}
 
my  $xml_test_string = 
			sprintf ("%s",
			$XML->xml(
				$XML->DarwinRecordSet(
					[ @$dwrNS, @$dwcNS, @$dctermsNS, 'xsi' => 'http://www.w3.org/2001/XMLSchema-instance',   ],
					{ 'xsi:schemaLocation' => 'http://rs.tdwg.org/dwc/xsd/simpledarwincore/  http://rs.tdwg.org/dwc/xsd/tdwg_dwc_simple.xsd' },
					$XML->DarwinRecord(
						$dwrNS,
						$XML->type( $dctermsNS, 'PhysicalObject' ), # temporal solution
						$XML->modified( $dctermsNS, ${$result_array[0]{result}}->{date_mod} ),
						$XML->rightsHolder( $dctermsNS, 'ReBiOMex' ), # temporal solution
						$XML->rights( $dctermsNS, 'Creative Commons License' ),  # temporal solution
						$XML->datasetID( $dwcNS, ${$result_array[0]{result}}->{database_id} ),
						$XML->datasetName( $dwcNS, &un(&get_database_abbreviation(${$result_array[0]{result}}->{database_id},$template,$dbh)) ),
						$XML->institutionCode( $dwcNS, ${$result_array[0]{result}}->{herbarium_abbreviation} ),
						$XML->basisOfRecord( $dwcNS, ${$result_array[0]{result}}->{record_base}),
						$XML->Occurrence(
							$dwcNS,
							$XML->occurenceID( $dwcNS,  ${$result_array[0]{result}}->{unit_id} ),
							$XML->catalogNumber( $dwcNS, ${$result_array[0]{result}}->{herbarium_number} ),
						),
						$XML->Event(
							$dwcNS,
							$XML->fieldNumber( $dwcNS, $collector),
							$XML->eventDate( $dwcNS, ${$result_array[0]{result}}->{collecting_date} ),
							$XML->habitat( $dwcNS, ${$result_array[0]{result}}->{microhabitat} ),
						),
						$XML->Location(
							$dwcNS,
							$XML->country( $dwcNS, $country ),
							$XML->stateProvince( $dwcNS, $state ),
							$XML->municipality( $dwcNS, $municipality ),
							$XML->verbatimLocality( $dwcNS, ${$result_array[0]{result}}->{locality} ),
							$XML->verbatimElevation( $dwcNS, ${$result_array[0]{result}}->{altitude} ),
							$XML->decimalLatitude( $dwcNS, ${$result_array[0]{result}}->{latitude} ),
							$XML->decimalLongitude( $dwcNS, ${$result_array[0]{result}}->{longitude} ),
						),
						$XML->Identification(
							$dwcNS,
							$XML->identificationID( $dwcNS, ${$result_array[0]{result}}->{identification_id} ),
							$XML->identifiedBy( $dwcNS, &un(&get_agent(${$result_array[0]{result}}->{identifier_id},$template,$dbh)) ),
							$XML->dateIdentified( $dwcNS, ${$result_array[0]{result}}->{identification_date} ),
							$XML->identificationCualifier( $dwcNS, ${$result_array[0]{result}}->{identification_cualifier} ),
						),
						$XML->Taxon(
							$dwcNS,
							$XML->scientificName( $dwcNS, ${$result_array[0]{result}}->{scientific_name} ),
							$XML->kingdom( $dwcNS, ${$result_array[0]{result}}->{regnum} ),
							$XML->phylum( $dwcNS, ${$result_array[0]{result}}->{phylum} ),
							$XML->class( $dwcNS, ${$result_array[0]{result}}->{classis} ),
							$XML->order( $dwcNS, ${$result_array[0]{result}}->{ordo} ),
							$XML->family( $dwcNS, ${$result_array[0]{result}}->{familia} ),
							$XML->genus( $dwcNS, ${$result_array[0]{result}}->{genus} ),
							$XML->specificEpithet( $dwcNS, ${$result_array[0]{result}}->{specie}) ,
						)
					)
				)
			)
			);
			
  


  $template->param(
    PAGE_TITLE => &messages('9005'),
    XML_EXPORT => 1,
    XML_TEST => escapeHTML($xml_test_string),
  );

&disconnect_dbh($dbh,$template);

# page output

print "Content-type: text/html; charset=utf-8\n\n";
binmode STDOUT, ":utf8";
print $template->output;

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
      @main_list_ref = &search_xml_export($clause,$template,$dbh);
    }
    if ((scalar @main_list_ref) > 0) {
      return shift @main_list_ref;
    } else { 
      return undef;
    }
}