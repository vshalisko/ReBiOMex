use utf8;
use CGI qw (:standard escapeHTML escape);
use locale;
use Encode;

require 'tools.pl';
require 'messages.pl';
require 'db_requests.pl';
#require 'db_requests_extended.pl';

# == table intependent part =======================================

sub action_control {
	my ($f,$sql_search,$sql_update,$sql_delete,$sql_insert,$action,$data_problem,$table,$template,$dbh) = @_;
	if ($action eq "search") {
		# table for search results with action controls or nothing found report
		$template->param(TABLE_OUTPUT => 1);
		$template->param(ACTION_SEARCH => 1);
		&reestablish_variables($template);
		# form search fields
		my @search_fields = ();
		my $search_string = ();
		foreach my $field (sort { $$f{$a}{'ORDER'} <=> $$f{$b}{'ORDER'} } keys %$f) {
			if ($$f{$field}{'SEARCH'} && param($$f{$field}{'SEARCH'})) {
				push (@search_fields, {FIELD_FULL_NAME => $$f{$field}{'NAME'}, FIELD_NAME => $field, FIELD_VALUE => &un(&trim(param($$f{$field}{'SEARCH'}))), });
				$search_string .= &URLescape($$f{$field}{'SEARCH'}) ."=". &URLescape(&un(&trim(param($$f{$field}{'SEARCH'})))) ."&";
			}
		}
		$template->param(SEARCH_REQUEST => \@search_fields, SEARCH_STRING => $search_string,); # this string is to form URL requests saving search parametes
 
		&universal_table_output($f,$table,$sql_search,$template,$dbh);
	}
	elsif ($action eq "eliminate") {
		# line elimination interface - proceed with elimination and output success report or problem report
		if (param("s_id")) {
			&reestablish_variables($template);
			if (param("confirmed")) {
				# atempt to eliminate record
				my ($del_count,$ext_key) = &record_delete($sql_delete,$template,$dbh);
				if ($del_count) {
					$template->param(ACTION_DELETESUCCESS => 1);
				} else {
					$template->param(TABLE_OUTPUT => 1);
					$template->param(ACTION_DELETEPROBLEM => 1);
					&universal_table_output($f,$table,$sql_search,$template,$dbh);
					if ($ext_key) {$template->param(DELETE_REFERENCE_PROBLEM => 1);};
				}
			} else {
				# request to confirm record deleting
				$template->param(TABLE_OUTPUT => 1);
				$template->param(ACTION_DELETECONFIRM => 1);
				&universal_table_output($f,$table,$sql_search,$template,$dbh);
			}
		} else {
			# record was not specified - nothing to do
		}
	}
	elsif ($action eq "modify_form") {
		# line modification interface - proceed with line modification form
		$template->param(FORM_OUTPUT => 1);
		$template->param(ACTION_MODIFYFORM => 1);
		&reestablish_variables($template);
		&universal_form_output($f,3,$sql_search,$template,$dbh);
	}
	elsif ($action eq "add_new_form") {
		# line add interface - proceed with line addition (empty) form
		$template->param(FORM_OUTPUT => 1);
		$template->param(ACTION_ADDFORM => 1);
		&reestablish_variables($template);
		&universal_form_output($f,1,$sql_search,$template,$dbh);
	}
	elsif ($action eq "modify") {
		# line modification interface - proceed with modification success report or problem in line modification form
		&reestablish_variables($template);
		my ($mod_count,$ext_key) = ();
		if (!$data_problem) {
			($mod_count,$ext_key) = &record_update(1,$sql_update,$sql_delete,$template,$dbh);
		}
		if ($mod_count && !$data_problem) {
			$template->param(ACTION_MODIFYSUCCESS => 1);
			$template->param(TABLE_OUTPUT => 1);
			&universal_table_output($f,$table,$sql_search,$template,$dbh);
		} else {
			$template->param(ACTION_MODIFYPROBLEM => 1);
			$template->param(FORM_OUTPUT => 1);
			&universal_form_output($f,0,$sql_search,$template,$dbh);
			if ($ext_key) {$template->param(MODIFY_REFERENCE_PROBLEM => 1);};
		}
	}
	elsif ($action eq "add_new") {
		# line add interface - proceed with line addition success report or problem in line addition form
		my ($ins_count,$last_insert_id,$ext_key) = 0;
		&reestablish_variables($template);
		if (!$data_problem) {
			($ins_count,$last_insert_id,$ext_key) = &record_insert($sql_insert,$template,$dbh);
		}
		if ($last_insert_id) {
			my $clause_last_id = &form_id_clause($f,$last_insert_id,$dbh);
			$sql_search .= " AND $clause_last_id";
		}
		if (($ins_count > 0) && !$data_problem) {
			$template->param(ACTION_ADDSUCCESS => 1);
			$template->param(TABLE_OUTPUT => 1);
			&universal_table_output($f,$table,$sql_search,$template,$dbh);
		} else {
			# problem how to maintain values in fields
			$template->param(ACTION_ADDPROBLEM => 1);
			$template->param(FORM_OUTPUT => 1);
			&universal_form_output($f,2,$sql_search,$template,$dbh);
			if ($ext_key) {$template->param(ADD_REFERENCE_PROBLEM => 1);};
		}		
	}
	else {
		# if no action is defined than we need to output initial interface for table
		# form search fields according to field descriptions
		my @search_fields = ();
		foreach my $field (sort { $$f{$a}{'ORDER'} <=> $$f{$b}{'ORDER'} } keys %$f) {
			if (!defined $$f{$field}{'TYPE'}) {$$f{$field}{'TYPE'} = '';}; 
			if (!defined $$f{$field}{'REFERENCE_TABLE'}) {$$f{$field}{'REFERENCE_TABLE'} = '';}; 
			if (!defined $$f{$field}{'REFERENCE_ID_NAME'}) {$$f{$field}{'REFERENCE_ID_NAME'} = '';};
			if (!defined $$f{$field}{'REFERENCE_SEARCH'}) {$$f{$field}{'REFERENCE_SEARCH'} = '';};
			if (!defined $$f{$field}{'REFERENCE_SEARCH_EXT'}) {$$f{$field}{'REFERENCE_SEARCH_EXT'} = '';};
			if (!defined $$f{$field}{'REFERENCE_FIELD_NAME'}) {$$f{$field}{'REFERENCE_FIELD_NAME'} = '';};
			my $field_type = $$f{$field}{'TYPE'} || 'field';
			my $reference_link = $$f{$field}{'REFERENCE_TABLE'} || 0;

			if ($$f{$field}{'SEARCH'}) {
				# following should be extended to include ENUM and SELECTOR controls
				if ($field_type eq "selector_external") {
					push (@search_fields, {
										TYPE_SELECTOR_EXTERNAL => 1,
										FIELD_FULL_NAME => $$f{$field}{'NAME'}, 
										FIELD_NAME => $$f{$field}{'SEARCH'}, 
										REFERENCE_LINK => $reference_link,
										REFERENCE_SEARCH => $$f{$field}{'REFERENCE_SEARCH'},
										REFERENCE_ID_NAME => $$f{$field}{'REFERENCE_ID_NAME'},
										EXTENDED_SEARCH => $$f{$field}{'REFERENCE_SEARCH_EXT'},
										REFERENCE_FIELD_NAME => $$f{$field}{'REFERENCE_FIELD_NAME'},
										SCRIPT_NAME => $script_name,
									})
				} else {
					push (@search_fields, {
										FIELD_FULL_NAME => $$f{$field}{'NAME'}, 
										FIELD_NAME => $$f{$field}{'SEARCH'}, 
										REFERENCE_LINK => $reference_link,
										REFERENCE_SEARCH => $$f{$field}{'REFERENCE_SEARCH'},
										REFERENCE_ID_NAME => $$f{$field}{'REFERENCE_ID_NAME'},
										EXTENDED_SEARCH => $$f{$field}{'REFERENCE_SEARCH_EXT'},
										REFERENCE_FIELD_NAME => $$f{$field}{'REFERENCE_FIELD_NAME'},
										SCRIPT_NAME => $script_name,
									})
				}
			}
		}
		$template->param(SEARCH_FIELDS => \@search_fields);
		$template->param(MENU_OUTPUT => 1);
	}
}

