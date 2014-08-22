# subs to request DB
require 'messages.pl';

sub main_list {
  # query alternative identification information and returns it 
  # as an array of references of hashes
  my ($request,$template,$dbh) = @_;
  my @main_ref_array = ();
  
  my $sth_1 = $dbh->prepare ($request) or &sql_error_out(&messages('1009'),$template);
  $sth_1->execute()  or &sql_error_out(&messages('1010'),$template);
  
  while (my $main_ref = $sth_1->fetchrow_hashref()) {
    push (@main_ref_array, \$main_ref);
  };
  
  $sth_1->finish()  or &sql_error_out(&messages('1011'),$template);
  return @main_ref_array;
}

#=== main_list based subs return list of refs ================================================================================= 

sub get_selector {
	my ($table,$id_field,$text_field,$template,$dbh) = @_;

	my @ref_array = &main_list(qq{
	    SELECT 
	    $id_field, 
	    $text_field
	    FROM $table
	},$template,$dbh);
	
	my %selector = ();
	foreach my $ref (@ref_array) {
		if (!defined $$ref->{$id_field}) {$$ref->{$id_field} = '';};
		if (!defined $$ref->{$text_field}) {$$ref->{$text_field} = '';};
		$selector{$$ref->{$id_field}} = $$ref->{$text_field};
	}
	return \%selector;
}

sub get_taxonomy {
	my ($clause,$template,$dbh) = @_;
	my @main_list_ref = &main_list(qq{
	SELECT 
	view_taxonomy.subgeneric_id,   
	view_taxonomy.specie,
	view_taxonomy.specie_author_id,
	view_taxonomy.infraspecific_flag,
	view_taxonomy.infraspecific_epithet,
	view_taxonomy.infraspecific_author_id,
	view_taxonomy.hybrid_flag,
	view_taxonomy.hybrid_genus_id,
	view_taxonomy.hybrid_specie,
	view_taxonomy.hybrid_author_id,
	view_taxonomy.subgeneric_reference_id,
	view_taxonomy.subgeneric_comment,
	view_taxonomy.genus_id,
	view_taxonomy.genus,	
	view_taxonomy.genus_author_id,
	view_taxonomy.genus_comment,
	view_taxonomy.genus_reference_id,
	view_taxonomy.familia_id,
	view_taxonomy.familia,
	view_taxonomy.familia_synonym,
	view_taxonomy.familia_author_id,
	view_taxonomy.ordo,
	view_taxonomy.classis,
	view_taxonomy.phylum,
	view_taxonomy.familia_reference_id,
	view_taxonomy.familia_comment,
	view_taxonomy.regnum_id,
	view_taxonomy.regnum,
	view_taxonomy.regnum_reference_id,
	view_taxonomy.regnum_comment,
	COUNT(identification.subgeneric_id) AS taxa_count,
	COUNT(identification.preferred_flag) AS preferred_taxa_count
	FROM view_taxonomy 
	LEFT JOIN identification 
	ON identification.subgeneric_id <=> view_taxonomy.subgeneric_id
	WHERE $clause 1
	GROUP BY 
	view_taxonomy.familia_id,
	view_taxonomy.genus_id,
	view_taxonomy.specie,
	view_taxonomy.specie_author_id,
	view_taxonomy.infraspecific_epithet,
	view_taxonomy.hybrid_genus_id,
	view_taxonomy.hybrid_specie,
	view_taxonomy.hybrid_author_id
	ORDER BY
	view_taxonomy.familia,
	view_taxonomy.genus,
	view_taxonomy.specie,
	view_taxonomy.infraspecific_epithet DESC,
	view_taxonomy.infraspecific_author_id DESC,
	view_taxonomy.specie_author_id DESC
	LIMIT 1000
	},$template,$dbh);

      return @main_list_ref ;
}

