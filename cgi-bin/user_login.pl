use CGI qw (:standard escapeHTML escape);
require 'tools.pl';
require 'messages.pl';

sub login_status {
# templated output of login status
	my ($template,$dbh) = @_;
	my ($user_id,$user_identifier,$user_name,$user_access,$etiquetes);
# == Login status ================================================================================================================================== 
	if (cookie('user_identifier')) {
		# user had logged in previously and have cookie with sessionidentifier
		 $user_identifier = cookie('user_identifier');
		 ($user_id,$user_name,$user_access,$etiquetes) = &get_user_login($user_identifier,$template,$dbh); 	# gen username from user identifier using DB  
		 # if user name is successfuly recovered from database we need to output login status, if not - do nothing, 
		 if ((defined $user_name))
		{
			$dbh = &set_user_access($user_name,$user_access,$template,$dbh);
			if (defined $etiquetes) {
			# there are some etiquetes ordened
			my $etiquetes_number = etiquetes_number($etiquetes);
			$template->param(
				CANASTA => 1,
				ETIQUETES_NUMBER => escapeHTML($etiquetes_number),
			);
		}
		}
	}
	return ($user_id,$user_identifier,$user_name,$user_access,$etiquetes,$dbh)
# == End of Login status ============================================================================================================================ 
}

sub canasta_login_status {
# templated output of login status
	my ($template,$dbh) = @_;
	my ($user_id,$user_identifier,$user_name,$user_access,$etiquetes);
# == Canasta login status ================================================================================================================================== 
	if (cookie('user_identifier')) {
		# user had logged in previously and have cookie with sessionidentifier
		 $user_identifier = cookie('user_identifier');
		 ($user_id,$user_name,$user_access,$etiquetes) = &get_user_login($user_identifier,$template,$dbh); 	# gen username from user identifier using DB  
		 # if user name is successfuly recovered from database we need to output login status, if not - do nothing, 
		 if ((defined $user_name))
		{
			$dbh = &set_user_access($user_name,$user_access,$template,$dbh);
		}
	}
	return ($user_identifier,$user_name,$user_access,$etiquetes,$dbh);
# == End of Canasta login status ============================================================================================================================ 
}

sub set_user_access {
	# set user access levels in template
	my ($user_name,$user_access,$template,$dbh) = @_;
	$template->param(USER_LOGIN => escapeHTML(&un($user_name)));
	my ($user_full_name,$user_institution);
	($user_full_name,$user_institution) = &get_user_name_login($user_name,$template,$dbh);
	if ($user_full_name)
	{
		$template->param(USER_FULL_NAME => escapeHTML(&un($user_full_name)));
	}
	if ($user_institution)
	{
		$template->param(USER_INSTITUTION => escapeHTML(&un($user_institution)));
	}
	if (defined $user_access) {
		if ($user_access && ($user_access =~ /lectura/i)) {
			$template->param(USER_ACCESS => 'lectura');
		} else {
			$template->param(USER_ACCESS => $user_access);
			# setting up access levels in template
			if ($user_access eq "admin") {
				$template->param(ADMIN => 1, SCRIPT_NAME => 'admin.cgi',);
			} elsif ($user_access eq "curador") {
				$template->param(CURADOR => 1, SCRIPT_NAME => 'curador.cgi',);
			} elsif ($user_access eq "investigador") {
				$template->param(INVESTIGADOR => 1, SCRIPT_NAME => 'investigador.cgi',);
			} elsif ($user_access eq "estudiante") {
				$template->param(ESTUDIANTE => 1, SCRIPT_NAME => 'estudiante.cgi',);
			}
		}
		$dbh = &reconnect_dbh($user_access,$template,$dbh)
	} else {
		$template->param(USER_ACCESS => 'invitado');
	}
	return $dbh;
}

# this sub is here and not in db_requests to reduce code load
sub get_user_login {
	# database request for login status
	  my ($user_identifier,$template,$dbh) = @_;
	  my ($user_login,$access_mode,$etiquetes_ordened) = undef;
	  my $sth_1 = $dbh->prepare (qq{
	    SELECT user_id, user_login, user_access, etiquetes_ordened 
	    FROM login
	    WHERE user_identifier = '$user_identifier'
	    LIMIT 1
	  }) or &sql_error_out(&messages('1015'),$template);
	  $sth_1->execute()  or &sql_error_out(&messages('1016'),$template);
	  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
	    $user_id = $ref_1->{'user_id'};
	    $user_login = $ref_1->{'user_login'};
	    $access_mode = $ref_1->{'user_access'};
	    $etiquetes_ordened = $ref_1->{'etiquetes_ordened'};
	  }
	  $sth_1->finish() or &sql_error_out(&messages('1017'),$template);
	  return ($user_id,$user_login,$access_mode,$etiquetes_ordened);
}

sub get_user_name_login {
  # sub to get user_name
  my ($user_login,$template,$dbh) = @_;
  my ($user_name,$user_institution) = undef;
  my $sth_1 = $dbh->prepare (qq{
    SELECT user_name, institution 
    FROM user
    WHERE user_login = '$user_login' 
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