# ===== subprogramas de formateo de las tablas y formas ================================

sub universal_table_output {
		# universal table output
		my ($f,$table_name,$sql_search,$template,$dbh) = @_;
		
		# prev/next related code
		my $position = 0;
		if (param('position')) 
		{
			$position = &escape_numeric_input(&un(param('position'))) || 0; 	# getting current position in table	
		}
		$sql_search .= " LIMIT $position, 51"; 					# add current position in to search clause
		
		my @a = &main_list($sql_search,$template,$dbh);
		
		# prev/next related code
		my $current_count = scalar @a;
		if ($current_count == 1) { $template->param(CURRENT_UNIQUE => 1, ); };
		if ($position <= 0) { $template->param(NO_PREVIOUS_FLAG => 1, ); };
		if (defined $a[50]) { 									# search retured line 50- we can have next
			$#a = 49;										# leaving only first 49 lines, from 0 to 48
			$current_count--;
			my $next = $position + 50;
			$template->param(NEXT => $next );
		}
		my $previuous = $position - 50;
		if ($previuous <= 0) {
			$template->param(PREVIOUS => 0, );
		} else {
			$template->param(PREVIOUS => $previuous, );
		};
		$template->param(CURRENT_LOW => $position + 1, CURRENT_HIGH => $position + $current_count, );
		
		if (scalar @a > 0) {
			if (scalar @a == 1) # table of one line - special case
			{
				$template->param(TABLE_SINGLE_LINE => 1);
			}
			# table header
			my $first_line = $a[0];
			my @table_header = ();
			my @field_names = sort { $$f{$a}{'ORDER'} <=> $$f{$b}{'ORDER'} } keys %$$first_line; # it is very important that it is a hash, but not reference
			if (scalar @field_names > 7) {$template->param(WIDE_TABLE => 1);}; # wide table representation
			foreach my $field_name (@field_names) {
				if (!(scalar @a == 1 && $$f{$field_name}{'SKIP'})) {
					if ($$f{$field_name}{'NAME'}) {
						push(@table_header, {COLUMN_NAME => escapeHTML(&un($$f{$field_name}{'NAME'}))});
					} else {
						push(@table_header, {COLUMN_NAME => escapeHTML(&un($field_name))});
					}
				}
			}
			$template->param(TABLE_HEADER => \@table_header);
			
			# table content
			my @table = ();
			foreach my $line (@a) {
				my @table_raw = ();
				my $id = 0;
				foreach my $field_name (@field_names) { 
					# my $column_name = $$f{$field_name}{'NAME'} || $field_name;
					my $reference_link = 0;
					my $reference_string = '';
					if (!(scalar @a == 1 && $$f{$field_name}{'SKIP'})) {
						if ($$f{$field_name}{'ID'} && $$line->{$field_name}) {
							$id = $$line->{$field_name};
						}
						if ($$f{$field_name}{'REFERENCE_TABLE'} && $$line->{$field_name}) {
							$reference_link = $$f{$field_name}{'REFERENCE_TABLE'};
							if ($$f{$field_name}{'REFERENCE_ID_NAME'} && $$f{$field_name}{'REFERENCE_FIELD_NAME'} && (scalar @a == 1)) {
								# request in reference table in base of field value
								my $reference_hash = &get_selector($reference_link,$$f{$field_name}{'REFERENCE_ID_NAME'},$$f{$field_name}{'REFERENCE_FIELD_NAME'},$template,$dbh);
								if ($$reference_hash{$$line->{$field_name}}) {
									$reference_string = $$reference_hash{$$line->{$field_name}};
								}
							}
						}
						if ($$line->{$field_name}) {
							push(@table_raw, {
									FIELD => escapeHTML(&un($$line->{$field_name})), 
									REFERENCE_LINK => $reference_link, 
									REFERENCE_STRING => escapeHTML(&un($reference_string)),
									SCRIPT_NAME => $script_name,
								});
						} else {
							push(@table_raw, {
									FIELD => '&nbsp;', 
								});
						}
					}
				}
				push(@table, {TABLE_RAW => \@table_raw, S_ID => $id, TABLE_NAME => $table_name, SCRIPT_NAME => $script_name,});
				$template->param(LAST_S_ID => $id);
			}
			$template->param(TABLE => \@table);
			return scalar @a;
		} else {
			$template->param(TABLE_NO_MATCH => 1);
			return 0;
		}
}