sub get_taxonomy_familia {
	my ($clause,$template,$dbh) = @_;
	my @main_list_ref = &main_list(qq{
	SELECT 
	view_taxonomy.genus_id,
	view_taxonomy.genus,	
	view_taxonomy.genus_author_id,
	view_taxonomy.genus_comment,
	view_taxonomy.genus_reference_id,
	view_taxonomy.familia_id,
	view_taxonomy.familia,
	view_taxonomy.familia_synonym,
	view_taxonomy.familia_author_id,
	view_taxonomy.ordo,
	view_taxonomy.classis,
	view_taxonomy.phylum,
	view_taxonomy.familia_reference_id,
	view_taxonomy.familia_comment,
	view_taxonomy.regnum_id,
	view_taxonomy.regnum,
	view_taxonomy.regnum_reference_id,
	view_taxonomy.regnum_comment,
	COUNT(identification.subgeneric_id) AS taxa_count,
	COUNT(identification.preferred_flag) AS preferred_taxa_count
	FROM view_taxonomy
	LEFT JOIN identification 
	ON identification.subgeneric_id <=> view_taxonomy.subgeneric_id
	WHERE $clause 1
	GROUP BY 
	view_taxonomy.familia_id,
	view_taxonomy.genus_id
	ORDER BY
	view_taxonomy.familia,
	view_taxonomy.genus
	LIMIT 1000
	},$template,$dbh);

      return @main_list_ref ;
}

sub get_main_list_record_number {
      my ($clause,$template,$dbh) = @_;
      my @main_list_ref = &main_list(qq{
    SELECT
    COUNT(DISTINCT view_identification.unit_id,specimen.specimen_id,view_identification.identification_id) AS record_number
    FROM 
    view_collector,
    assignation_status RIGHT JOIN
    view_identification 
    ON view_identification.subgeneric_id <=> assignation_status.subgeneric_id
    LEFT JOIN specimen
    ON view_identification.unit_id <=> specimen.unit_id 
    LEFT JOIN herbarium 
    ON specimen.herbarium_id <=> herbarium.herbarium_id
    WHERE $clause
    view_identification.unit_id = view_collector.unit_id
    },$template,$dbh);
      return @main_list_ref ;
}

sub search_main_list_simple {
      my ($limit,$clause,$template,$dbh) = @_;
      my @main_list_ref = &main_list(qq{
    SELECT
    view_identification.unit_id,
    view_identification.collector_id,
    view_identification.collector_field_number,
    DATE_FORMAT(view_identification.collecting_date,'%e/%c/%Y') AS collecting_date,
    view_identification.municipality_id,
    view_identification.observations_plant_common_name,
    view_identification.genus_id, 
    view_identification.specie, 
    view_identification.author_id,
    view_identification.infraspecific_flag,
    view_identification.infraspecific_epithet,
    view_identification.infraspecific_author_id,
    view_identification.hybrid_flag,
    view_identification.hybrid_genus_id,
    view_identification.hybrid_specie,
    view_identification.hybrid_author_id,
    view_identification.identification_id,
    view_identification.preferred_flag,
    view_identification.name_addendum,
    view_identification.identification_cualifier,
    view_identification.observations_plant_common_name,
    view_identification.database_abbreviation,
    view_identification.subgeneric_id,
    specimen.specimen_id,
    specimen.type_status,
    specimen.specimen_status,
    specimen.herbarium_number,
    specimen.type_identification_id,
    herbarium.herbarium_abbreviation,
    assignation_status.status_detail,
    COUNT(assignation_status.status_detail) AS count_status
    FROM
    assignation_status RIGHT JOIN
    view_identification 
    ON view_identification.subgeneric_id <=> assignation_status.subgeneric_id
    LEFT JOIN specimen
    ON view_identification.unit_id <=> specimen.unit_id
    LEFT JOIN herbarium 
    ON specimen.herbarium_id <=> herbarium.herbarium_id
    WHERE $clause 1
    GROUP BY 
    view_identification.unit_id, specimen.specimen_id, view_identification.identification_id
    ORDER BY 
    view_identification.genus, 
    view_identification.specie, 
    view_identification.infraspecific_epithet,
    herbarium.herbarium_abbreviation,
    view_identification.unit_id
    $limit
    },$template,$dbh);
      return @main_list_ref ;
}

