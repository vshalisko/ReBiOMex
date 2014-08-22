
use DBI;
use Cwd;
use CGI qw (escapeHTML);
require 'messages.pl';


my $database_error_string = (); # string to accumulate error messages

sub return_dbh {
  my ($template,$access_mode) = @_;
# == Database connection ========================================================================================================================= 
  # option file that should contain connection parameters according to access mode
  my $option_file = "invitado.cnf";
  if (defined $access_mode) {
    if ($access_mode eq "admin") {
      $option_file = "admin.cnf";
    } elsif ($access_mode eq "curador") {
      $option_file = "curador.cnf";
    } elsif ($access_mode eq "investigador") {
      $option_file = "investigador.cnf";
    } elsif ($access_mode eq "estudiante") {
      $option_file = "estudiante.cnf";
    } elsif ($access_mode =~ /lectura/i) {
      $option_file = "lectura.cnf";
    }
  }

  my $option_drive_root = &paths('R008');
  $option_file = &paths('R009') . $option_file;

  # construct data source and connect to server (under Windows, save
  # current working directory first, change location to option file
  # drive, connect, and then restore current directory)
  my $orig_dir;
  if ($option_drive_root)
  {
    $orig_dir = cwd ();
    chdir ($option_drive_root)
      or &sql_error_out(&messages('1002'),$template);
  }
  my $dsn = "DBI:mysql:rebiomex_ibug;mysql_read_default_file=$option_file";
  my $dbh = DBI->connect ($dsn, undef, undef,
        { RaiseError => 0, PrintError => 1, AutoCommit => 1, mysql_enable_utf8 => 1}) or &sql_error_out(&messages('1003'),$template);
  # parameter mysql_enable_utf8 => 1 is important for correct use of UTF-8 connection
  # $gbh->{mysql_server_prepare} = 1; # Activating of server-side prepared sentences
  # DBI->trace(1); # activation of DBI tracing to log file BE CAREFUL - huge ammount of data in log file with consequence not to be able to make consult with many data
  if ($option_drive_root)
  {
    chdir ($orig_dir)
      or &sql_error_out(&messages('1002'),$template);
  }

# workaround of server encoding problem that worked once, but does not more
#$dbh->do('SET NAMES utf8');

# another workaround of server encoding problem that worked once & I still do not know i it really necessary
# ! note that problem finaly was resolved adding skip-character-set-client-handshake to my.ini and recoding entire DB to utf8
  my $sth = $dbh->prepare (qq{
  SET 
  character_set_client = 'utf8',
  character_set_results = 'utf8',
  character_set_server = 'utf8',
  character_set_database = 'utf8',
  character_set_connection = 'utf8'
  })  or &sql_error_out(&messages('1004'),$template);
  $sth->execute()  or &sql_error_out(&messages('1005'),$template);
  $sth->finish()  or &sql_error_out(&messages('1006'),$template);

#  &sql_error_out("DBH: $dbh",$template); # debug code (returns current DBH hash)

  return $dbh;
# == End of Database connection ==================================================================================================================== 
}

sub reconnect_dbh {
  my ($access_mode,$template,$dbh_to_disconnect) = @_;
  &disconnect_dbh($dbh_to_disconnect,$template);
  my $new_dbh = &return_dbh($template,$access_mode);
  
  # debug strings for encoding problems =============================================================================
#   my $sth_debug = $dbh->prepare (qq{
#    SHOW VARIABLES LIKE '%character%'
#  })  or &sql_error_out(&messages('1004'),$template);
#   $sth_debug->execute()   or &sql_error_out(&messages('1005'),$template);
#   while (my $ref_debug = $sth_debug->fetchrow_hashref()) {
#     &sql_error_out("Debugging 2 CHARSETS setting: $ref_debug->{'Variable_name'} => $ref_debug->{'Value'}",$template);
#   };
#   $sth_debug->finish()  or &sql_error_out(&messages('1006'),$template);
  # ==========================================================================================

  return $new_dbh;
}

sub disconnect_dbh {
  my ($dbh,$template) = @_;
  if (defined $dbh) {
    # disconnection from database
    $dbh->disconnect ()  or &sql_error_out(&messages('1007'),$template);
  }
  # accumulated error string templated output
  $template->param(SQL_ERROR => $database_error_string);
}

sub sql_error_out {
  my ($message,$template) = @_;
  if (defined $DBI::err) {
  print STDERR "DB Error number ".$DBI::err." ".$DBI::errstr." ";
  # this only can print the last produced error, but rewrites all previous errors
  $database_error_string .= "<br />". escapeHTML($message.": ". &messages('1008') . " ". $DBI::err);
  } else {
  # this only can print the last produced error, but rewrites all previous errors
  if ($message) {
      $database_error_string .= "<br />". escapeHTML($message);
      print STDERR "DB Error s/n ($message)";
      } else {
      $database_error_string .= "<br />". escapeHTML(&messages('1001'));
      print STDERR "DB Error s/n (possibly server connection lost)";
      }
  }
  #$template->param(SQL_ERROR => $database_error_string); we can not output error each time, it should accumulate in a string instead
  return 0;
};

sub logging {
	# sub to add new record
	my ($sql_statement,$result, $template,$dbh) = @_;
	if (! $sql_statement) { return 0; };
	# security measure - changing of SQL keywords 
		$sql_statement =~ s/INSERT/-INSERT-/gi;
		$sql_statement =~ s/UPDATE/-UPDATE-/gi;
		$sql_statement =~ s/DELETE/-DELETE-/gi;
		$sql_statement =~ s/DROP/-DROP-/gi;
		$sql_statement =~ s/CREATE/-CREATE-/gi;
	$sql_statement = &un($dbh->quote($sql_statement));
	$result = &un($dbh->quote($result));
	my $sth_logging = $dbh->prepare (qq{
		INSERT INTO logging (sql_statement, result, execution_datetime) VALUES ($sql_statement, $result, NOW())
	}) or &sql_error_out(&messages('1024'),$template);
	my $count = $sth_logging->execute()  or &sql_error_out(&messages('1025'),$template);
	$sth_logging->finish() or &sql_error_out(&messages('1026'),$template);
	return ($count); # return number of entries added (normally 1)
}

1;