sub universal_form_output {
		# universal form output - only first match of search
		my ($f,$empty,$sql_search,$template,$dbh) = @_;
		my $sql_limited_search = $sql_search . ' LIMIT 1';
		my @a = &main_list($sql_limited_search,$template,$dbh);
		if (scalar @a > 0) {
			# table header
			my $first_line = $a[0];
			my @table_header = ();
			my @field_names = sort { $$f{$a}{'ORDER'} <=> $$f{$b}{'ORDER'} } keys %$$first_line; # it is very important that it is a hash, but not reference
			
			# form content
			my @form = ();
			my $line = shift @a;
			foreach my $field_name (@field_names) {
				if ($$f{$field_name}{'SKIP'}) {
					next;
				}
				if (!defined $$f{$field_name}{'VALUE'}) {$$f{$field_name}{'VALUE'} = '';}; 
				if (!defined $$f{$field_name}{'DEFAULT'}) {$$f{$field_name}{'DEFAULT'} = '';}; 
				if (!defined $$f{$field_name}{'NAME'}) {$$f{$field_name}{'NAME'} = '';}; 
				if (!defined $$f{$field_name}{'EDIT'}) {$$f{$field_name}{'EDIT'} = '';}; 
				if (!defined $$f{$field_name}{'OBLIGATORY'}) {$$f{$field_name}{'OBLIGATORY'} = '';}; 
				if (!defined $$f{$field_name}{'REFERENCE_TABLE'}) {$$f{$field_name}{'REFERENCE_TABLE'} = '';}; 
				if (!defined $$f{$field_name}{'LENGTH'}) {$$f{$field_name}{'LENGTH'} = '';}; 
				if (!defined $$f{$field_name}{'TYPE'}) {$$f{$field_name}{'TYPE'} = '';}; 
				if (!defined $$f{$field_name}{'PROBLEM'}) {$$f{$field_name}{'PROBLEM'} = '';}; 
				if (!defined $$f{$field_name}{'REFERENCE_FIELD_NAME'}) {$$f{$field_name}{'REFERENCE_FIELD_NAME'} = '';};
				if (!defined $$f{$field_name}{'REFERENCE_ID_NAME'}) {$$f{$field_name}{'REFERENCE_ID_NAME'} = '';};
				if (!defined $$f{$field_name}{'REFERENCE_SEARCH'}) {$$f{$field_name}{'REFERENCE_SEARCH'} = '';};
				if (!defined $$f{$field_name}{'REFERENCE_SEARCH_EXT'}) {$$f{$field_name}{'REFERENCE_SEARCH_EXT'} = '';};
				if (!defined $$line->{$field_name}) {$$line->{$field_name} = '';}; 
				
				my $column_name = $$f{$field_name}{'NAME'} || $field_name;
				my $editable = $$f{$field_name}{'EDIT'} || 0;
				my $obligate = $$f{$field_name}{'OBLIGATORY'} || 0;
				my $field_length = $$f{$field_name}{'LENGTH'} || 50;
				my $field_type = $$f{$field_name}{'TYPE'} || 'field';
				my $field_value = escapeHTML($$f{$field_name}{'VALUE'}) || escapeHTML(&un($$line->{$field_name})) || '';
				my $reference_link = $$f{$field_name}{'REFERENCE_TABLE'} || 0;
				my ($reference_field_name) = escapeHTML($$f{$field_name}{'REFERENCE_FIELD_NAME'}) || ($field_name =~ m/(.*)_id$/);
				my $reference_id_name = escapeHTML($$f{$field_name}{'REFERENCE_ID_NAME'}) || $field_name;
				my $reference_search = $$f{$field_name}{'REFERENCE_SEARCH'} || 0;
				my $reference_search_extended = $$f{$field_name}{'REFERENCE_SEARCH_EXT'} || 0;
				my $reference_string = '';
				
				if ($reference_link && $reference_id_name && $reference_field_name) {
					# request in reference table in base of field value
					my $reference_hash = &get_selector($reference_link,$reference_id_name,$reference_field_name,$template,$dbh);
					if ($$reference_hash{$field_value}) {
						$reference_string = &un($$reference_hash{$field_value});
					}
				}
				
				my $problem = $$f{$field_name}{'PROBLEM'} || 0;  # error message can be passed through parameter hash
				if ($empty == 1) { 
					$field_value = escapeHTML($$f{$field_name}{'VALUE'}) || escapeHTML($$f{$field_name}{'DEFAULT'}) || undef; 
					$problem = 0;
				};
				if ($empty == 2) { 
					$field_value = escapeHTML($$f{$field_name}{'VALUE'}) || escapeHTML($$f{$field_name}{'DEFAULT'}) || undef; 
				};
				if ($empty == 3) { 
					$problem = 0;
				};
				# set flag for input type, specially important for types such as list
				if ($field_type eq "label_only") {
					# simple text type 
					push(@form, {
							TYPE_LABEL_ONLY => 1,
							FIELD_VALUE => $field_value, 
							EDITABLE => $editable, 
							LENGTH => $field_length, 
							FIELD_FULL_NAME => $column_name,
							FIELD_NAME => $field_name,
							PROBLEM => $problem,
							OBLIGATORY => $obligate,
							REFERENCE_LINK => $reference_link, # external table reference
							SCRIPT_NAME => $script_name,
							REFERENCE_STRING => $reference_string, # output of external table request result
						});
				} elsif ($field_type eq "text") {
					# simple text type 
					push(@form, {
							TYPE_TEXT => 1,
							FIELD_VALUE => $field_value, 
							EDITABLE => $editable, 
							LENGTH => $field_length, 
							FIELD_FULL_NAME => $column_name,
							FIELD_NAME => $field_name,
							PROBLEM => $problem,
							OBLIGATORY => $obligate,
							REFERENCE_LINK => $reference_link,
							SCRIPT_NAME => $script_name,
							REFERENCE_STRING => $reference_string,
						});
				} elsif ($field_type eq "field") {
					# textfield type 
					push(@form, {
							TYPE_FIELD => 1,
							FIELD_VALUE => $field_value, 
							EDITABLE => $editable, 
							LENGTH => $field_length, 
							FIELD_FULL_NAME => $column_name,
							FIELD_NAME => $field_name,
							PROBLEM => $problem,
							OBLIGATORY => $obligate,
							REFERENCE_LINK => $reference_link,
							SCRIPT_NAME => $script_name,
							REFERENCE_STRING => $reference_string,
						});
				} elsif (($field_type eq "enum") || ($field_type eq "set")) {
					# enum type with predefined list of values, values can not contain commas
					my @enum = ();
					my %selected = ();
					my $multiple = 0;
					if ($field_type eq "set") {	$multiple = 1; };
					my @parsed_field_values = &parse_csv($field_value); # parse database stored value to get it elements
					foreach my $parsed_field_value (@parsed_field_values) {
						$selected{$parsed_field_value} = 1;
					}
					if ($$f{$field_name}{'TYPE_ENUM'}) {
						my @enum_vlaues = &parse_csv($$f{$field_name}{'TYPE_ENUM'});
						foreach my $value (@enum_vlaues) {
							if ($selected{$value}) {
								push (@enum, {ENUM_VALUE => $value, SELECTED => 1});
							} else {
								push (@enum, {ENUM_VALUE => $value, SELECTED => 0});
							}
						}
					}	
					push(@form, {
							TYPE_ENUM => \@enum,
							FIELD_VALUE => $field_value, 
							EDITABLE => $editable, 
							LENGTH => $field_length, 
							FIELD_FULL_NAME => $column_name,
							FIELD_NAME => $field_name,
							PROBLEM => $problem,
							OBLIGATORY => $obligate,
							REFERENCE_LINK => $reference_link,
							SCRIPT_NAME => $script_name,
							MULTIPLE => $multiple,
							REFERENCE_STRING => $reference_string,
						});
				} elsif (($field_type eq "selector")) {
					# selecor type with list of values from extenal table
					my @enum = ();
					if ($$f{$field_name}{'REFERENCE_ID_NAME'} && $$f{$field_name}{'REFERENCE_FIELD_NAME'}) {
						my $enum_hash = &get_selector($reference_link,$$f{$field_name}{'REFERENCE_ID_NAME'},$$f{$field_name}{'REFERENCE_FIELD_NAME'},$template,$dbh); # instead it should be a hash as a result of sub($reference_link,$text_field)
						if (!$obligate) { # if field is not obligatory we shold give option of NULL selection
							if ($field_value) { # checking if there is some field value defined
								push (@enum, {ENUM_VALUE => '', SELECTED => 0, ENUM_TEXT => '',});
							} else {
								push (@enum, {ENUM_VALUE => '', SELECTED => 1, ENUM_TEXT => '',});
							}
						}
						foreach my $value (sort { ($$enum_hash{$a} cmp $$enum_hash{$b}) || ($a <=> $b)} keys %$enum_hash) { 
							if ($field_value && ($field_value eq $value)) {
								push (@enum, {ENUM_VALUE => escapeHTML($value), SELECTED => 1, ENUM_TEXT => escapeHTML(&un($$enum_hash{$value})).' (ID:'.escapeHTML($value) .')',});
							} else {
								push (@enum, {ENUM_VALUE => escapeHTML($value), SELECTED => 0, ENUM_TEXT => escapeHTML(&un($$enum_hash{$value})).' (ID:'.escapeHTML($value) .')',});
							}
						}
					}
					push(@form, {
							TYPE_ENUM => \@enum,
							FIELD_VALUE => $field_value, 
							EDITABLE => $editable, 
							LENGTH => $field_length, 
							FIELD_FULL_NAME => $column_name,
							FIELD_NAME => $field_name,
							PROBLEM => $problem,
							OBLIGATORY => $obligate,
							REFERENCE_LINK => $reference_link,
							SCRIPT_NAME => $script_name,
							MULTIPLE => 0,
							REFERENCE_STRING => $reference_string,
						});
				} elsif (($field_type eq "selector_external")) {
					# selecor type with list of values from extenal table
					push(@form, {
							TYPE_SELECTOR_EXTERNAL => 1,
							FIELD_VALUE => $field_value, 
							EDITABLE => $editable, 
							LENGTH => $field_length, 
							FIELD_FULL_NAME => $column_name,
							FIELD_NAME => $field_name,
							PROBLEM => $problem,
							OBLIGATORY => $obligate,
							REFERENCE_LINK => $reference_link,
							REFERENCE_FIELD_NAME => $reference_field_name,
							REFERENCE_ID_NAME => $reference_id_name,
							REFERENCE_SEARCH => $reference_search,
							EXTENDED_SEARCH => $reference_search_extended,
							SCRIPT_NAME => $script_name,
							REFERENCE_STRING => $reference_string,
						});
				} elsif ($field_type eq "checkbox") {
					# checkbox type for binary value (yes/no)
					push(@form, {
							TYPE_CHECKBOX => 1,
							FIELD_VALUE => $field_value, 
							EDITABLE => $editable, 
							LENGTH => $field_length, 
							FIELD_FULL_NAME => $column_name,
							FIELD_NAME => $field_name,
							PROBLEM => $problem,
							OBLIGATORY => $obligate,
							REFERENCE_LINK => $reference_link,
							SCRIPT_NAME => $script_name,
							REFERENCE_STRING => $reference_string,
						});
				} else {
					# simple text type by default 
					push(@form, {
							TYPE_FIELD => 1,
							FIELD_VALUE => $field_value, 
							EDITABLE => $editable, 
							LENGTH => $field_length, 
							FIELD_FULL_NAME => $column_name,
							FIELD_NAME => $field_name,
							PROBLEM => $problem,
							OBLIGATORY => $obligate,
							REFERENCE_LINK => $reference_link,
							SCRIPT_NAME => $script_name,
							REFERENCE_STRING => $reference_string,
						});
				}
			}
			$template->param(FORM => \@form, SCRIPT_NAME => $script_name,);
			return scalar @a;
		} else {
			$template->param(TABLE_NO_MATCH => 1);
			return 0;
		}
}