sub search_main_list {
      my ($limit,$clause,$template,$dbh) = @_;
      my @main_list_ref = &main_list(qq{
    SELECT
    view_identification.unit_id,
    view_identification.collector_id,
    view_identification.collector_field_number,
    DATE_FORMAT(view_identification.collecting_date,'%e/%c/%Y') AS collecting_date,
    view_identification.municipality_id,
    view_identification.observations_plant_common_name,
    view_identification.genus_id, 
    view_identification.specie, 
    view_identification.author_id,
    view_identification.infraspecific_flag,
    view_identification.infraspecific_epithet,
    view_identification.infraspecific_author_id,
    view_identification.hybrid_flag,
    view_identification.hybrid_genus_id,
    view_identification.hybrid_specie,
    view_identification.hybrid_author_id,
    view_identification.identification_id,
    view_identification.preferred_flag,
    view_identification.name_addendum,
    view_identification.identification_cualifier,
    view_identification.observations_plant_common_name,
    view_identification.database_abbreviation,
    view_identification.subgeneric_id,
    specimen.specimen_id,
    specimen.type_status,
    specimen.specimen_status,
    specimen.herbarium_number,
    specimen.type_identification_id,
    herbarium.herbarium_abbreviation,  
    view_collector.agent,
    assignation_status.status_detail,
    COUNT(assignation_status.status_detail) AS count_status
    FROM
    view_collector,
    assignation_status RIGHT JOIN
    view_identification 
    ON view_identification.subgeneric_id <=> assignation_status.subgeneric_id
    LEFT JOIN specimen
    ON view_identification.unit_id <=> specimen.unit_id 
    LEFT JOIN herbarium 
    ON specimen.herbarium_id <=> herbarium.herbarium_id
    WHERE $clause 
    view_identification.unit_id = view_collector.unit_id
    GROUP BY 
    view_identification.unit_id, specimen.specimen_id, view_identification.identification_id
    ORDER BY  
    view_identification.genus, 
    view_identification.specie, 
    view_identification.infraspecific_epithet,
    view_collector.agent,
    view_identification.collector_field_number,
    herbarium.herbarium_abbreviation,
    view_identification.unit_id
    $limit
    },$template,$dbh);
      return @main_list_ref ;
}

sub canasta_main_list {
      my ($clause,$template,$dbh) = @_;
      my @main_list_ref = &main_list(qq{
    SELECT 
    unit.unit_id,
    unit.collector_id,
    unit.collector_field_number,
    DATE_FORMAT(unit.collecting_date,'%e/%c/%Y') AS collecting_date,
    unit.municipality_id,
    subgeneric.genus_id, 
    subgeneric.specie, 
    subgeneric.author_id,
    subgeneric.infraspecific_flag,
    subgeneric.infraspecific_epithet,
    subgeneric.infraspecific_author_id,
    subgeneric.hybrid_flag,
    subgeneric.hybrid_genus_id,
    subgeneric.hybrid_specie,
    subgeneric.hybrid_author_id,
    identification.identification_id,
    identification.name_addendum,
    identification.identification_cualifier,
    specimen.specimen_id,
    specimen.type_status,
    specimen.specimen_status,
    specimen.herbarium_number,
    specimen.type_identification_id,
    herbarium.herbarium_abbreviation 
    FROM identification, subgeneric, 
    unit LEFT JOIN specimen 
    ON unit.unit_id = specimen.unit_id 
    LEFT JOIN herbarium
    ON specimen.herbarium_id = herbarium.herbarium_id
    WHERE $clause
    unit.unit_id <=> identification.unit_id
    AND identification.subgeneric_id <=> subgeneric.subgeneric_id
    ORDER BY unit.unit_id, identification.identification_id, specimen.specimen_id
    },$template,$dbh);
      return @main_list_ref ;
}

