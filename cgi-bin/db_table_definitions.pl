use utf8;
use CGI qw (:standard escapeHTML escape);

require 'tools.pl';
require 'db_table_processing.pl';

# == table specific part =======================================

# Sample field definitions concepts
#		NAME => "ID",
#		TYPE => "field", - simple text field
#		TYPE => "text", - multiple line text field
#		TYPE => "enum", - selector of options with unique resulting value
#		TYPE => "set", - selector of options with multiple resulting values separates by commas
#		TYPE => "checkbox", - checkbox with binary result
#		TYPE => "selector", - selector type (possible with reference to external table)
#		TYPE => "selector_external" - selector type for Ajax style dinamic control
#		TYPE_ENUM => "'IBUG','MEXU','MO','BTC','BMM'", - set of enum or set possible values
#		EDIT => 1,		      # editable
#		LENGTH => 10,	     # maximum length of string
#		SEARCH => "s_id",          # status of search camps s_id, s_1, s_2 or s_3
#		ORDER => 1,		 # order of field in tables, etc.
#		ID => 1,		# flag of "key ID" value
#		VALUE => "some value"	# some predifined value
#		DEFAULT => "Some default text",  # value by default in case that there is no VALUE (empty field)
#		TEST => \&check_text,     # subprogram that check if the value is correct
#		FORMAT => \&escape_input_common,  # subprogram that preformat value
#		REFERENCE_TABLE => name of reference table
#		REFERENCE_ID_NAME => name of ID column in reference table
#		REFERENCE_FIELD_NAME => name of main field column in reference table
						