# ========= podprogramas para formar cadenas SQL o partes de tales cadenas ==================

sub form_clause {
	# forms clause for search for 4 parameters: $id as a unique identifier (? - currently included in LIKE context), and 3 more LIKE search identifiers, all from CGI input
	# search parameters should be coded in input as s_id, s_1, s_2 & s_3 respectively
	my ($id,$s_1,$s_2,$s_3,$dbh) = @_;
	my $clause = "";
	if ($id && param("s_id")) { $clause .= "$id LIKE " . $dbh->quote(&un(&trim(param("s_id")))) . " AND " }; # it is unclear if it should be opportunity to searh only for exact match or partial math for this main key field
	if ($s_1 && param("s_1")) { $clause .= "$s_1 LIKE ".$dbh->quote(&un(&trim(param("s_1")))). " AND "; };
	if ($s_2 && param("s_2")) { $clause .= "$s_2 LIKE ".$dbh->quote(&un(&trim(param("s_2")))). " AND "; };
	if ($s_3 && param("s_3")) { $clause .= "$s_3 LIKE ".$dbh->quote(&un(&trim(param("s_3")))). " AND "; };
	return $clause;
}

sub form_id_clause {
	# automaticaly form id clause for "s_id" marked field in data structure
	my ($f,$input_id,$dbh) = @_;
	my ($clause,$id) = "";
	# analyse data structure to find id parameter
	foreach my $field (keys %$f) {
		if (defined $$f{$field}{'SEARCH'} && ($$f{$field}{'SEARCH'} eq 's_id')) {
			$id = $field;
		}
	}
	if ($id && $input_id) { $clause .= "$id = " . $dbh->quote($input_id) };
	return $clause;
	}