sub search_unit_list {
      my ($clause,$template,$dbh) = @_;
      my @main_list_ref = &main_list(qq{
    SELECT 
    unit.unit_id,
    unit.unit_identifier,
    unit.unit_universal_identifier,
    unit.record_base,
    unit.collector_id,
    unit.collector_field_number,
    DATE_FORMAT(unit.collecting_date,'%e/%c/%Y') AS collecting_date,
    unit.project_id,
    unit.database_id,
    unit.municipality_id,
    unit.locality, 
    unit.altitude,
    unit.latitude,
    unit.longitude,
    unit.microhabitat,
    unit.vegetation_type_id,
    unit.observations_plant_lifeform,
    unit.observations_plant_size,
    unit.observations_plant_longevity,
    unit.observations_plant_common_name,
    unit.observations_plant_use,
    unit.observations_plant_abundance,
    unit.observations_plant_fenology,
    unit.observations_plant_nutrition,
    unit.comment,
    unit.user_id,
    unit.date_mod,
    unit.user_id_creation,
    unit.date_creation,
    subgeneric.subgeneric_id,
    subgeneric.genus_id, 
    subgeneric.specie, 
    subgeneric.author_id,
    subgeneric.infraspecific_flag,
    subgeneric.infraspecific_epithet,
    subgeneric.infraspecific_author_id,
    subgeneric.hybrid_flag,
    subgeneric.hybrid_genus_id,
    subgeneric.hybrid_specie,
    subgeneric.hybrid_author_id,
    identification.identification_id,
    identification.identifier_id,
    identification.identifier_role,
    DATE_FORMAT(identification.identification_date,'%e/%c/%Y') AS identification_date,
    identification.preferred_flag,
    identification.reference_id,
    identification.name_addendum,
    identification.identification_cualifier,
    identification.comment AS identification_comment,
    identification.user_id_creation AS ident_user_id_creation,
    identification.date_creation AS ident_date_creation
    FROM unit LEFT JOIN identification ON unit.unit_id <=> identification.unit_id
    LEFT JOIN subgeneric ON identification.subgeneric_id <=> subgeneric.subgeneric_id
    WHERE $clause 1
    ORDER BY identification.preferred_flag DESC
    LIMIT 1     
    },$template,$dbh);
      return @main_list_ref ;
}

sub search_etiquetes_list { # should be improved to show empty identification cases
      my ($clause,$template,$dbh) = @_;
      my @main_list_ref = &main_list(qq{
    SELECT 
    unit.unit_id,
    unit.unit_identifier,
    unit.unit_universal_identifier,
    unit.record_base,
    unit.collector_id,
    unit.collector_field_number,
    DATE_FORMAT(unit.collecting_date,'%e/%c/%Y') AS collecting_date,
    unit.project_id,
    unit.database_id,
    unit.municipality_id,
    unit.locality, 
    unit.altitude,
    unit.latitude,
    unit.longitude,
    unit.microhabitat,
    unit.vegetation_type_id,
    unit.observations_plant_lifeform,
    unit.observations_plant_size,
    unit.observations_plant_longevity,
    unit.observations_plant_common_name AS common_name,
    unit.observations_plant_use,
    unit.observations_plant_abundance,
    unit.observations_plant_fenology,
    unit.comment,
    subgeneric.genus_id, 
    subgeneric.specie, 
    subgeneric.author_id,
    subgeneric.infraspecific_flag,
    subgeneric.infraspecific_epithet,
    subgeneric.infraspecific_author_id,
    subgeneric.hybrid_flag,
    subgeneric.hybrid_genus_id,
    subgeneric.hybrid_specie,
    subgeneric.hybrid_author_id,
    identification.identification_id,
    identification.identifier_id,
    identification.identifier_role,
    DATE_FORMAT(identification.identification_date,'%e/%c/%Y') AS identification_date,
    identification.preferred_flag,
    identification.name_addendum,
    identification.identification_cualifier,
    specimen.specimen_id,
    specimen.type_status,
    specimen.specimen_status,
    specimen.herbarium_number,
    specimen.type_identification_id,
    herbarium.herbarium_abbreviation 
    FROM identification, subgeneric, 
    unit LEFT JOIN specimen 
    ON unit.unit_id = specimen.unit_id 
    LEFT JOIN herbarium
    ON specimen.herbarium_id = herbarium.herbarium_id
    WHERE $clause
    unit.unit_id <=> identification.unit_id
    AND identification.subgeneric_id <=> subgeneric.subgeneric_id
    ORDER BY identification.preferred_flag DESC
    LIMIT 1      
    },$template,$dbh);
      return @main_list_ref ;
}

