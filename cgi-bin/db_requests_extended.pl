# additional requests that include modifiation of DB
use IO::CaptureOutput qw(capture);
require 'messages.pl';

sub dump_sql {
  # dumping of SQL code execution
  my ($sql_code,$template,$dbh) = @_;
  my ($sql_result,$stderr,$ping_result) = undef;
  $ping_result = $dbh->ping;
  my $sth_1 = $dbh->prepare (qq{
    $sql_code
  }) or &sql_error_out(&messages('1018'),$template);
  $sth_1->execute() or &sql_error_out(&messages('1019'),$template);
  # dump results
  capture sub { sql_dump_results($sth_1) }, \$sql_result, \$stderr;
  $sth_1->finish() or &sql_error_out(&messages('1020'),$template);
  return ($sql_result, $stderr, $ping_result);
}

sub sql_dump_results {
	# sub to dump results of SQL code execution
	$sth = shift; 
	$sth->dump_results(32768, "\n", ", ");
}

sub user_access_update {
	# sub to update or set user access level, login and password
	my ($user_id,$login,$password,$access,$template,$dbh) = @_;

	my $sth_1 = $dbh->prepare (qq{
	    SELECT COUNT(*) AS count, COUNT(user_access.user_access) AS count_user_access 
	    FROM user LEFT JOIN user_access 
	    ON user.user_id <=> user_access.user_id 
	    WHERE user.user_id = '$user_id'
	  }) or &sql_error_out(&messages('1012'),$template);
	$sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
	my ($count,$user_access) = $sth_1->fetchrow_array();
	$sth_1->finish() or &sql_error_out(&messages('1014'),$template);
	
	if (defined $count && ($count > 0) && defined $user_access && ($user_access > 0)) {
		# we have a user account to modify
		my $sth_1 = $dbh->prepare (qq{
		UPDATE user, user_access 
		SET 
		user.user_login = '$login',
		user_access.user_password = '$password',
		user_access.user_access = '$access',
		user_access.date_mod = CURDATE()
		WHERE user.user_id = user_access.user_id
		AND user.user_id = '$user_id'
	    }) or &sql_error_out(&messages('1021'),$template);
	    $sth_1->execute()  or &sql_error_out(&messages('1022'),$template);
	    $sth_1->finish() or &sql_error_out(&messages('1023'),$template);
	} elsif (defined $count && ($count > 0) && defined $user_access && ($user_access == 0)) {
			# we have to add a new user account
			my $sth_1 = $dbh->prepare (qq{
			INSERT INTO user_access (user_id,user_password,user_access,date_mod)
			VALUES ('$user_id','$password','$access',CURDATE())
			}) or &sql_error_out(&messages('1024'),$template);
			$sth_1->execute()  or &sql_error_out(&messages('1025'),$template);
			$sth_1->finish() or &sql_error_out(&messages('1026'),$template);
			$sth_1 = $dbh->prepare (qq{
				UPDATE user
				SET 
				user_login = '$login'
				WHERE user_id = '$user_id'
			}) or &sql_error_out(&messages('1021'),$template);
			$sth_1->execute()  or &sql_error_out(&messages('1022'),$template);
			$sth_1->finish() or &sql_error_out(&messages('1023'),$template);
	}
	return $count; # return number of entries matched and modified (normally 1)

}

sub user_access_delete {
	# sub to update or set user access level, login and password
	my ($user_id,$template,$dbh) = @_;
	my $sth_1 = $dbh->prepare (qq{
	    SELECT COUNT(*) AS count FROM user_access WHERE user_id = '$user_id'
	}) or &sql_error_out(&messages('1012'),$template);
	$sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
	my ($count) = $sth_1->fetchrow_array();
	$sth_1->finish() or &sql_error_out(&messages('1014'),$template);
	if (defined ($count) && ($count == 1)) {
		my $sth_1 = $dbh->prepare (qq{
		DELETE FROM user_access WHERE user_id = '$user_id'
		}) or &sql_error_out(&messages('1027'),$template);
		$sth_1->execute()  or &sql_error_out(&messages('1028'),$template);
		$sth_1->finish() or &sql_error_out(&messages('1029'),$template);
	}
	return $count; # return number of entries matched and modified (normally 1)
}