sub form_insert_update_strings {	
	# form INSERT aud UPDATE strings using data structure of table describing hash
	# and check the input, preformati it and establish stable values for future use
	# later it is possible to add here check for unique fieldsSSeE
	my ($f,$table,$user_id,$dbh) = @_; # $user_id is necessary to set who had modified register (it is impossible to determine who deleted it)
	my ($input_error_message,$update_string,$insert_string,$field_list,$variable_list,$pairs_list) = '';
	my $s_id = &un(param("s_id"));
	my $id_clause = &form_id_clause($f,$s_id,$dbh);
	foreach my $field (  sort { $$f{$a}{'ORDER'} <=> $$f{$b}{'ORDER'} } keys %$f) {
		if ($$f{$field}{'EDIT'}) {
			$field_list .= $field. ',';
			$pairs_list .= $field. ' ';
			
			if ( param($field) ) {
				# processing form input values
				my $value = ();
				# preformat values with field-specific sub or universal sub
				my @val_list_temp = param($field); # sometimes CGI param() can return a list of values, e. g. multiple choice elements
				my @val_list = ();
				foreach my $val_to_convert (@val_list_temp)
				{
					push (@val_list, &un($val_to_convert)); # converting cgi input to utf8
				}
				# fist value we should put without comma
				my $first_val = shift @val_list; 
				if (defined $$f{$field}{'FORMAT'}) {
					$value .= $$f{$field}{'FORMAT'}->($first_val);
				} else {
					$value .= scalar &trim($first_val);
				}
				# other (list) values we should start with comma
				foreach my $val (@val_list) {
					if (defined $$f{$field}{'FORMAT'}) {
						$value .= ',' . $$f{$field}{'FORMAT'}->($val);
					} else {
						$value .= ',' . (scalar &trim($val));
					}
				}
				# check value with field-specific routine, and if problem is present - set problem flag
				if ($$f{$field}{'TEST'}->($value)) {
					$$f{$field}{'PROBLEM'} = $$f{$field}{'TEST'}->($value) || &messages('2005');
					$input_error_message = 1;
				}
				# checking if obligatory field for some reason was reduced to 0 or ""
				if ($$f{$field}{'OBLIGATORY'} && !$value) {
					$$f{$field}{'PROBLEM'} = &messages('2004');
					$input_error_message = 1;
				}
				$$f{$field}{'VALUE'} = $value; # store input values to use in form fields
				$variable_list .= &un($dbh->quote($value)). ','; # here we may have problem with unicode - quote seems not to support utf8
				$pairs_list .= '= '. &un($dbh->quote($value)). ', ';
			} else {
				if ($$f{$field}{'OBLIGATORY'}) { 
					$$f{$field}{'PROBLEM'} = &messages('2004');
					$input_error_message = 1;
				}
				$variable_list .= "NULL,";
				$pairs_list .= "= NULL, ";
			}
		}
	}
	if (!$input_error_message) {
		if (($table eq 'user') || ($table eq 'view_user')) { # special table that contains user_id as s_id field - we cannot set who modified table there
			$insert_string = "INSERT INTO $table ($field_list date_mod) VALUES ($variable_list CURDATE())";
			if ($id_clause) {
				$update_string = "UPDATE $table SET $pairs_list date_mod = CURDATE() WHERE $id_clause";
			}			
		} else {
			$insert_string = "INSERT INTO $table ($field_list user_id,date_mod,user_id_creation,date_creation) VALUES ($variable_list $user_id, CURDATE(), $user_id, CURDATE())";
			if ($id_clause) {
				$update_string = "UPDATE $table SET $pairs_list user_id = '$user_id', date_mod = CURDATE() WHERE $id_clause";
			}
		}
	}
	
	$update_string = &un($update_string);
	
	return ($insert_string,$update_string,$input_error_message);
}