sub search_xml_export { # should be improved to show empty identification cases
      my ($clause,$template,$dbh) = @_;
      my @main_list_ref = &main_list(qq{
    SELECT 
    unit.database_id,
    unit.unit_id,
    unit.unit_identifier,
    unit.unit_universal_identifier,
    unit.record_base,
    unit.collector_id,
    unit.collector_field_number,
    unit.collecting_date AS collecting_date,
    unit.project_id,
    unit.database_id,
    unit.municipality_id,
    unit.locality, 
    unit.altitude,
    unit.latitude,
    unit.longitude,
    unit.microhabitat,
    unit.vegetation_type_id,
    unit.observations_plant_lifeform,
    unit.observations_plant_size,
    unit.observations_plant_longevity,
    unit.observations_plant_common_name AS common_name,
    unit.observations_plant_use,
    unit.observations_plant_abundance,
    unit.observations_plant_fenology,
    unit.comment,
    unit.date_mod,
    view_species.subgeneric_id,
    view_species.scientific_name,
    subgeneric.specie,
    genus.genus,
    familia.familia,
    familia.ordo,
    familia.classis,
    familia.phylum,
    regnum.regnum,
    identification.identification_id,
    identification.identifier_id,
    identification.identifier_role,
    identification.identification_date AS identification_date,
    identification.preferred_flag,
    identification.name_addendum,
    identification.identification_cualifier,
    specimen.specimen_id,
    specimen.type_status,
    specimen.specimen_status,
    specimen.herbarium_number,
    specimen.type_identification_id,
    herbarium.herbarium_abbreviation 
    FROM identification, view_species, subgeneric, genus, familia, regnum,
    unit LEFT JOIN specimen 
    ON unit.unit_id = specimen.unit_id 
    LEFT JOIN herbarium
    ON specimen.herbarium_id = herbarium.herbarium_id
    WHERE $clause
    unit.unit_id <=> identification.unit_id
    AND identification.subgeneric_id <=> view_species.subgeneric_id
    AND identification.subgeneric_id <=> subgeneric.subgeneric_id
    AND subgeneric.genus_id <=> genus.genus_id
    AND genus.familia_id <=> familia.familia_id
    AND familia.regnum_id <=> regnum.regnum_id
    ORDER BY identification.preferred_flag DESC
    LIMIT 1      
    },$template,$dbh);
      return @main_list_ref ;
}

sub status_list {
 my ($subgeneric_id,$template,$dbh) = @_;
 my @status_ref_array = &main_list(qq{
    SELECT 
    assignation_status.subgeneric_id,
    assignation_status.status_detail, 
    assignation_status.pubid,
    assignation_status.comment,
    publication.pubabbreviation,
    publication.pubdate,
    publication.pubname
    FROM assignation_status LEFT JOIN publication 
    ON assignation_status.pubid = publication.pubid
    WHERE assignation_status.subgeneric_id = '$subgeneric_id'
    ORDER BY publication.pubdate DESC
  },$template,$dbh); 
  return @status_ref_array;
}


sub specimen_list {
  # query specimen information and returns it 
  # as an array of references of hashes
  my ($unit_id,$template,$dbh) = @_;
  my @specimen_ref_array = &main_list(qq{
    SELECT specimen.type_status,
    specimen.specimen_id, 
    specimen.herbarium_number,
    specimen.type_identification_id,
    specimen.specimen_status,
    specimen.comment,
    specimen.user_id_creation,
    specimen.date_creation,
    herbarium.herbarium_abbreviation 
    FROM specimen LEFT JOIN herbarium 
    ON specimen.herbarium_id = herbarium.herbarium_id
    WHERE specimen.unit_id = '$unit_id'
    ORDER BY specimen.type_status, herbarium.herbarium_abbreviation
  },$template,$dbh); 
  return @specimen_ref_array;
}