sub t_vegetation {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		vegetation_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		vegetation  => {
							NAME => "Tipo de vegetacion",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		vegetation_abbreviation  => {
							NAME => "Abreviacion",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 20,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	

	my $clause = &form_clause('vegetation_id','vegetation','vegetation_abbreviation',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);
	
	my $sql_search = qq{SELECT vegetation_id, vegetation, vegetation_abbreviation, reference_id, comment 
					FROM vegetation WHERE $clause 1};
	my $sql_delete = "FROM vegetation WHERE $id_clause"; # should be without DELETE commnad					
	
	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'vegetation',$user_id,$dbh);
	
	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_municipality {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		municipality_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		municipality  => {
							NAME => "Municipio",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		state  => {
							NAME => "Estado",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							
						},
		country_id  => {
							NAME => "ID de pais (referencia a tabla COUNTRY)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "country",
							REFERENCE_ID_NAME => "country_id",
							REFERENCE_FIELD_NAME => "name",
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('municipality_id','municipality','state',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT municipality_id, municipality, state, country_id, comment 
					FROM municipality WHERE $clause 1};
	my $sql_delete = "FROM municipality WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'municipality',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_country {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		country_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		name  => {
							NAME => "Nombre de pais",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		name_english  => {
							NAME => "Nombre de pais en ingles",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		iso3166code  => {
							NAME => "Codigo en estandar ISO-3166",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 2,
							SEARCH =>"s_3",
							ORDER => 4,
							TEST => \&check_text,
							FORMAT => \&escape_input,
							OBLIGATORY => 1,
						},
	);
	my $clause = form_clause('country_id','name','name_english','iso3166code',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT country_id, name, name_english, iso3166code 
					FROM country WHERE $clause 1};
	my $sql_delete = "FROM country WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'country',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_project {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		project_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		project  => {
							NAME => "Proyecto",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 150,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('project_id','project',undef,undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT project_id, project, comment 
					FROM project WHERE $clause 1};
	my $sql_delete = "FROM project WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'project',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_method {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		method_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		method  => {
							NAME => "Método",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		method_type  => {
							NAME => "Tipo de método",
							TYPE => "enum",
							TYPE_ENUM => "'método de colecta','método de preservación','método de identificación','método de estudio','método de georeferenciación','otro tipo de método'",	
							EDIT => 1,
							LENGTH => 100,
							ORDER => 3,
							DEFAULT => "método de colecta",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('method_id','method',undef,undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT method_id, method, method_type, reference_id, comment 
					FROM method WHERE $clause 1};
	my $sql_delete = "FROM method WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'method',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_herbarium {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		herbarium_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		herbarium_abbreviation  => {
							NAME => "Codigo de herbario",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 30,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		herbarium_name  => {
							NAME => "Nombre completo del herbario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_3",
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		location  => {
							NAME => "Ubicación del herbario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_2",
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		institution_id  => {
							NAME => "ID de institución (referencia a tabla INSTITUTION)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 6,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "institution",
							REFERENCE_ID_NAME => "institution_id",
							REFERENCE_FIELD_NAME => "institution_name",
							REFERENCE_SEARCH => 2,
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 7,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('herbarium_id','herbarium_abbreviation','location','herbarium_name',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT herbarium_id, herbarium_abbreviation, herbarium_name, location, institution_id, comment 
					FROM herbarium WHERE $clause 1};
	my $sql_delete = "FROM herbarium WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'herbarium',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_regnum {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		regnum_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		regnum  => {
							NAME => "Nombre de regnum (kindom)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		code_id  => {
							NAME => "ID de referencia a codigo de nomenclatura (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('regnum_id','regnum',undef,undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT regnum_id, regnum, code_id, reference_id, comment 
					FROM regnum WHERE $clause 1};
	my $sql_delete = "FROM regnum WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'regnum',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_genus {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		genus_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		genus  => {
							NAME => "Nombre de genero",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		author_id  => {
							NAME => "ID de referencia a author de genero (referencia a tabla AUTHOR)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "author",
							REFERENCE_ID_NAME => "author_id",
							REFERENCE_FIELD_NAME => "author",
							REFERENCE_SEARCH => 2,
							REFERENCE_SEARCH_EXT => 1,
						},
		familia_id => {
							NAME => "ID de referencia a familia (referencia a tabla FAMILIA)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_3",
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "familia",
							REFERENCE_ID_NAME => "familia_id",
							REFERENCE_FIELD_NAME => "familia",
							REFERENCE_SEARCH => 3,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 5,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 6,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('genus_id','genus','author_id','familia_id',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT genus_id, genus, author_id, familia_id, reference_id, comment 
					FROM genus WHERE $clause 1};
	my $sql_delete = "FROM genus WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'genus',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_familia {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		familia_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		familia  => {
							NAME => "Nombre de familia",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		familia_synonym  => {
							NAME => "Synonimos de familia",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 3,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		familia_author_id  => {
							NAME => "ID de referencia a author de familia (referencia a tabla AUTHOR)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "author",
							REFERENCE_ID_NAME => "author_id",
							REFERENCE_FIELD_NAME => "author",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		ordo  => {
							NAME => "Nombre de ordo",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							SEARCH =>"s_2",
							ORDER => 5,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		classis  => {
							NAME => "Nombre de classis",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							SEARCH =>"s_3",
							ORDER => 6,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		phylum  => {
							NAME => "Nombre de división",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 7,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		regnum_id  => {
							NAME => "ID de regnum (referencia a tabla REGNUM)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 4,
							ORDER => 8,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "regnum",
							REFERENCE_ID_NAME => "regnum_id",
							REFERENCE_FIELD_NAME => "regnum",
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 9,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 10,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('familia_id','familia','ordo','classis',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT familia_id, familia, familia_synonym, familia_author_id, ordo, classis, phylum, regnum_id, reference_id, comment 
					FROM familia WHERE $clause 1};
	my $sql_delete = "FROM familia WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'familia',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_subgeneric {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		subgeneric_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		genus_id  => {
							NAME => "ID de referencia a genero (referencia a tabla GENUS)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "genus",
							REFERENCE_ID_NAME => "genus_id",
							REFERENCE_FIELD_NAME => "genus",
							REFERENCE_SEARCH => 2,
						},
		specie  => {
							NAME => "Nombre de especie",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		author_id  => {
							NAME => "ID de referencia a author de especie (referencia a tabla AUTHOR)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_3",
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "author",
							REFERENCE_ID_NAME => "author_id",
							REFERENCE_FIELD_NAME => "author",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		infraspecific_flag  => {
							NAME => "Prefijo del taxon subespecifico",
							TYPE => "enum",
							TYPE_ENUM => "'','subsp.','var.','subvar.','f.','subf.','f. spec.'",
							DEFAULT => "",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 5,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		infraspecific_epithet  => {
							NAME => "Epitheto subespecifico",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 6,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		infraspecific_author_id  => {
							NAME => "ID de referencia a author del taxon subespecifico (referencia a tabla AUTHOR)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 7,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "author",
							REFERENCE_ID_NAME => "author_id",
							REFERENCE_FIELD_NAME => "author",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		hybrid_flag => {
							NAME => "Prefijo de hybrido o jimera",
							TYPE => "enum",
							TYPE_ENUM => "'','x','+'",
							DEFAULT => "",
							LENGTH => 1,
							EDIT => 1,
							ORDER => 8,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		hybrid_genus_id  => {
							NAME => "ID de referencia a genero de hybrido (referencia a tabla GENUS)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 9,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "genus",
							REFERENCE_ID_NAME => "genus_id",
							REFERENCE_FIELD_NAME => "genus",
							REFERENCE_SEARCH => 2,
						},
		hybrid_specie  => {
							NAME => "Nombre de especie de hybrido",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 10,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		hybrid_author_id  => {
							NAME => "ID de referencia a author de especie de hybrido (referencia a tabla AUTHOR)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 11,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "author",
							REFERENCE_ID_NAME => "author_id",
							REFERENCE_FIELD_NAME => "author",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_reference",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 12,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 13,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('subgeneric_id','genus_id','specie','author_id',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT subgeneric_id, genus_id, specie, author_id, infraspecific_flag, 
					infraspecific_epithet, infraspecific_author_id, hybrid_flag, hybrid_genus_id, 
					hybrid_specie, hybrid_author_id, reference_id, comment 
					FROM subgeneric WHERE $clause 1};
	my $sql_delete = "FROM subgeneric WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'subgeneric',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}


sub t_named_area {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		named_area_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		named_area => {
							NAME => "Nombre de área geografica",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		named_area_type  => {
							NAME => "Tipo de área",
							TYPE => "enum",
							TYPE_ENUM => "'provincia fisiográfica','provincia florística','área protegida o reserva','otra área'",	
							EDIT => 1,
							LENGTH => 100,
							ORDER => 3,
							DEFAULT => "provincia fisiográfica",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('named_area_id','named_area',undef,undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT named_area_id, named_area, named_area_type, reference_id, comment 
					FROM named_area WHERE $clause 1};
	my $sql_delete = "FROM named_area WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'named_area',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_author {
	my ($action,$table,$user_id,$template,$dbh) = @_;
	# definition of column (fields) parameters
	my %f = (
		author_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		author => {
							NAME => "Autor",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		author_xml  => {
							NAME => "XML registro de autor",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		regnum_id  => {
							NAME => "ID de reino taxonomico (referencia a tabla REGNUM)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 4,
							ORDER => 5,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "regnum",
							REFERENCE_ID_NAME => "regnum_id",
							REFERENCE_FIELD_NAME => "regnum",
						},

	);
	my $clause = form_clause('author_id','author',undef,undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT author_id, author, author_xml, reference_id, regnum_id 
					FROM author WHERE $clause 1};
	my $sql_delete = "FROM author WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'author',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_reference {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		reference_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		pubid  => {
							NAME => "ID de publicacion (referencia a tabla PUBLICATION)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "publication",
							REFERENCE_ID_NAME => "pubid",
							REFERENCE_FIELD_NAME => "pubabbreviation",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		citationdetail => {
							NAME => "Especificación de referencia",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('reference_id','pubid','citationdetail',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT reference_id, pubid, citationdetail, comment 
					FROM reference WHERE $clause 1};
	my $sql_delete = "FROM reference WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'reference',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_publication {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		pubid => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		publication_type  => {
							NAME => "Tipo de publicación",
							TYPE => "enum",
							TYPE_ENUM => "'','libro','revista cientifica','serie cientifica','documento de normatividad','publicación de difusión','base de datos en-linea','otro tipo de publicación'",	
							EDIT => 1,
							LENGTH => 100,
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		pubname  => {
							NAME => "Nombre completo de publicación (edición)",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							SEARCH => "s_1",
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		pubabbreviation => {
							NAME => "Abbreviacion de publicación (edición)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 150,
							SEARCH =>"s_2",
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		locnumber => {
							NAME => "Locnumber",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 9,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		tl2author => {
							NAME => "TL2author",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							SEARCH =>"s_3",
							ORDER => 5,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		tl2number => {
							NAME => "TL2number",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 20,
							ORDER => 7,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		bphnumber => {
							NAME => "BPHnumber",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 8,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},			
		pubdate => {
							NAME => "Fecha de publicación",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 6,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},	
		isbn => {
							NAME => "ISBN",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 10,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},	
		issn => {
							NAME => "ISSN",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 11,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 12,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('pubid','pubname','pubabbreviation','tl2author',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT pubid, publication_type, pubname, pubabbreviation, tl2author, tl2number, locnumber, bphnumber, pubdate, issn, isbn, comment 
					FROM publication WHERE $clause 1};
	my $sql_delete = "FROM publication WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'publication',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_teams {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		team_person_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		team_id => {
							NAME => "ID de grupo",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
						},
		person_id => {
							NAME => "ID de persona (referencia a tabla PERSONS)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "persons",
							REFERENCE_ID_NAME => "person_id",
							REFERENCE_FIELD_NAME => "person_string",
							REFERENCE_SEARCH => 2,
							REFERENCE_SEARCH_EXT => 1,
						},
		leader_flag => {
							NAME => "Flag de orden en grupo (2 - leader, 1 - miembro común, 0 - ultimo)",
							TYPE => "enum",
							TYPE_ENUM => "'0','1','2'",
							DEFAULT => "1",
							LENGTH => 1,
							EDIT => 1,
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},						
	);
	my $clause = form_clause('team_person_id','team_id','person_id',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT team_person_id, team_id, person_id, leader_flag, comment
					FROM teams WHERE $clause 1};
	my $sql_delete = "FROM teams WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'teams',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_persons {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		person_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		person_string  => {
							NAME => "Nombre de investigador o grupo",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 150,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		institution_id => {
							NAME => "ID de institution (referencia a tabla INSTITUTION)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_2",
							ORDER => 3,
							DEFAULT => 1,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "institution",
							REFERENCE_ID_NAME => "institution_id",
							REFERENCE_FIELD_NAME => "institution_name",
							REFERENCE_SEARCH => 2,
							REFERENCE_SEARCH_EXT => 1,
						},
		person_xml  => {
							NAME => "XML registro de persona",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('person_id','person_string','institution_id',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT person_id, person_string, institution_id, person_xml, comment
					FROM persons WHERE $clause 1};
	my $sql_delete = "FROM persons WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'persons',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_institution {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		institution_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		institution_name  => {
							NAME => "Nombre de institución",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 250,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		country_id  => {
							NAME => "ID de pais (referencia a tabla COUNTRY)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "country",
							REFERENCE_ID_NAME => "country_id",
							REFERENCE_FIELD_NAME => "name",
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('institution_id','institution_name','country_id',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT institution_id, institution_name, country_id, comment 
					FROM institution WHERE $clause 1};
	my $sql_delete = "FROM institution WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'institution',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_user {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		user_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		user_name  => {
							NAME => "Nombre completo del usuario",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		user_login  => {
							NAME => "Login del usuario",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 30,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_text,
							FORMAT => \&escape_input,
						},
		institution  => {
							NAME => "Institución (afilación)",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		date_mod  => {
							NAME => "Fecha de modificación",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 10,
							SEARCH =>"s_3",
							ORDER => 6,
							TEST => \&check_date,
							FORMAT => \&escape_date,
						},
	);
	my $clause = form_clause('user_id','user_name','user_login','date_mod',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT user_id, user_name, user_login, institution, comment, date_mod
					FROM user WHERE $clause 1};
	my $sql_delete = "FROM user WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'user',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_assignation_named_area {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		assignation_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_id  => {
							NAME => "ID de registro (referencia a tabla UNIT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		named_area_id  => {
							NAME => "ID de unidad geografica (referencia a tabla NAMED_AREA)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "named_area",
							REFERENCE_ID_NAME => "named_area_id",
							REFERENCE_FIELD_NAME => "named_area",
							REFERENCE_SEARCH_EXT => 1,
						},
	);
	my $clause = form_clause('assignation_id','unit_id','named_area_id',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT assignation_id, unit_id, named_area_id 
					FROM assignation_named_area WHERE $clause 1};
	my $sql_delete = "FROM assignation_named_area WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'assignation_named_area',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_assignation_reference {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		assignation_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_id  => {
							NAME => "ID de registro (referencia a tabla UNIT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		reference_id  => {
							NAME => "ID de referencia bibliográfica (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario de asignación de referencia",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('assignation_id','unit_id','reference_id','comment',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT assignation_id, unit_id, reference_id, comment 
					FROM assignation_reference WHERE $clause 1};
	my $sql_delete = "FROM assignation_reference WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'assignation_reference',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_assignation_status {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		status_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		subgeneric_id => {
							NAME => "ID de nombre cientifico (referencia a tabla SUBGENERIC)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_species",
							REFERENCE_ID_NAME => "subgeneric_id",
							REFERENCE_FIELD_NAME => "scientific_name",
							SEARCH => "s_3",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		pubid  => {
							NAME => "ID de documento normativo (referencia a registros selectos de tabla PUBLICATION)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_1",
							ORDER => 4,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_publication_normatividad",
							REFERENCE_ID_NAME => "pubid",
							REFERENCE_FIELD_NAME => "publication_string",
						},
		status_detail => {
							NAME => "Especificación de estatus",
#							TYPE => "field",  # temporalmente, para comodidad de captura, en realidad estos valores deben ser opciones, pero no unicas
							TYPE => "enum",
							TYPE_ENUM => "'',
										'Pr (sujeta a protección especial), endémica',
										'Pr (sujeta a protección especial), no-endémica',
										'P (en peligro de extinción), endémica',
										'P (en peligro de extinción), no-endémica',
										'A (amenazada), endémica',
										'A (amenazada), no-endémica',
										'R (rara), endémica',
										'R (rara), no-endémica',
										'E (probablemente extinta), endémica',
										'Apéndice I',
										'Apéndice II',
										'Apéndice III',
										'FALTAN VALORES DE LISTA ROJA - bajo construcción',
										",
							EDIT => 1,
							LENGTH => 50,
							SEARCH =>"s_2",
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 6,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('status_id','pubid','status_detail','subgeneric_id',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT status_id, subgeneric_id, pubid, status_detail, comment 
					FROM assignation_status WHERE $clause 1};
	my $sql_delete = "FROM assignation_status WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'assignation_status',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_identification {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		identification_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_id  => {
							NAME => "ID de registro (referencia a tabla UNIT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		subgeneric_id  => {
							NAME => "ID de taxon subgenerico (referencia a tabla SUBGENERIC)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_species",
							REFERENCE_ID_NAME => "subgeneric_id",
							REFERENCE_FIELD_NAME => "scientific_name", # view with scientific name created here instead of this reference
							REFERENCE_SEARCH => 3,
						},
		identifier_role => {
							NAME => "Función de identificador (det. - determino, conf. - confirmo, def. - identificación de tipo)",
							TYPE => "enum",
							TYPE_ENUM => "'','det.','conf.','def.'",
							EDIT => 1,
							LENGTH => 5,
							ORDER => 4,
							DEFAULT => "det.",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		identifier_id  => {
							NAME => "ID de identificador (referencia a tabla COL_DET_AGENT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_3",
							ORDER => 5,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "col_det_agent",
							REFERENCE_ID_NAME => "agent_id",
							REFERENCE_FIELD_NAME => "agent",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		identification_date  => {
							NAME => "Fecha de identificación (AAAA-MM-DD)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 6,
							TEST => \&check_date,
							FORMAT => \&escape_date,
						},
		identification_cualifier => {
							NAME => "Cualificador de identificacion",
							TYPE => "enum",
							TYPE_ENUM => "'','aff.','cf.','vel aff.'",
							EDIT => 1,
							LENGTH => 8,
							ORDER => 7,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		name_addendum => {
							NAME => "Addendum de taxon",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 20,
							ORDER => 8,
							TEST => \&check_text,
							FORMAT => \&escape_input_common
						},
		identification_method_id  => {
							NAME => "ID de metodo de identificación (referencia a tabla METHOD)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 9,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_method_identification",
							REFERENCE_ID_NAME => "method_id",
							REFERENCE_FIELD_NAME => "method",
							REFERENCE_SEARCH_EXT => 1,
						},
		identification_quality => {
							NAME => "Calidad de identificación (de 0 a 9)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 1,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
						},
		identification_verification_xml => {
							NAME => "XML de vereficación de identificación",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 11,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		preferred_flag => {
							NAME => "Señal de identificación preferida",
							TYPE => "checkbox",
							EDIT => 1,
							LENGTH => 1,
							ORDER => 10,
							DEFAULT => "1",
							TEST => \&check_number,
							FORMAT => \&format_flag,
						},
		stored_under_flag => {
							NAME => "Señal de identificación para almacenamiento del especimen",
							TYPE => "checkbox",
							EDIT => 1,
							LENGTH => 1,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&format_flag,
						},
		non_flag => {
							NAME => "Señal de identificación negativa",
							TYPE => "checkbox",
							EDIT => 1,
							LENGTH => 1,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&format_flag,
						},
		result_role => {
							NAME => "Used to designate the role of the identification result (e.g. substrate, isolate, host, parasite, etc.)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 20,
							ORDER => 16,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 17,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 18,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		
	);
	my $clause = form_clause('identification_id','unit_id','subgeneric_id','identifier_id',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT identification_id, unit_id, subgeneric_id, identifier_role, identifier_id,
					identification_date, identification_cualifier, name_addendum, identification_method_id ,
					identification_quality, identification_verification_xml, preferred_flag,
					stored_under_flag, non_flag, result_role, reference_id, comment
					FROM identification WHERE $clause 1};
	my $sql_delete = "FROM identification WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'identification',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_specimen {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		specimen_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_id  => {
							NAME => "ID de registro (referencia a tabla UNIT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		herbarium_id  => {
							NAME => "ID de herbario (referencia a tabla HERBARIUM)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "herbarium",
							REFERENCE_ID_NAME => "herbarium_id",
							REFERENCE_FIELD_NAME => "herbarium_abbreviation",
						},
		herbarium_number => {
							NAME => "Numero o código del espécimen en herbario",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 30,
							SEARCH =>"s_3",
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		herbarium_xml => {
							NAME => "XML relacionado con posivción de espécimen en herbario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},

		specimen_status => {
							NAME => "Estatus de espécimen",
							TYPE => "enum",
							TYPE_ENUM => "'','incorporado a colección','preparado para envío a colección','enviado a colección','en proceso de incorporación a colección','en proceso de intercambio con otra colección','extraviado','destruido'",	
							EDIT => 1,
							LENGTH => 40,
							ORDER => 7,
							DEFAULT => "incorporado a colección",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		type_status => {
							NAME => "Estatus de tipo de espécimen",
							TYPE => "enum",
							TYPE_ENUM => "'','holotypus','isotypus','isolectotypus','lectotypus','neotypus','paratypus','isoparatypus','syntypus','isosyntypus','topotypus','typus','clonotypus','cotypus'",	
							EDIT => 1,
							LENGTH => 20,
							ORDER => 8,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		type_identification_id  => {
							NAME => "ID de identificación de tipo (referencia a tabla IDENTIFICATION)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 9,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_type_identifications",
							REFERENCE_ID_NAME => "identification_id",
							REFERENCE_FIELD_NAME => "scientific_name", # view with scientific name shoud be created here instead of this reference
							REFERENCE_SEARCH => 3,
						},
		type_verification_xml=> {
							NAME => "XML relacionado con estatus de tipo de espécimen",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 10,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		specimen_xml=> {
							NAME => "XML relacionado con propio espécimen",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 11,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 12,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('specimen_id','unit_id','herbarium_id','herbarium_number',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT specimen_id, unit_id, herbarium_id, herbarium_number, 
					herbarium_xml, specimen_status, type_status, type_identification_id, 
					type_verification_xml, specimen_xml, comment
					FROM specimen WHERE $clause 1};
	my $sql_delete = "FROM specimen WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'specimen',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_unit {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		unit_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_identifier => {
							NAME => "Numero o código de registro",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		unit_universal_identifier => {
							NAME => "Numero o código universal de registro",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		database_id  => {
							NAME => "ID de base de datos (referencia bajo construcción)",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							ORDER => 4,
							DEFAULT => "0",
							TEST => \&check_number,
							#OBLIGATORY => 1, # obligatory, but may be no necessarity to indicate that now
							FORMAT => \&escape_numeric_input,
							#REFERENCE_TABLE => "data_base",
						},
		record_base => {
							NAME => "Base de registro",
							TYPE => "enum",
							TYPE_ENUM => "'','espécimen preservado','espécimen vivo','espécimen fósil','fotografía','diapositiva','dibujo','fotocopia de espécimen','observación humana','observación automatizada','objeto multimedia','publicacion','otro espécimen'",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 5,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		collector_id => {
							NAME => "ID de colector (referencia a tabla COL_DET_AGENT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_1",
							ORDER => 6,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "col_det_agent",
							REFERENCE_ID_NAME => "agent_id",
							REFERENCE_FIELD_NAME => "agent",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		collector_field_number => {
							NAME => "Numero de colecta asignado por colector",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 25,
							SEARCH =>"s_2",	
							ORDER => 7,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		collecting_date  => {
							NAME => "Fecha de colecta (AAAA-MM-DD)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_3",
							ORDER => 8,
							TEST => \&check_date,
							FORMAT => \&escape_date,
						},
		collecting_method_id  => {
							NAME => "ID de método de colecta (referencia a tabla METHOD)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 9,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_method_collecting",
							REFERENCE_ID_NAME => "method_id",
							REFERENCE_FIELD_NAME => "method",
							REFERENCE_SEARCH_EXT => 1,
						},
		project_id  => {
							NAME => "ID de proyecto de colecta (referencia a tabla PROJECT)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "project",
							REFERENCE_ID_NAME => "project_id",
							REFERENCE_FIELD_NAME => "project",
							REFERENCE_SEARCH_EXT => 1,
						},
		municipality_id  => {
							NAME => "ID de municipio (referencia a tabla MUNICIPALITY)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 11,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "municipality",
							REFERENCE_ID_NAME => "municipality_id",
							REFERENCE_FIELD_NAME => "municipality",
							REFERENCE_SEARCH => 2,
							REFERENCE_SEARCH_EXT => 1,
						},
		locality => {
							NAME => "Localidad",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 12,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		altitude => {
							NAME => "Altitud (msnm.)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 13,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
						},
		longitude => {
							NAME => "Longitud (Grados con fracción)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 14,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},						
		latitude => {
							NAME => "Latitud (Grados con fracción)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 15,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},							
		georeferencing_xml => {
							NAME => "XML relacionado con georeferenciación",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 16,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		gathering_xml => {
							NAME => "XML relacionado con evento de colecta",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 17,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		vegetation_type_id  => {
							NAME => "ID de tipod vegetación (referencia a tabla VEGETATION)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 18,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "vegetation",
							REFERENCE_ID_NAME => "vegetation_id",
							REFERENCE_FIELD_NAME => "vegetation",
							REFERENCE_SEARCH_EXT => 1,
						},
		other_species => {
							NAME => "Otros especies observados",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 19,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		microhabitat => {
							NAME => "Microhábitat",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 20,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_locality_xml => {
							NAME => "XML relacionado con observaciones en localidad de colecta",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 21,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		observations_plant_lifeform => {
							NAME => "Observación durante la colecta: forma de crecimiento",
							TYPE => "enum",
							TYPE_ENUM => "'','acuática flotante','acuática sumergida','arborescente','arbustiva','bejuco','enredadera herbácea','enredadera leñosa','epífita','herbácea','parásita','rastrera','rupícola','trepadora'",	
							EDIT => 1,
							LENGTH => 50,
							ORDER => 22,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_size => {
							NAME => "Observación durante la colecta: tamaño del organismo (m)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 20,
							ORDER => 23,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},	
		observations_plant_longevity => {
							NAME => "Observación durante la colecta: longevidad",
							TYPE => "enum",
							TYPE_ENUM => "'','anual','bianual','perenne'",	
							EDIT => 1,
							LENGTH => 20,
							ORDER => 24,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},	
		observations_plant_common_name => {
							NAME => "Nombre comun",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 75,
							ORDER => 25,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_use => {
							NAME => "Uso",
							TYPE => "set",
							TYPE_ENUM => "'medicinal','alimento','madera/muebles','ornamental','combustible','forrajero','ceremonial','artesanía','cerca viva','colorante','veneno','otro uso'",	
							EDIT => 1,
							LENGTH => 20,
							ORDER => 26,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},	
		observations_plant_abundance => {
							NAME => "Observación durante la colecta: abundancia",
							TYPE => "enum",
							TYPE_ENUM => "'','abundante','abundante y frecuente','común','escasa','frecuente','muy abundante','muy común','muy escasa','muy frecuente','muy rara','poco abundante','poco común','poco frecuente','rara','regular','ocasional'",	
							EDIT => 1,
							LENGTH => 20,
							ORDER => 27,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_fenology => {
							NAME => "Observación durante la colecta: fenología",
							TYPE => "set",
							TYPE_ENUM => "'vegetativa','en flor','en fruto','con conos femeninos','con conos masculinos','con soros','con estróbilos','en botón floral'",	
							EDIT => 1,
							LENGTH => 30,
							ORDER => 28,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_nutrition => {
							NAME => "Observación durante la colecta: nutrición del organismo",
							TYPE => "enum",
							TYPE_ENUM => "'','autótrofa','hemi-/parásita','parásita','saprófita'",	
							EDIT => 1,
							LENGTH => 30,
							ORDER => 29,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_xml => {
							NAME => "XML relacionado con observaciones en del organismo colectado",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 30,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},	
		unit_xml => {
							NAME => "XML relacionado con registro",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 31,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},	
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 32,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('unit_id','collector_id','collector_field_number','collecting_date',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT unit_id, unit_identifier, unit_universal_identifier, 
					database_id, record_base, collector_id, collector_field_number,
					collecting_date, collecting_method_id, project_id, municipality_id,
					locality, altitude, longitude, latitude, georeferencing_xml,
					gathering_xml, vegetation_type_id, other_species, microhabitat,
					observations_locality_xml, observations_plant_lifeform,
					observations_plant_size, observations_plant_longevity, 
					observations_plant_common_name, observations_plant_use, 
					observations_plant_abundance, observations_plant_fenology, 
					observations_plant_nutrition, observations_plant_xml, 
					unit_xml, comment
					FROM unit WHERE $clause 1};
	my $sql_delete = "FROM unit WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'unit',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub t_specimen_image {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		specimen_image_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		specimen_id => {
							NAME => "ID del especimen (referencia a tabla SPECIMEN)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_1",
							ORDER => 2,
							OBLIGATORY => 1,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_specimen",
							REFERENCE_ID_NAME => "specimen_id",
							REFERENCE_FIELD_NAME => "specimen_string",
							REFERENCE_SEARCH => 3,
						},
		imagen  => {
							NAME => "Cadena de especificación de imagen",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 30,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_image_basename,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							SEARCH =>"s_3",
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('specimen_image_id','specimen_id','imagen','comment',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT specimen_image_id, specimen_id, imagen, comment 
					FROM specimen_image WHERE $clause 1};
	my $sql_delete = "FROM specimen_image WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'specimen_image',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_user {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		user_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		user_name  => {
							NAME => "Nombre completo del usuario",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 100,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		user_login  => {
							NAME => "Login del usuario",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 30,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_text,
							FORMAT => \&escape_input,
						},
		institution  => {
							NAME => "Institución",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		date_mod  => {
							NAME => "Fecha de modificación",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 10,
							SEARCH =>"s_3",
							ORDER => 6,
							TEST => \&check_date,
							FORMAT => \&escape_date,
						},
		access  => {
							NAME => "Modo de acceso registrado",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 20,
							ORDER => 7,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		date_access_mod  => {
							NAME => "Fecha de modificación del cuenta de acceso",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 10,
							ORDER => 8,
							TEST => \&check_date,
							FORMAT => \&escape_date,
						},
	);
	my $clause = form_clause('user_id','user_name','user_login','date_mod',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT user_id, user_name, user_login, institution, comment, date_mod, access, date_access_mod
					FROM view_user WHERE $clause 1};
	my $sql_delete = "FROM user WHERE $id_clause"; # delete only from user, but not from user_access

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'user',$user_id,$dbh); # trick: insert and update should be of the user table, viewsare not insertable objects

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_specimen_full {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	my %f = (
		specimen_id => {
							NAME => "ID de especimen",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_string => {
							NAME => "Referencia a evento de colecta original (datos de tabla UNIT)",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_1",
							ORDER => 2,
						},
		unit_id  => {
							NAME => "ID de evento de colecta (referencia numerica a tabla UNIT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							REFERENCE_SEARCH => 3,
						},
		herbarium_abbreviation => {
							NAME => "Herbario original (datos de tabla HERBARIUM)",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_3",
							ORDER => 4,
						},
		herbarium_id  => {
							NAME => "Herbarium con ID correspondiente (ID de referencia a tabla HERBARIUM)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 5,
							DEFAULT => "1",
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "herbarium",
							REFERENCE_ID_NAME => "herbarium_id",
							REFERENCE_FIELD_NAME => "herbarium_abbreviation",
						},
		herbarium_number => {
							NAME => "Numero o código del espécimen en herbario",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 30,
							ORDER => 6,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		herbarium_xml => {
							NAME => "XML relacionado con posivción de espécimen en herbario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 7,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		specimen_status => {
							NAME => "Estatus de espécimen",
							TYPE => "enum",
							TYPE_ENUM => "'','incorporado a colección','preparado para envío a colección','enviado a colección','en proceso de incorporación a colección','en proceso de intercambio con otra colección','extraviado','destruido'",	
							EDIT => 1,
							LENGTH => 40,
							ORDER => 8,
							DEFAULT => "incorporado a colección",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		type_status => {
							NAME => "Estatus de tipo de espécimen",
							TYPE => "enum",
							TYPE_ENUM => "'','holotypus','isotypus','isolectotypus','lectotypus','neotypus','paratypus','isoparatypus','syntypus','isosyntypus','topotypus','typus','clonotypus','cotypus'",	
							EDIT => 1,
							LENGTH => 20,
							ORDER => 9,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		type_identification_id  => {
							NAME => "ID de identificación de tipo (referencia a tabla IDENTIFICATION)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_type_identifications",
							REFERENCE_ID_NAME => "identification_id",
							REFERENCE_FIELD_NAME => "scientific_name", # view with scientific name shoud be created here instead of this reference
							REFERENCE_SEARCH => 3,

						},
		type_verification_xml=> {
							NAME => "XML relacionado con estatus de tipo de espécimen",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 11,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		specimen_xml=> {
							NAME => "XML relacionado con propio espécimen",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 12,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 13,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('specimen_id','unit_string','unit_id','herbarium_abbreviation',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT specimen_id, unit_id, unit_string, herbarium_abbreviation, herbarium_id, herbarium_number, 
					herbarium_xml, specimen_status, type_status, type_identification_id, 
					type_verification_xml, specimen_xml, comment
					FROM view_specimen_full WHERE $clause 1};
	my $sql_delete = "FROM specimen WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'specimen',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_specimen {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	my %f = (
		specimen_id => {
							NAME => "ID de especimen",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_string => {
							NAME => "Referencia a evento de colecta original (datos de tabla UNIT)",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_1",
							ORDER => 2,
							SKIP => 1,
						},
		unit_id  => {
							NAME => "ID de evento de colecta (referencia numerica a tabla UNIT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							REFERENCE_SEARCH => 3,
						},
		herbarium_abbreviation => {
							NAME => "Herbario original (datos de tabla HERBARIUM)",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_3",
							ORDER => 4,
							SKIP => 1,
						},
		herbarium_id  => {
							NAME => "Herbarium con ID correspondiente (ID de referencia a tabla HERBARIUM)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 5,
							DEFAULT => "1",
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "herbarium",
							REFERENCE_ID_NAME => "herbarium_id",
							REFERENCE_FIELD_NAME => "herbarium_abbreviation",
						},
		herbarium_number => {
							NAME => "Numero o código del espécimen en herbario",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 30,
							ORDER => 6,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		herbarium_xml => {
							NAME => "XML relacionado con posivción de espécimen en herbario",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 1024,
							ORDER => 7,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		specimen_status => {
							NAME => "Estatus de espécimen",
							TYPE => "enum",
							TYPE_ENUM => "'','incorporado a colección','preparado para envío a colección','enviado a colección','en proceso de incorporación a colección','en proceso de intercambio con otra colección','extraviado','destruido'",	
							EDIT => 1,
							LENGTH => 40,
							ORDER => 8,
							DEFAULT => "incorporado a colección",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		type_status => {
							NAME => "Estatus de tipo de espécimen",
							TYPE => "enum",
							TYPE_ENUM => "'','holotypus','isotypus','isolectotypus','lectotypus','neotypus','paratypus','isoparatypus','syntypus','isosyntypus','topotypus','typus','clonotypus','cotypus'",	
							EDIT => 0,
							LENGTH => 20,
							ORDER => 9,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		type_identification_id  => {
							NAME => "ID de identificación de tipo (referencia a tabla IDENTIFICATION)",
							TYPE => "selector_external",
							EDIT => 0,
							LENGTH => 10,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_type_identifications", # instead of view_type_identification we should use here any identification, according to the fact that there is no assignation of type identification initially (!!! may bve should be redisegned in database structure to reffer to subeneric)
							REFERENCE_ID_NAME => "identification_id",
							REFERENCE_FIELD_NAME => "scientific_name", # view with scientific name shoud be created here instead of this reference
							REFERENCE_SEARCH => 3,
						},
		type_verification_xml=> {
							NAME => "XML relacionado con estatus de tipo de espécimen",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 1024,
							ORDER => 11,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		specimen_xml=> {
							NAME => "XML relacionado con propio espécimen",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 1024,
							ORDER => 12,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 13,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('specimen_id','unit_string','unit_id','herbarium_abbreviation',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT specimen_id, unit_id, unit_string, herbarium_abbreviation, herbarium_id, herbarium_number, 
					herbarium_xml, specimen_status, type_status, type_identification_id, 
					type_verification_xml, specimen_xml, comment
					FROM view_specimen_full WHERE $clause 1};
	my $sql_delete = "FROM specimen WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'specimen',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_species {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		subgeneric_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		scientific_name => {
							NAME => "Nombre cientifico",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_1",
							ORDER => 2,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 3,
							SEARCH => "s_2",
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 4,
							SEARCH => "s_3",
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		
	);
	my $clause = form_clause('subgeneric_id','scientific_name','reference_id','comment',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT subgeneric_id, scientific_name, reference_id, comment
					FROM view_species WHERE $clause 1};
	my $sql_delete = "FROM subgeneric WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'subgeneric',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_type_identifications {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		identification_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		scientific_name => {
							NAME => "Nombre cientifico",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_1",
							ORDER => 2,
						},
		identification_cualifier => {
							NAME => "Cualificador de identificacion",
							TYPE => "enum",
							TYPE_ENUM => "'','aff.','cf.','vel aff.'",
							EDIT => 0,
							LENGTH => 8,
							ORDER => 3,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		name_addendum => {
							NAME => "Addendum de taxon",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 20,
							ORDER => 4,
							TEST => \&check_text,
							FORMAT => \&escape_input_common
						},
		identifier_id  => {
							NAME => "ID de identificador (referencia a tabla COL_DET_AGENT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 5,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "col_det_agent",
							REFERENCE_ID_NAME => "agent_id",
							REFERENCE_FIELD_NAME => "agent",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		identification_date  => {
							NAME => "Fecha de identificación (AAAA-MM-DD)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 6,
							TEST => \&check_date,
							FORMAT => \&escape_date,
						},
		identification_method_id  => {
							NAME => "ID de metodo de identificación (referencia a tabla METHOD)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 7,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_method_identification",
							REFERENCE_ID_NAME => "method_id",
							REFERENCE_FIELD_NAME => "method",
							REFERENCE_SEARCH_EXT => 1,
						},
		identification_quality => {
							NAME => "Calidad de identificación (de 0 a 9)",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 1,
							ORDER => 8,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 9,
							SEARCH => "s_2",
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 10,
							SEARCH => "s_3",
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		
	);
	my $clause = form_clause('identification_id','scientific_name','reference_id','comment',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT identification_id, scientific_name, identification_cualifier, name_addendum, identification_quality, identification_method_id, identifier_id, identification_date,  reference_id, comment
					FROM view_type_identifications WHERE $clause 1};
	my $sql_delete = "FROM identification WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'identification',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_normal_identifications {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		identification_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_string => {
							NAME => "Referencia a evento de colecta",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_1",
							ORDER => 2,
							SKIP => 1,
						},
		unit_id  => {
							NAME => "ID de evento de colecta (referencia numerica a tabla UNIT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							REFERENCE_SEARCH => 3,
						},
		scientific_name => {
							NAME => "Nombre cientifico",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_3",
							ORDER => 4,
							SKIP => 1,
						},
		subgeneric_id => {
							NAME => "ID de nombre cientifico (referencia a tabla SUBGENERIC)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 5,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_species",
							REFERENCE_ID_NAME => "subgeneric_id",
							REFERENCE_FIELD_NAME => "scientific_name",
							REFERENCE_SEARCH => 3,
						},
		identification_cualifier => {
							NAME => "Cualificador de identificacion",
							TYPE => "enum",
							TYPE_ENUM => "'','aff.','cf.','vel aff.'",
							EDIT => 1,
							LENGTH => 8,
							ORDER => 6,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		name_addendum => {
							NAME => "Addendum de taxon",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 20,
							ORDER => 7,
							TEST => \&check_text,
							FORMAT => \&escape_input_common
						},
		identifier_role => {
							NAME => "Función de identificador (det. - determino, conf. - confirmo, def. - identificación de tipo)",
							TYPE => "enum",
							TYPE_ENUM => "'','det.','conf.','def.'",
							EDIT => 1,
							LENGTH => 5,
							ORDER => 8,
							DEFAULT => "det.",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		identifier_id  => {
							NAME => "ID de identificador (referencia a tabla COL_DET_AGENT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 9,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "col_det_agent",
							REFERENCE_ID_NAME => "agent_id",
							REFERENCE_FIELD_NAME => "agent",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		identification_date  => {
							NAME => "Fecha de identificación (AAAA-MM-DD)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 10,
							TEST => \&check_date,
							FORMAT => \&escape_date,
						},
		identification_method_id  => {
							NAME => "ID de metodo de identificación (referencia a tabla METHOD)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 11,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_method_identification",
							REFERENCE_ID_NAME => "method_id",
							REFERENCE_FIELD_NAME => "method",
							REFERENCE_SEARCH_EXT => 1,
						},
		identification_quality => {
							NAME => "Calidad de identificación (de 0 a 9)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 1,
							ORDER => 12,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
						},
		reference_id => {
							NAME => "ID de fuente de referencia (referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 13,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 14,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		preferred_flag => {
							NAME => "Señal de identificación preferida",
							TYPE => "checkbox",
							EDIT => 1,
							LENGTH => 1,
							ORDER => 15,
							DEFAULT => "1",
							TEST => \&check_number,
							FORMAT => \&format_flag,
						},
		stored_under_flag => {
							NAME => "Señal de identificación para almacenamiento del especimen",
							TYPE => "checkbox",
							EDIT => 1,
							LENGTH => 1,
							ORDER => 16,
							TEST => \&check_number,
							FORMAT => \&format_flag,
						},
		non_flag => {
							NAME => "Señal de identificación negativa",
							TYPE => "checkbox",
							EDIT => 1,
							LENGTH => 1,
							ORDER => 17,
							TEST => \&check_number,
							FORMAT => \&format_flag,
						},
	);
	my $clause = form_clause('identification_id','unit_string','unit_id','scientific_name',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT identification_id, subgeneric_id, scientific_name, 
					unit_id, unit_string, identification_cualifier, 
					name_addendum, identification_quality, identification_method_id, identifier_id, 
					identification_date, identifier_role, reference_id, comment,
					preferred_flag, stored_under_flag, non_flag
					FROM view_normal_identifications WHERE $clause 1};
	my $sql_delete = "FROM identification WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'identification',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}


sub v_assignation_named_area {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		assignation_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_id  => {
							NAME => "ID de evento de colecta (referencia numerica a tabla UNIT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							REFERENCE_SEARCH => 3,
						},
		named_area_id  => {
							NAME => "Nombre del unidad geografica con ID correspondiente (ID de referencia a tabla NAMED_AREA)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_assignation_named_area",		# ???
							REFERENCE_ID_NAME => "named_area_id",
							REFERENCE_FIELD_NAME => "named_area_with_type",
						},
	);
	my $clause = form_clause('assignation_id','unit_id','named_area_id',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT assignation_id, unit_id, named_area_id 
					FROM assignation_named_area WHERE $clause 1};
	my $sql_delete = "FROM assignation_named_area WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'assignation_named_area',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_assignation_reference {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		assignation_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_id  => {
							NAME => "ID de evento de colecta (referencia numerica a tabla UNIT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							REFERENCE_SEARCH => 3,
						},
		reference_id  => {
							NAME => "Nombre de referencia bibliográfica con ID correspondiente (ID de referencia a tabla REFERENCE)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "view_reference",
							REFERENCE_ID_NAME => "reference_id",
							REFERENCE_FIELD_NAME => "reference",
							REFERENCE_SEARCH => 3,
						},
		comment  => {
							NAME => "Comentario de asignación de referencia",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 4,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		reference_comment  => {
							NAME => "Comentario de referencia",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 256,
							ORDER => 5,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('assignation_id','unit_id','reference_id',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT assignation_id, unit_id, reference_id, reference_id, comment, reference_comment
					FROM view_assignation_reference WHERE $clause 1};
	my $sql_delete = "FROM assignation_reference WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'assignation_reference',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_reference {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	my %f = (
		reference_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		reference => {
							NAME => "Definición original de referencia bibliográfica",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							ORDER => 2,
							SKIP => 1,
						},
		pubid  => {
							NAME => "ID de publicacion (referencia a tabla PUBLICATION)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_1",
							ORDER => 2,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							OBLIGATORY => 1,
							REFERENCE_TABLE => "publication",
							REFERENCE_ID_NAME => "pubid",
							REFERENCE_FIELD_NAME => "pubabbreviation",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		citationdetail => {
							NAME => "Especificación de referencia",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							SEARCH =>"s_2",
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 4,
							SEARCH =>"s_3",
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('reference_id','pubid','citationdetail','comment',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT reference_id, reference, pubid, citationdetail, comment 
					FROM view_reference WHERE $clause 1};
	my $sql_delete = "FROM reference WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'reference',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_unit_collector {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	my %f = (
		unit_id => {
							NAME => "unit ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_string => {
							NAME => "Definicion original de evento de colecta",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_1",
							ORDER => 2,
						},
		unit_identifier => {
							NAME => "Numero o código de registro",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		unit_universal_identifier => {
							NAME => "Numero o código universal de registro",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 4,
							SEARCH => "s_2",
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		database_id  => { # IMPORTANT - we should not allow user to change dataset as he want, may be user login should be linked directly with some datast or several datasets
							NAME => "ID de base de datos",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 5,
							DEFAULT => "2",
							TEST => \&check_number,
							OBLIGATORY => 1,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "data_base",
							REFERENCE_ID_NAME => "database_id",
							REFERENCE_FIELD_NAME => "database_abbreviation",
						},
		record_base => {
							NAME => "Base de registro",
							TYPE => "enum",
							TYPE_ENUM => "'','espécimen preservado','espécimen vivo','espécimen fósil','fotografía','diapositiva','dibujo','fotocopia de espécimen','observación humana','observación automatizada','objeto multimedia','publicacion','otro espécimen'",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 6,
							SEARCH => "s_3",
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('unit_id','unit_string','unit_universal_identifier','record_base',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT unit_id, unit_string, database_id, record_base, unit_identifier, unit_universal_identifier
					FROM view_unit_collector WHERE $clause 1};
	my $sql_delete = "FROM unit WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'unit',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_unit_collector_full {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	my %f = (
		unit_id => {
							NAME => "unit ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_identifier => {
							NAME => "Numero o código de registro",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		unit_universal_identifier => {
							NAME => "Numero o código universal de registro",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		database_id  => {
							NAME => "ID de base de datos",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 4,
							DEFAULT => "2",
							TEST => \&check_number,
							OBLIGATORY => 1,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "data_base",
							REFERENCE_ID_NAME => "database_id",
							REFERENCE_FIELD_NAME => "database_abbreviation",
						},
		record_base => {
							NAME => "Base de registro",
							TYPE => "enum",
							TYPE_ENUM => "'','espécimen preservado','espécimen vivo','espécimen fósil','fotografía','diapositiva','dibujo','fotocopia de espécimen','observación humana','observación automatizada','objeto multimedia','publicacion','otro espécimen'",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 5,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		unit_string => {
							NAME => "Definicion original de evento de colecta",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_1",
							ORDER => 6,
							SKIP => 1,
						},
		collector_id => {
							NAME => "ID de colector (referencia a tabla COL_DET_AGENT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 7,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "col_det_agent",
							REFERENCE_ID_NAME => "agent_id",
							REFERENCE_FIELD_NAME => "agent",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		collector_field_number => {
							NAME => "Numero de colecta asignado por colector",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 25,
							ORDER => 8,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		collecting_date  => {
							NAME => "Fecha de colecta (AAAA-MM-DD)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_3",
							ORDER => 9,
							TEST => \&check_date,
							FORMAT => \&escape_date,
						},
		collecting_method_id  => {
							NAME => "ID de método de colecta (referencia a tabla METHOD)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_method_collecting",
							REFERENCE_ID_NAME => "method_id",
							REFERENCE_FIELD_NAME => "method",
							REFERENCE_SEARCH_EXT => 1,
						},
		project => {
							NAME => "Nombre del proyecto de colecta original",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							ORDER => 11,
							SKIP => 1,
						},
		project_id  => {
							NAME => "ID de proyecto de colecta (referencia a tabla PROJECT)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 12,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "project",
							REFERENCE_ID_NAME => "project_id",
							REFERENCE_FIELD_NAME => "project",
							REFERENCE_SEARCH_EXT => 1,
						},
		municipality_with_state => {
							NAME => "Unidad administrativa (municipio) original",
							TYPE => "label_only",
							SEARCH => "s_2",
							EDIT => 0,
							LENGTH => 256,
							ORDER => 13,
							SKIP => 1,
						},
		municipality_id  => {
							NAME => "ID de municipio (referencia a tabla MUNICIPALITY)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 14,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_municipality",
							REFERENCE_ID_NAME => "municipality_id",
							REFERENCE_FIELD_NAME => "municipality_with_state",
							REFERENCE_SEARCH => 2,
							REFERENCE_SEARCH_EXT => 1,
						},
		locality => {
							NAME => "Localidad",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 15,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		altitude => {
							NAME => "Altitud (msnm.)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 16,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
						},
		longitude => {
							NAME => "Longitud (Grados con fracción)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 17,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},
		latitude => {
							NAME => "Latitud (Grados con fracción)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 18,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},
		georeferencing_xml => {
							NAME => "XML relacionado con georeferenciación",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 19,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		gathering_xml => {
							NAME => "XML relacionado con evento de colecta",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 20,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		vegetation_type => {
							NAME => "Tipo de vegetación original",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							ORDER => 21,
							SKIP => 1,
						},
		vegetation_type_id  => {
							NAME => "ID de tipod vegetación (referencia a tabla VEGETATION)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 22,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "vegetation",
							REFERENCE_ID_NAME => "vegetation_id",
							REFERENCE_FIELD_NAME => "vegetation",
							REFERENCE_SEARCH_EXT => 1,
						},
		other_species => {
							NAME => "Otros especies observados",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 23,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		microhabitat => {
							NAME => "Microhábitat",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 24,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		unit_xml => {
							NAME => "XML relacionado con registro",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 25,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},	
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 26,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('unit_id','unit_string','municipality_with_state','collecting_date',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT unit_id, unit_string, unit_identifier, unit_universal_identifier,
					database_id, record_base, collector_id, collector_field_number,
					collecting_date, collecting_method_id, project, project_id, municipality_id, municipality_with_state,
					locality, altitude, longitude, latitude, georeferencing_xml,
					gathering_xml, vegetation_type, vegetation_type_id, other_species, microhabitat,
					unit_xml, comment
					FROM view_unit_collector_full WHERE $clause 1};
	my $sql_delete = "FROM unit WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'unit',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub v_specimen_images {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	# definition of column (fields) parameters
	my %f = (
		specimen_image_id => {
							NAME => "ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		specimen_id => {
							NAME => "ID del especimen (referencia a tabla SPECIMEN)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							SEARCH => "s_1",
							ORDER => 2,
							OBLIGATORY => 1,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_specimen",
							REFERENCE_ID_NAME => "specimen_id",
							REFERENCE_FIELD_NAME => "specimen_string",
							REFERENCE_SEARCH => 3,
						},
		specimen_status => {
							NAME => "Estatus de espécimen",
							TYPE => "enum",
							TYPE_ENUM => "'','incorporado a colección','preparado para envío a colección','enviado a colección','en proceso de incorporación a colección','en proceso de intercambio con otra colección','extraviado','destruido'",	
							EDIT => 1,
							LENGTH => 40,
							ORDER => 3,
							DEFAULT => "incorporado a colección",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		unit_id => {
							NAME => "ID unit",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 30,
							ORDER => 4,
							REFERENCE_TABLE => "unit",
							SKIP => 1,
						},
		herbarium_number => {
							NAME => "Numero o código del espécimen en herbario",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 30,
							ORDER => 6,
							SKIP => 1,
						},
		herbarium_abbreviation  => {
							NAME => "Codigo de herbario",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 30,
							ORDER => 5,
							SKIP => 1,
						},
		imagen  => {
							NAME => "Cadena de especificación de imagen",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 30,
							SEARCH =>"s_2",
							ORDER => 7,
							TEST => \&check_image_basename,
							FORMAT => \&escape_input_common,
							OBLIGATORY => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 8,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('specimen_image_id','specimen_id','imagen',undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT specimen_image_id, specimen_id, specimen_status, imagen, unit_id, comment, herbarium_abbreviation, herbarium_number 
					FROM view_specimen_image WHERE $clause 1};
	my $sql_delete = "FROM specimen_image WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'specimen_image',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}


sub w_step_1 {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	my %f = (
		unit_id => {
							NAME => "unit ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							ID => 1,
						},
		unit_identifier => {
							NAME => "Numero o código de registro",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		unit_universal_identifier => {
							NAME => "Numero o código universal de registro",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		database_id  => { # IMPORTANT - we should not allow user to change dataset as he want, may be user login should be linked directly with some datast or several datasets
							NAME => "Segmento de base de datos",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 4,
							DEFAULT => "2",
							TEST => \&check_number,
							OBLIGATORY => 1,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "data_base",
							REFERENCE_ID_NAME => "database_id",
							REFERENCE_FIELD_NAME => "database_abbreviation",
						},
		record_base => {
							NAME => "Base de registro",
							TYPE => "enum",
							TYPE_ENUM => "'','espécimen preservado','espécimen vivo','espécimen fósil','fotografía','diapositiva','dibujo','fotocopia de espécimen','observación humana','observación automatizada','objeto multimedia','publicacion','otro espécimen'",
							EDIT => 1,
							LENGTH => 50,
							ORDER => 5,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		unit_string => {
							NAME => "Definicion original de evento de colecta (colector, número de colecta, fecha de colecta)",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							SEARCH => "s_1",
							ORDER => 6,
							SKIP => 1,
						},
		collector_id => {
							NAME => "ID de colector (referencia a tabla COL_DET_AGENT)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 7,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "col_det_agent",
							REFERENCE_ID_NAME => "agent_id",
							REFERENCE_FIELD_NAME => "agent",
							REFERENCE_SEARCH => 3,
							REFERENCE_SEARCH_EXT => 1,
						},
		collector_field_number => {
							NAME => "Numero de colecta asignado por colector",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 25,
							ORDER => 8,
							SEARCH => "s_3",
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		collecting_date  => {
							NAME => "Fecha de colecta (AAAA-MM-DD)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							SEARCH =>"s_2",
							ORDER => 9,
							TEST => \&check_date,
							FORMAT => \&escape_date,
						},
		collecting_method_id  => {
							NAME => "Método de colecta",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_method_collecting",
							REFERENCE_ID_NAME => "method_id",
							REFERENCE_FIELD_NAME => "method",
							REFERENCE_SEARCH_EXT => 1,
						},
		project => {
							NAME => "Proyecto de colecta",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							ORDER => 11,
							SKIP => 1,
						},
		project_id  => {
							NAME => "ID de proyecto de colecta",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 12,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "project",
							REFERENCE_ID_NAME => "project_id",
							REFERENCE_FIELD_NAME => "project",
							REFERENCE_SEARCH_EXT => 1,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 13,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('unit_id','unit_string','collecting_date','collector_field_number',$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT unit_id, unit_string, collector_field_number, collecting_date, collecting_method_id, 
					project, project_id, collector_id, database_id, record_base, unit_identifier, unit_universal_identifier, comment
					FROM view_unit_collector_full WHERE $clause 1};
	my $sql_delete = "FROM unit WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'unit',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub w_step_2 {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	my %f = (
		unit_id => {
							NAME => "unit ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							ID => 1,
						},
		unit_identifier => {
							NAME => "Numero o código de registro",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 50,
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		unit_universal_identifier => {
							NAME => "Numero o código universal de registro",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 50,
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		database_id  => { # IMPORTANT - we should not allow user to change dataset as he want, may be user login should be linked directly with some datast or several datasets
							NAME => "Segmento de base de datos",
							TYPE => "label_only",
							EDIT => 0,
							ORDER => 4,
							REFERENCE_TABLE => "data_base",
							REFERENCE_ID_NAME => "database_id",
							REFERENCE_FIELD_NAME => "database_abbreviation",
						},
		record_base => {
							NAME => "Base de registro",
							TYPE => "enum",
							TYPE_ENUM => "'','espécimen preservado','espécimen vivo','espécimen fósil','fotografía','diapositiva','dibujo','fotocopia de espécimen','observación humana','observación automatizada','objeto multimedia','publicacion','otro espécimen'",
							EDIT => 0,
							LENGTH => 50,
							ORDER => 5,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		collecting_method_id  => {
							NAME => "Método de colecta",
							TYPE => "selector",
							EDIT => 0,
							LENGTH => 10,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_method_collecting",
							REFERENCE_ID_NAME => "method_id",
							REFERENCE_FIELD_NAME => "method",
							REFERENCE_SEARCH_EXT => 1,
						},
		project => {
							NAME => "Proyecto de colecta",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							ORDER => 11,
							SKIP => 1,
						},
		municipality_id  => {
							NAME => "ID de municipio (referencia a tabla MUNICIPALITY)",
							TYPE => "selector_external",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 14,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "view_municipality",
							REFERENCE_ID_NAME => "municipality_id",
							REFERENCE_FIELD_NAME => "municipality_with_state",
							REFERENCE_SEARCH => 2,
							REFERENCE_SEARCH_EXT => 1,
						},
		locality => {
							NAME => "Localidad",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 15,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		altitude => {
							NAME => "Altitud (msnm.)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 16,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
						},
		longitude => {
							NAME => "Longitud (Grados con fracción)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 17,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},
		latitude => {
							NAME => "Latitud (Grados con fracción)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 18,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},
		georeferencing_xml => {
							NAME => "XML relacionado con georeferenciación",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 19,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		gathering_xml => {
							NAME => "XML relacionado con evento de colecta",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 20,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		vegetation_type => {
							NAME => "Tipo de vegetación original",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							ORDER => 21,
							SKIP => 1,
						},
		vegetation_type_id  => {
							NAME => "ID de tipod vegetación (referencia a tabla VEGETATION)",
							TYPE => "selector",
							EDIT => 1,
							LENGTH => 10,
							ORDER => 22,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
							REFERENCE_TABLE => "vegetation",
							REFERENCE_ID_NAME => "vegetation_id",
							REFERENCE_FIELD_NAME => "vegetation",
							REFERENCE_SEARCH_EXT => 1,
						},
		other_species => {
							NAME => "Otros especies observados",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 23,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		microhabitat => {
							NAME => "Microhábitat",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 24,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 26,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('unit_id','unit_string',undef,undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT unit_id, collecting_method_id, 
					project, database_id, record_base, unit_identifier, unit_universal_identifier,
					municipality_id, locality, altitude, longitude, latitude, georeferencing_xml, gathering_xml, 
					vegetation_type, vegetation_type_id, other_species, microhabitat, comment
					FROM view_unit_collector_full WHERE $clause 1};
	my $sql_delete = "FROM unit WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'unit',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}

sub w_step_3 {
	my ($action,$table,$user_id,$template,$dbh) = @_;	
	my %f = (
		unit_id => {
							NAME => "unit ID",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							SEARCH => "s_id",
							ORDER => 1,
							REFERENCE_TABLE => "view_unit_collector",
							REFERENCE_ID_NAME => "unit_id",
							REFERENCE_FIELD_NAME => "unit_string",
							ID => 1,
						},
		unit_identifier => {
							NAME => "Numero o código de registro",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 50,
							ORDER => 2,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		unit_universal_identifier => {
							NAME => "Numero o código universal de registro",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 50,
							ORDER => 3,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		database_id  => { # IMPORTANT - we should not allow user to change dataset as he want, may be user login should be linked directly with some datast or several datasets
							NAME => "Segmento de base de datos",
							TYPE => "label_only",
							EDIT => 0,
							ORDER => 4,
							REFERENCE_TABLE => "data_base",
							REFERENCE_ID_NAME => "database_id",
							REFERENCE_FIELD_NAME => "database_abbreviation",
						},
		record_base => {
							NAME => "Base de registro",
							TYPE => "enum",
							TYPE_ENUM => "'','espécimen preservado','espécimen vivo','espécimen fósil','fotografía','diapositiva','dibujo','fotocopia de espécimen','observación humana','observación automatizada','objeto multimedia','publicacion','otro espécimen'",
							EDIT => 0,
							LENGTH => 50,
							ORDER => 5,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		collecting_method_id  => {
							NAME => "Método de colecta",
							TYPE => "selector",
							EDIT => 0,
							ORDER => 6,
							REFERENCE_TABLE => "view_method_collecting",
							REFERENCE_ID_NAME => "method_id",
							REFERENCE_FIELD_NAME => "method",
							REFERENCE_SEARCH_EXT => 1,
						},
		project_id => {
							NAME => "ID de proyecto de colecta (referencia a tabla PROJECT)",
							TYPE => "label_only",
							EDIT => 0,
							LENGTH => 256,
							ORDER => 7,
							REFERENCE_TABLE => "project",
							REFERENCE_ID_NAME => "project_id",
							REFERENCE_FIELD_NAME => "project",
						},
		municipality_id  => {
							NAME => "ID de municipio (referencia a tabla MUNICIPALITY)",
							TYPE => "label_only",
							EDIT => 0,
							ORDER => 8,
							REFERENCE_TABLE => "view_municipality",
							REFERENCE_ID_NAME => "municipality_id",
							REFERENCE_FIELD_NAME => "municipality_with_state",
							REFERENCE_SEARCH => 2,
							REFERENCE_SEARCH_EXT => 1,
						},
		locality => {
							NAME => "Localidad",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 1024,
							ORDER => 9,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		altitude => {
							NAME => "Altitud (msnm.)",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							ORDER => 10,
							TEST => \&check_number,
							FORMAT => \&escape_numeric_input,
						},
		longitude => {
							NAME => "Longitud (Grados con fracción)",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							ORDER => 11,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},
		latitude => {
							NAME => "Latitud (Grados con fracción)",
							TYPE => "field",
							EDIT => 0,
							LENGTH => 10,
							ORDER => 12,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},
		vegetation_type_id  => {
							NAME => "ID de tipod vegetación (referencia a tabla VEGETATION)",
							TYPE => "selector",
							EDIT => 0,
							ORDER => 13,
							REFERENCE_TABLE => "vegetation",
							REFERENCE_ID_NAME => "vegetation_id",
							REFERENCE_FIELD_NAME => "vegetation",
							REFERENCE_SEARCH_EXT => 1,
						},
		other_species => {
							NAME => "Otros especies observados",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 1024,
							ORDER => 14,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		microhabitat => {
							NAME => "Microhábitat",
							TYPE => "text",
							EDIT => 0,
							LENGTH => 1024,
							ORDER => 15,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_locality_xml => {
							NAME => "XML relacionado con observaciones en localidad de colecta",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 21,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
		observations_plant_lifeform => {
							NAME => "Observación durante la colecta: forma de crecimiento",
							TYPE => "enum",
							TYPE_ENUM => "'','acuática flotante','acuática sumergida','arborescente','arbustiva','bejuco','enredadera herbácea','enredadera leñosa','epífita','herbácea','parásita','rastrera','rupícola','trepadora'",	
							EDIT => 1,
							LENGTH => 50,
							ORDER => 22,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_size => {
							NAME => "Observación durante la colecta: tamaño del organismo (m)",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 20,
							ORDER => 23,
							TEST => \&check_decimal_number,
							FORMAT => \&escape_decimal_input,
						},	
		observations_plant_longevity => {
							NAME => "Observación durante la colecta: longevidad",
							TYPE => "enum",
							TYPE_ENUM => "'','anual','bianual','perenne'",	
							EDIT => 1,
							LENGTH => 20,
							ORDER => 24,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},	
		observations_plant_common_name => {
							NAME => "Nombre comun",
							TYPE => "field",
							EDIT => 1,
							LENGTH => 75,
							ORDER => 25,
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_use => {
							NAME => "Uso",
							TYPE => "set",
							TYPE_ENUM => "'medicinal','alimento','madera/muebles','ornamental','combustible','forrajero','ceremonial','artesanía','cerca viva','colorante','veneno','otro uso'",	
							EDIT => 1,
							LENGTH => 20,
							ORDER => 26,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},	
		observations_plant_abundance => {
							NAME => "Observación durante la colecta: abundancia",
							TYPE => "enum",
							TYPE_ENUM => "'','abundante','abundante y frecuente','común','escasa','frecuente','muy abundante','muy común','muy escasa','muy frecuente','muy rara','poco abundante','poco común','poco frecuente','rara','regular','ocasional'",	
							EDIT => 1,
							LENGTH => 20,
							ORDER => 27,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_fenology => {
							NAME => "Observación durante la colecta: fenología",
							TYPE => "set",
							TYPE_ENUM => "'vegetativa','en flor','en fruto','con conos femeninos','con conos masculinos','con soros','con estróbilos','en botón floral'",	
							EDIT => 1,
							LENGTH => 30,
							ORDER => 28,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_nutrition => {
							NAME => "Observación durante la colecta: nutrición del organismo",
							TYPE => "enum",
							TYPE_ENUM => "'','autótrofa','hemi-/parásita','parásita','saprófita'",	
							EDIT => 1,
							LENGTH => 30,
							ORDER => 29,
							DEFAULT => "",
							TEST => \&check_text,
							FORMAT => \&escape_input_common,
						},
		observations_plant_xml => {
							NAME => "XML relacionado con observaciones en del organismo colectado",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 30,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},	
		unit_xml => {
							NAME => "XML relacionado con registro",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 1024,
							ORDER => 31,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},	
		comment  => {
							NAME => "Comentario",
							TYPE => "text",
							EDIT => 1,
							LENGTH => 256,
							ORDER => 32,
							TEST => \&check_gag,
							FORMAT => \&escape_input_common,
						},
	);
	my $clause = form_clause('unit_id','unit_string',undef,undef,$dbh);
	my $s_id = &trim(param("s_id"));
	my $id_clause = &form_id_clause(\%f,$s_id,$dbh);

	my $sql_search = qq{SELECT unit_id, collecting_method_id, 
					project_id, database_id, record_base, unit_identifier, unit_universal_identifier,
					municipality_id, locality, altitude, longitude, latitude, vegetation_type_id,
					other_species, microhabitat,
					observations_locality_xml, observations_plant_lifeform,
					observations_plant_size, observations_plant_longevity, 
					observations_plant_common_name, observations_plant_use, 
					observations_plant_abundance, observations_plant_fenology, 
					observations_plant_nutrition, observations_plant_xml, 
					unit_xml, comment
					FROM unit WHERE $clause 1};
	my $sql_delete = "FROM unit WHERE $id_clause";

	my ($sql_insert,$sql_update,$input_error_flag) = &form_insert_update_strings(\%f,'unit',$user_id,$dbh);

	&action_control(\%f,$sql_search,$sql_update,$sql_delete,$sql_insert ,$action,$input_error_flag,$table,$template,$dbh);
}


1;