# ========= podprogramas para trabajar con base de datos ejecutando cadenas SQL ==================

sub record_delete {
	# sub to delete record
	my ($sql_delete,$template,$dbh) = @_;
	if (! $sql_delete) { return (0,0); };
	my ($count,$ext_key) = 0;
	my $sth_1 = $dbh->prepare (qq{
		SELECT COUNT(*) AS count $sql_delete
	}) or &sql_error_out(&messages('1012'),$template);
	$sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
	$count = $sth_1->fetchrow_array();
	$sth_1->finish() or &sql_error_out(&messages('1014'),$template);
	# it is safe to delete something only when we have unique match to the condition of elimination
	if ($count == 1) {
		$sql_delete = 'DELETE '. $sql_delete;
		my $sth_1 = $dbh->prepare (qq{
			$sql_delete
		}) or &sql_error_out(&messages('1027'),$template);
		$count = $sth_1->execute() or &sql_error_out(&messages('1028'),$template);
		if (!$count && $DBI::err && ($DBI::err == 1451)) {
			$ext_key = 1;
		}
		$sth_1->finish() or &sql_error_out(&messages('1029'),$template);
	}
	if ($count) {
		$count_string = 'deleted: '. $count ;
		&logging($sql_delete,$count_string,$template,$dbh);
	} else {
		&logging($sql_delete,$DBI::err,$template,$dbh);
	}
	return ($count,$ext_key); # return number of entries matched and modified (normally 1)
}