sub specimen_image_list {
  # query specimen image information and returns it 
  # as an array of references of hashes
  my ($specimen_id,$template,$dbh) = @_;
  my @image_ref_array = &main_list(qq{
    SELECT specimen_image.specimen_image_id,
    specimen_image.specimen_id, 
    specimen_image.imagen,
    specimen_image.comment,
    specimen_image.user_id_creation,
    specimen_image.date_creation,
    specimen.specimen_status,
    specimen.type_status,
    specimen.herbarium_number,
    specimen.comment AS specimen_comment,
    herbarium.herbarium_abbreviation 
    FROM specimen_image, 
    specimen LEFT JOIN herbarium 
    ON specimen.herbarium_id = herbarium.herbarium_id
    WHERE specimen_image.specimen_id = '$specimen_id'
    AND specimen_image.specimen_id = specimen.specimen_id
    ORDER BY specimen.type_status, specimen_image.specimen_image_id
  },$template,$dbh); 
  return @image_ref_array;
}

sub areas_list {
  # query specimen information and returns it 
  # as an array of references of hashes
  my ($unit_id,$template,$dbh) = @_;
  my @area_ref_array = &main_list(qq{
    SELECT named_area.named_area,
    named_area.named_area_type, 
    named_area.reference_id,
    named_area.comment
    FROM assignation_named_area, named_area 
    WHERE named_area.named_area_id = assignation_named_area.named_area_id
    AND assignation_named_area.unit_id = '$unit_id'
    ORDER BY named_area.named_area
  },$template,$dbh); 
  return @area_ref_array;
}

sub reference_list {
  # query references information and returns it 
  # as an array of references of hashes
  my ($unit_id,$template,$dbh) = @_;
  my @ref_array = &main_list(qq{
    SELECT view_reference.reference,
    view_reference.pubdate,
    assignation_reference.comment
    FROM assignation_reference, view_reference 
    WHERE view_reference.reference_id = assignation_reference.reference_id
    AND assignation_reference.unit_id = '$unit_id'
    ORDER BY view_reference.pubdate, view_reference.reference
  },$template,$dbh); 
  return @ref_array;
}

sub identification_list {
  # query alternative identification information and returns it 
  # as an array of references of hashes
  my ($unit_id,$main_identification_id,$template,$dbh) = @_;
  my @identification_ref_array = &main_list(qq{
    SELECT
    subgeneric.subgeneric_id,
    subgeneric.genus_id, 
    subgeneric.specie, 
    subgeneric.author_id,
    subgeneric.infraspecific_flag,
    subgeneric.infraspecific_epithet,
    subgeneric.infraspecific_author_id,
    subgeneric.hybrid_flag,
    subgeneric.hybrid_genus_id,
    subgeneric.hybrid_specie,
    subgeneric.hybrid_author_id,
    identification.unit_id,
    identification.identification_id,
    identification.identifier_id,
    identification.identifier_role,
    DATE_FORMAT(identification.identification_date,'%e/%c/%Y') AS identification_date,
    identification.preferred_flag,
    identification.stored_under_flag,
    identification.non_flag,
    identification.reference_id,
    identification.name_addendum,
    identification.identification_cualifier,
    identification.user_id_creation,
    identification.date_creation
    FROM identification, subgeneric 
    WHERE 
    identification.subgeneric_id <=> subgeneric.subgeneric_id
    AND
    identification.unit_id = '$unit_id'
    AND 
    identification.identification_id NOT LIKE '$main_identification_id'
    ORDER BY identification.identification_date
  },$template,$dbh);     
  return @identification_ref_array;
}

sub user_list {
	my ($clause,$template,$dbh) = @_;
	# To skip user with user_id =1 condition user.user_id <> '1' is added
	my @user_ref_array = &main_list(qq{
	    SELECT user.user_id, 
	    user.user_login, 
	    user.user_name, 
	    user.institution,
	    user.comment,
	    user.date_mod AS date_reg,
	    user_access.user_access, 
	    user_access.date_mod,
	    login.last_login,
	    login.last_login_host
	    FROM user LEFT JOIN user_access 
	    ON user.user_id = user_access.user_id
	    LEFT JOIN login
	    ON user_access.user_id <=> login.user_id
	    WHERE $clause
	    user.user_id <> '1'
	    GROUP BY user.user_id
	    ORDER BY user.user_name 
     },$template,$dbh);     
	return @user_ref_array;
}

