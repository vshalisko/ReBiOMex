# subs to generate sql clause code from CGI input

use strict;
use locale;
use CGI qw (:standard escapeHTML escape);
use Encode;
require 'tools.pl';
require 'messages.pl';
require 'db_requests.pl';

sub get_list_search_params {

	my ($template,$dbh) = @_;
	my ($genus, $specie, $family, $municipality, $state, $collector, $field_number, 
		$collecting_date, $type_status, $herbarium, $common, $data_set, $status_only, $incorporated_only, $substring) = (); # CGI input variables
	my ($cl,$ss) = ();	# output variables
	my (@search_param) = ();		# output array

	# parameters to look for 	
	$genus = &escape_input(&un(param("genus")));
	$specie = &escape_input(&un(param("specie")));
	$family = &escape_input(&un(param("family")));
	$municipality = &escape_input_1(&un(param("municipality")));
	$state = &escape_input_1(&un(param("state")));
	$collector = &escape_input_1(&un(param("collector"))); # cause switching to slow request version
	$field_number = &escape_input(&un(param("field_number")));
	$collecting_date = &escape_date_1(&un(param("collecting_date")));
	$type_status = &escape_input(&un(param("type_status")));
	$herbarium = &escape_input(&un(param("herbarium")));
	$common = &escape_input(&un(param("common")));
	$status_only = &escape_input(&un(param("status_only"))); # advanced feature - search only registers with status
	$incorporated_only = &escape_input(&un(param("incorporated_only"))); # advanced feature - search only registers incorporated to scientific collections
	$data_set = &escape_input(&un(param("data_set"))); # advanced feature - search in specific data segment only (waiting to be implementated in form)
	$substring = &escape_input_1(&un(param("substring"))); # special request

	# generating of SQL elements for specimen search
	if ($genus) 
	{
		$cl .= "view_identification.genus LIKE ". $dbh->quote ($genus) ." AND\n";
		push(@search_param, {PARAMETER => &messages('3002'), VALUE => escapeHTML($genus)});
		$ss .=  "genus=". &URLescape($genus) ."&";
	}
	if ($specie) 
	{
		$cl .= "view_identification.specie LIKE " . $dbh->quote ($specie) ." AND\n";
		push(@search_param, {PARAMETER => &messages('3003'), VALUE => escapeHTML($specie)});
		$ss .=  "specie=". &URLescape($specie) ."&";
	}
	if ($family) 
	{
		$cl .= "( view_identification.familia LIKE ". $dbh->quote ($family) ." OR view_identification.familia_synonym LIKE ". $dbh->quote ($family) ." ) AND\n";
		push(@search_param, {PARAMETER => &messages('3004'), VALUE => escapeHTML($family)});
		$ss .=  "family=". &URLescape($family) ."&";
	}
	if ($state || $municipality) 
	{
		my @municipality_id_list = &get_municipality_id_list($municipality,$state,$template,$dbh);
		if (scalar @municipality_id_list) 
		{
			$cl .= "(";
			foreach my $id_ref (@municipality_id_list) 
			{
				$cl .= "view_identification.municipality_id = ". $dbh->quote($$id_ref->{municipality_id}) ." OR ";
			}
			$cl =~ s/OR\s$//i;
			$cl .= ") AND\n";
		}
		if ($municipality) 
		{
			push(@search_param, {PARAMETER => &messages('3005'), VALUE => escapeHTML($municipality)});
			$ss .=  "municipality=". &URLescape($municipality) ."&";
		}
		if ($state) 
		{
			push(@search_param, {PARAMETER => &messages('3006'), VALUE => escapeHTML($state)});
			$ss .=  "state=". &URLescape($state) ."&";
		}
	}
	if ($collector) # to improve performance search is limited only to team leader
	{
		if (length($collector) >= 4) {
			$collector = "%".$collector."%";
		}
		$cl .= "view_collector.agent_sorting_name LIKE ". $dbh->quote ($collector) ." AND\n";
		push(@search_param, {PARAMETER => &messages('3007'), VALUE => escapeHTML($collector)});
		$ss .=  "collector=". &URLescape($collector) ."&";
	}
	if ($field_number) 
	{
		$cl .= "view_identification.collector_field_number LIKE ". $dbh->quote ($field_number) ." AND\n";
		push(@search_param, {PARAMETER => &messages('3008'), VALUE => escapeHTML($field_number)});
		$ss .=  "field_number=". &URLescape($field_number) ."&";
	}
	if ($collecting_date) 
	{
		$cl .= "view_identification.collecting_date LIKE ". $dbh->quote ($collecting_date) ." AND\n";
		push(@search_param, {PARAMETER => &messages('3009'), VALUE => escapeHTML($collecting_date)});
		$ss .=  "collecting_date=". &URLescape($collecting_date) ."&";
	}
	if ($type_status) 
	{
		$cl .= "specimen.type_status IS NOT NULL AND\n";
		push(@search_param, {PARAMETER => &messages('3010'), VALUE => escapeHTML($type_status)});
		$ss .=  "type_status=". &URLescape($type_status) ."&";
	}
	if ($herbarium) 
	{
		$cl .= "herbarium.herbarium_abbreviation LIKE ". $dbh->quote ($herbarium) ." AND\n";
		push(@search_param, {PARAMETER => &messages('3011'), VALUE => escapeHTML($herbarium)});
		$ss .=  "herbarium=". &URLescape($herbarium) ."&";
	}
	if ($data_set) 
	{
		$cl .= "view_identification.database_abbreviation LIKE ". $dbh->quote ($data_set) ." AND\n";
		push(@search_param, {PARAMETER => &messages('3014'), VALUE => escapeHTML($data_set)});
		$ss .=  "data_set=". &URLescape($data_set) ."&";
	}
	if ($status_only) 
	{
		$cl .= "assignation_status.status_detail IS NOT NULL AND\n";
		push(@search_param, {PARAMETER => &messages('3015'), VALUE => escapeHTML($status_only)});
		$ss .=  "status_only=". &URLescape($status_only) ."&";
	}
	if ($incorporated_only) 
	{
		$cl .= "specimen.specimen_status LIKE 'incorporado%' AND\n";
		push(@search_param, {PARAMETER => &messages('3017'), VALUE => escapeHTML($incorporated_only)});
		$ss .=  "incorporated_only=". &URLescape($status_only) ."&";
	}
	if ($common) 
	{
		$cl .= "view_identification.observations_plant_common_name LIKE ". $dbh->quote ($common) ." AND\n";
		push(@search_param, {PARAMETER => &messages('3012'), VALUE => escapeHTML($common)});
		$ss .=  "common=". &URLescape($common) ."&";
	}
	if ($substring) 
	{
		my @substring_parts = &parse_words($substring);
		foreach my $substring_part (@substring_parts)
		{
			$cl .= "(";
			$cl .= "view_identification.genus LIKE ". $dbh->quote ($substring_part) ." OR ";
			$cl .= "view_identification.specie LIKE ". $dbh->quote ($substring_part) ." OR ";
			$cl .= "view_identification.infraspecific_epithet LIKE ". $dbh->quote ($substring_part) ." OR ";
			$cl .= "view_identification.hybrid_specie LIKE ". $dbh->quote ($substring_part) ." OR ";
			$cl .= "view_identification.observations_plant_common_name LIKE ". $dbh->quote ($substring_part) ." OR ";
			$cl .= "( view_identification.familia LIKE ". $dbh->quote ($substring_part) ." OR view_identification.familia_synonym LIKE" . $dbh->quote ($substring_part) ." )";
			$cl .= ") AND\n";
		}
		push(@search_param, {PARAMETER => &messages('3001'), VALUE => escapeHTML($substring)});
		$ss .=  "substring=". &URLescape($substring) ."&";
	}

	if ($cl && !$specie && !$substring)
	{
		# if search is not specific taxa based, only preferred identifications should be found
		$cl .= "view_identification.preferred_flag IS NOT NULL AND "; 
		push(@search_param, {PARAMETER => &messages('3016'), VALUE => 'on'});
	}


	return (\@search_param,$ss,$cl);
}

1;