sub record_update {
	# sub to update record
	my ($strict,$sql_update,$sql_search,$template,$dbh) = @_;
	# $strict defines if we need update exactly one record or it may be several records
	if (! $sql_update || ! $sql_search) { return (0,0); };
	my ($count,$ext_key) = 0;
	my $sth_1 = $dbh->prepare (qq{
		SELECT COUNT(*) AS count $sql_search
	}) or &sql_error_out(&messages('1012'),$template);
	$sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
	$count = $sth_1->fetchrow_array();
	$sth_1->finish() or &sql_error_out(&messages('1014'),$template);
	# it is safe to update something only when we have unique match to the condition of update
	if ($count == 1 || (!$strict && $count >= 1)) {
		my $sth_1 = $dbh->prepare (qq{
			$sql_update
		}) or &sql_error_out(&messages('1021'),$template);
		$count = $sth_1->execute() or &sql_error_out(&messages('1022'),$template);
		if (!$count && $DBI::err && ($DBI::err == 1452)) {
			$ext_key = 1;
		}
		$sth_1->finish() or &sql_error_out(&messages('1023'),$template);
	}
	if ($count) {
		$count_string = 'updated: '. $count ;
		&logging($sql_update,$count_string,$template,$dbh);
	} else {
		&logging($sql_update,$DBI::err,$template,$dbh);
	}
	return ($count,$ext_key); # return number of entries matched and modified (normally 1 in strict case)
}