sub user_list_full {
	my ($clause,$template,$dbh) = @_;
	# To skip user with user_id =1 condition user.user_id <> '1' is added
	my @user_ref_array = &main_list(qq{
	    SELECT user.user_id, 
	    user.user_login, 
	    user.user_name,
	    user.date_mod AS date_reg,
	    user_access.user_access, 
	    user_access.user_password,
	    user_access.date_mod,
	    login.last_login,
	    login.last_login_host
	    FROM user LEFT JOIN user_access 
	    ON user.user_id = user_access.user_id
	    LEFT JOIN login
	    ON user_access.user_id <=> login.user_id
	    WHERE $clause
	    user.user_id <> '1'
	    ORDER BY user_access.user_access DESC, user.user_name, login.last_login DESC
	},$template,$dbh);
	return @user_ref_array;
}

sub get_municipality_id_list {
	my ($municipality,$state,$template,$dbh) = @_;
	my $ clause = ();
	if ($municipality) {
		  $clause .= qq{municipality.municipality LIKE '$municipality' AND };
	}
	if ($state) {
		  $clause .= qq{municipality.state LIKE '$state' AND };
	}
	my @municipality_ref_array = &main_list(qq{
	    SELECT municipality.municipality_id, 
	    municipality.state
	    FROM municipality
	    WHERE $clause 1
	},$template,$dbh);
	if (scalar @municipality_ref_array < 1)
	{
		# if array is empty, we can try another time but with %% symbols
		my $municipality_new = &escape_input_2($municipality); # removing existing %
		my $state_new = &escape_input_2($state); # removing existing %
		$ clause = ();
		if ($municipality_new) {
			  $clause .= qq{municipality.municipality LIKE '%$municipality_new%' AND };
		}
		if ($state_new) {
			  $clause .= qq{municipality.state LIKE '%$state_new%' AND };
		}
		@municipality_ref_array = &main_list(qq{
		    SELECT municipality.municipality_id, 
		    municipality.state
		    FROM municipality
		    WHERE $clause 1
		},$template,$dbh);
	}
	return @municipality_ref_array;
}

#=== independent subs return variables ================================================================================= 

sub get_municipality_id {
  my ($municipality,$template,$dbh) = @_;
  my ($municipality_id) = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT municipality_id 
    FROM municipality
    WHERE municipality = '$municipality'
  })  or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute()   or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $municipality_id = $ref_1->{'municipality_id'};
  }
  $sth_1->finish()  or &sql_error_out(&messages('1014'),$template);
  return $municipality_id;
}

sub get_municipality {
  my ($municipality_id,$template,$dbh) = @_;
  my ($municipality,$state,$country) = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT municipality.municipality, 
    municipality.state, country.name
    FROM municipality LEFT JOIN country 
    ON municipality.country_id = country.country_id
    WHERE municipality.municipality_id = '$municipality_id'
  })  or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute()   or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $municipality = $ref_1->{'municipality'};
    $state = $ref_1->{'state'};
    $country = $ref_1->{'name'};
  }
  $sth_1->finish()  or &sql_error_out(&messages('1014'),$template);
  return ($municipality,$state,$country);
}

sub get_family {
  my ($genus_id,$template,$dbh) = @_;
  my $family = undef;
  if (!$genus_id) {return undef;};
  my $sth_1 = $dbh->prepare (qq{
    SELECT familia.familia FROM familia, genus 
    WHERE genus.genus_id = '$genus_id'
    AND genus.familia_id = familia.familia_id
  })  or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute()   or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $family = $ref_1->{'familia'};
  }
  $sth_1->finish()  or &sql_error_out(&messages('1014'),$template);
  return $family;
}

sub get_agent {
  my ($agent_id,$template,$dbh) = @_;
  my $agent = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT agent FROM col_det_agent WHERE agent_id = '$agent_id'
  })  or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $agent = $ref_1->{'agent'};
  }
  $sth_1->finish()  or &sql_error_out(&messages('1014'),$template);
  return $agent;
}

sub get_author {
  my ($author_id,$template,$dbh) = @_;
  my $author = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT author FROM author WHERE author_id = '$author_id'
  })  or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $author = $ref_1->{'author'};
  }
  $sth_1->finish()  or &sql_error_out(&messages('1014'),$template);
  return $author;
}