sub user_update {
	# sub to update or set user access level, login and password
	my ($user_id,$login,$user_name,$user_institution,$user_comment,$template,$dbh) = @_;
	my $count = 0;
	if ($user_id) {
	       my $sth_1 = $dbh->prepare (qq{
		    SELECT COUNT(*) AS count
		    FROM user
		    WHERE user_id = '$user_id'
		}) or &sql_error_out(&messages('1012'),$template);
		$sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
		$count = $sth_1->fetchrow_array();
		$sth_1->finish() or &sql_error_out(&messages('1014'),$template);
	}
	
	if (defined $user_id && $user_id && defined $count && ($count > 0)) {
		# we have a user account to modify
		my $sth_1 = $dbh->prepare (qq{
			UPDATE user
			SET 
			user_login = '$login',
			user_name = '$user_name',
			institution = '$user_institution',
			comment = '$user_comment',
			date_mod = CURDATE()
			WHERE user_id = '$user_id'
		}) or &sql_error_out(&messages('1021'),$template);
		$sth_1->execute()  or &sql_error_out(&messages('1022'),$template);
		$sth_1->finish() or &sql_error_out(&messages('1023'),$template);
	} else {
		# we have to add a new user account
		my $sth_1 = $dbh->prepare (qq{
			INSERT INTO user (user_login, user_name, institution, comment, date_mod)
			VALUES 
			('$login', '$user_name', '$user_institution', '$user_comment', CURDATE())
		}) or &sql_error_out(&messages('1024'),$template);
		$sth_1->execute()  or &sql_error_out(&messages('1025'),$template);
		$sth_1->finish() or &sql_error_out(&messages('1026'),$template);
		$count++;
	}
	return $count; # return number of entries matched and modified (normally 1)

}

sub user_delete {
	# sub to update or set user access level, login and password
	my ($user_id,$template,$dbh) = @_;
	my ($count,$ext_key) = 0;
	my $sth_1 = $dbh->prepare (qq{
	    SELECT COUNT(*) AS count FROM user WHERE user_id = '$user_id'
	}) or &sql_error_out(&messages('1012'),$template);
	$sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
	($count) = $sth_1->fetchrow_array();
	$sth_1->finish() or &sql_error_out(&messages('1014'),$template);
	# it is safe to delete something only when we have unique match to the condition of elimination
	if (defined ($count) && ($count == 1)) {
		my $sth_1 = $dbh->prepare (qq{
			DELETE FROM user WHERE user_id = '$user_id'
		}) or &sql_error_out(&messages('1027'),$template);
		$sth_1->execute()  or &sql_error_out(&messages('1028'),$template);
		if ($DBI::err && $DBI::err == 1451) {$count = 0; $ext_key = 1;};
		$sth_1->finish() or &sql_error_out(&messages('1029'),$template);
	}
	return ($count,$ext_key); # return number of entries matched and modified (normally 1)
}

sub set_login {
	  # it is necessary to add deleting of expired records when we have entrance of user with same login as record to expire and to add check of host from where logging-in
	  # sub to get user_id from main database, should be modified to select information about acces provilegies and passwords from another table
	  my ($user_identifier,$user_id,$user_login,$user_access,$user_ip,$user_host,$template,$dbh) = @_;
	  my $user_login_host = "";
	  if (defined $user_host && $user_host) { $user_login_host .= $user_host; } else { $user_login_host .= "host no-identificado"; };
	  if (defined $user_ip && $user_ip) { $user_login_host .= " (" .$user_ip. ")"; } else { $user_login_host .= " (direccion ip desconocido)"; };
	  
	  my $sth_1 = $dbh->prepare (qq{
	    INSERT INTO login (user_identifier,user_id,user_login,user_access,last_login,last_login_host) 
	    VALUES('$user_identifier','$user_id','$user_login','$user_access',NOW(),'$user_login_host')
	  }) or &sql_error_out(&messages('1024'),$template);
	  $sth_1->execute()  or &sql_error_out(&messages('1025'),$template);
	  $sth_1->finish() or &sql_error_out(&messages('1026'),$template);
	  
	  # secondary task of deleting of old records (records elder than 3 days are considered as expired): this script is unter testing
	  $sth_1 = $dbh->prepare (qq{
	    SELECT COUNT(*) AS count FROM login WHERE last_login < ADDDATE(NOW(),INTERVAL -1 DAY)
	  }) or &sql_error_out(&messages('1012'),$template);
	  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
	  my ($count) = $sth_1->fetchrow_array();
	  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
	  if (defined ($count) && ($count > 0)) {
	    my $sth_1 = $dbh->prepare (qq{
	    DELETE FROM login WHERE last_login < ADDDATE(NOW(),INTERVAL -1 DAY)
	    }) or &sql_error_out(&messages('1027'),$template);
	    $sth_1->execute()  or &sql_error_out(&messages('1028'),$template);
	    $sth_1->finish() or &sql_error_out(&messages('1029'),$template);
	  }
	  return $count; # return number of entries expired and deleted 
 }