sub record_insert {
	# sub to add new record
	my ($sql_insert,$template,$dbh) = @_;
	if (! $sql_insert) { return (0,undef,undef); };
	my ($count,$ext_key) = 0;
	my $last_id = ();
	my $sth_1 = $dbh->prepare (qq{
		$sql_insert
	}) or &sql_error_out(&messages('1024'),$template);
	$count = $sth_1->execute()  or &sql_error_out(&messages('1025'),$template);
	if (!$count && $DBI::err && ($DBI::err == 1452)) {
		$ext_key = 1;
	}
	$sth_1->finish() or &sql_error_out(&messages('1026'),$template);
	if ($count) {
		$sth_1 = $dbh->prepare (qq{
			SELECT LAST_INSERT_ID() as 'last_id'
			}) or &sql_error_out(&messages('1012'),$template);
		$sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
		$last_id = $sth_1->fetchrow_array();
		$sth_1->finish() or &sql_error_out(&messages('1014'),$template);
	};
	if ($count) {
		$count_string = 'inserted: '. $count ;
		&logging($sql_insert,$count_string,$template,$dbh);
	} else {
		&logging($sql_insert,$DBI::err,$template,$dbh);
	}
	return ($count,$last_id,$ext_key); # return number of entries added (normally 1)
}

sub reestablish_variables {
	my ($template) = @_;
	$template->param(S_ID => &un(&trim(param("s_id"))));
	$template->param(S_1 => &un(&trim(param("s_1"))));
	$template->param(S_2 => &un(&trim(param("s_2"))));
	$template->param(S_3 => &un(&trim(param("s_3"))));
	$template->param(S_UNIT => &un(&trim(param("s_unit"))));
}

1;