sub get_genus {
  my ($genus_id,$template,$dbh) = @_;
  my $genus = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT genus FROM genus WHERE genus_id = '$genus_id'
  })  or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $genus = $ref_1->{'genus'};
  }
  $sth_1->finish()  or &sql_error_out(&messages('1014'),$template);
  return $genus;
}

sub get_reference {
  my ($reference_id,$template,$dbh) = @_;
  my ($citation_detail,$publication_abbreviation,$publication_author,$reference,$publication_date) = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT 
    view_reference.reference_id,
    view_reference.reference,
    view_reference.pubabbreviation,
    view_reference.pubdate,
    view_reference.citationdetail,
    view_reference.comment,
    publication.tl2author
    FROM view_reference, publication
    WHERE view_reference.reference_id = '$reference_id'
    AND view_reference.pubid = publication.pubid
  }) or &sql_error_out(&messages('1012'),$template);
   $sth_1->execute() or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $reference = $ref_1->{'reference'};
    $citation_detail = $ref_1->{'citationdetail'};
    $publication_author = $ref_1->{'tl2author'};
    $publication_abbreviation = $ref_1->{'pubabbreviation'};
    $publication_date = $ref_1->{'pubdate'};
  };
  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
  return ($reference,$citation_detail,$publication_abbreviation,$publication_author,$publication_date);
}

sub get_project {
  my ($project_id,$template,$dbh) = @_;
  my $project = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT project FROM project WHERE project_id = '$project_id'
  }) or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute() or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $project = $ref_1->{'project'};
  }
  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
  return $project;
}

sub get_vegetation {
  my ($vegetation_id,$template,$dbh) = @_;
  my $vegetation = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT vegetation FROM vegetation WHERE vegetation_id = '$vegetation_id'
  }) or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute() or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $vegetation = $ref_1->{'vegetation'};
  }
  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
  return $vegetation;
}

sub get_database {
  my ($database_id,$template,$dbh) = @_;
  my $database = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT database_abbreviation, database_name FROM data_base WHERE database_id = '$database_id'
  }) or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute() or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $database = $ref_1->{'database_name'} .' ('. $ref_1->{'database_abbreviation'} . ')';
  }
  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
  return $database;
}

sub get_database_abbreviation {
  my ($database_id,$template,$dbh) = @_;
  my $database_abbreviation = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT database_abbreviation, database_name FROM data_base WHERE database_id = '$database_id'
  }) or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute() or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $database_abbreviation =  $ref_1->{'database_abbreviation'} ;
  }
  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
  return $database_abbreviation;
}

sub get_user_id {
  # sub to get user_id from main database, should be modified to select information about acces provilegies and passwords from another table
  my ($user_login,$template,$dbh) = @_;
  my ($user_id,$user_access,$user_password) = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT user.user_id, user_access.user_access, user_access.user_password 
    FROM user, user_access
    WHERE user.user_login = '$user_login' 
    AND user.user_id = user_access.user_id
    AND user_access.user_password IS NOT NULL
    LIMIT 1
  }) or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $user_id = $ref_1->{'user_id'};
    $user_access = $ref_1->{'user_access'};
    $user_password = $ref_1->{'user_password'};
  }
  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
  return ($user_id,$user_access,$user_password);
}

sub get_user_id_by {
  # sub to get user_id from main database
  my ($user_login,$user_name,$template,$dbh) = @_;
  my $clause = '';
  if (defined $user_login && $user_login) { $clause .= "user_login = '$user_login' AND"; };
  if (defined $user_name && $user_name) { $clause .= "user_name = '$user_name' AND"; };
  my $user_id = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT user_id
    FROM user
    WHERE $clause user_id <> '1'
    LIMIT 1
  }) or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $user_id = $ref_1->{'user_id'};
  }
  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
  return $user_id;
}

sub get_user_name {
  # sub to get user_name
  my ($user_id,$template,$dbh) = @_;
  my ($user_name,$user_institution) = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT user_name, institution 
    FROM user
    WHERE user_id = '$user_id' 
    LIMIT 1
  }) or &sql_error_out(&messages('1012'),$template);
  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
    $user_name = $ref_1->{'user_name'};
    $user_institution = $ref_1->{'institution'};
  }
  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
  return ($user_name,$user_institution);
}

1;