sub set_logout {
	  # sub to delete specified user_identifiers from table login
	  my ($user_identifier,$template,$dbh) = @_;
	  my $sth_1 = $dbh->prepare (qq{
	    SELECT COUNT(*) AS count FROM login WHERE user_identifier = '$user_identifier'
	  }) or &sql_error_out(&messages('1012'),$template);
	  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
	  my ($count) = $sth_1->fetchrow_array();
	  $sth_1->finish() or &sql_error_out(&messages('1014'),$template);
	  if (defined ($count) && ($count > 0)) {
	    my $sth_1 = $dbh->prepare (qq{
	    DELETE FROM login WHERE user_identifier = '$user_identifier'
	    }) or &sql_error_out(&messages('1027'),$template);
	    $sth_1->execute()  or &sql_error_out(&messages('1028'),$template);
	    $sth_1->finish() or &sql_error_out(&messages('1029'),$template);
	  }
	  return $count; # return number of entries to delete (deleted)
 }

sub regenerate_col_det_agent {
	  # sub to delete specified user_identifiers from table login
	  my ($template,$dbh) = @_;
	  my ($table_record_count) = undef;
	  # really ugly solution, it should use stored procedures instread, that are not available in current MySQL environment for the reason that need root privileges to be executed
	  # may be it is better to use here transaction ?
	  
	  my $sth_1 = $dbh->prepare (qq{
		DROP TABLE IF EXISTS col_det_agent;
	  }) or &sql_error_out(&messages('1012'),$template);
	  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);

	  $sth_1 = $dbh->prepare (qq{
		  CREATE
		  TABLE col_det_agent
		  (
		  agent_id INT(10) UNSIGNED NOT NULL,
		  agent VARCHAR(1000) NOT NULL,
		  agent_sorting_name VARCHAR(100) NOT NULL,
		  persons_in_team INT(2) UNSIGNED NOT NULL DEFAULT 1,
		  PRIMARY KEY (agent_id),
		  INDEX (agent),
		  INDEX (agent_sorting_name)
		  ) ENGINE=InnoDB CHARACTER SET = utf8
		  AS
		  SELECT
		  teams.team_id AS agent_id,
		  GROUP_CONCAT(DISTINCT persons.person_string ORDER BY teams.leader_flag DESC, persons.person_string SEPARATOR ', ') AS agent,
		  MAX(persons.person_string) AS agent_sorting_name,
		  COUNT(teams.team_person_id) AS persons_in_team
		  FROM persons, teams
		  WHERE
		  teams.person_id = persons.person_id
		  GROUP BY teams.team_id
		  ORDER BY teams.leader_flag DESC
	  }) or &sql_error_out(&messages('1012'),$template);
	  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);

	  $sth_1 = $dbh->prepare (qq{
		SELECT COUNT(*) AS table_record_count FROM col_det_agent;
	  }) or &sql_error_out(&messages('1012'),$template);
	  $sth_1->execute()  or &sql_error_out(&messages('1013'),$template);
	  while (my $ref_1 = $sth_1->fetchrow_hashref()) {
	    $table_record_count = $ref_1->{'table_record_count'};
	  }
	  $sth_1->finish() or &sql_error_out(&messages('1020'),$template);
	  return ($table_record_count);
}

1;