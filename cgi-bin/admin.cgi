#!/usr/bin/perl -w

# admin interface
BEGIN {
    my $base_module_dir = (-d '/home2/rebiomex/perl' ? '/home2/rebiomex/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use Carp; # carp - debug module, comment this to reduce log size
$SIG{__WARN__} = \&carp;
$SIG{__DIE__} = \&confess;

use strict;
use locale;
use CGI qw (:standard escapeHTML escape);
use HTML::Template;
use Encode;
require 'tools.pl';
require 'messages.pl';

our $script_name = 'admin.cgi'; # making it as a global variable to let table processing.pl script to use it and pass to template

my $template = HTML::Template->new(filename => 'ibug_access.tmpl', max_includes => 20,filter => sub {
                            my $ref = shift;
                            ${$ref} = Encode::decode_utf8(${$ref});
          $ref = &whitespace_clean($ref);
                        });

require 'db_connection.pl';
my $pre_dbh=&return_dbh($template);

require 'user_login.pl';
my ($admin_id,undef,undef,$access_mode) = &login_status($template,$pre_dbh);

my $dbh=&reconnect_dbh($access_mode,$template,$pre_dbh);

require 'db_requests.pl';
require 'db_requests_extended.pl';

if (param('user_access')) 
{
	  my ($new_user_login_problem,$new_user_password_problem,$new_user_access_problem,$problem) = '';
	  $template->param(USER_ACCESS_ADMINISTRATION => 1);
	  if (  param('search_user') 
	    || param('search_login') 
	    || param('search_user_name')
	    || param('search_user_access_date') )
	{
		    # user access list
		    my $clause = &clause_user();
		    if (  param('delete_login') && param('search_user') ) 
		    {
		      # deleting of access account
		      $template->param(LOGIN_DELETE => 1);
		      if (&user_access_delete(&escape_numeric_input(&un(param("search_user"))),$template,$dbh)) 
		      {
			$template->param(LOGIN_DELETE_SUCCESS => 1);
		      }
		    } 
		    if (param('edit_login')) 
		    {
		      # editing of access account
		      $template->param(LOGIN_EDIT => 1);
		    }

		    if (param('update_login')) 
		    {
		      my @user_list_ref_1 = &user_list_full($clause,$template,$dbh);
		      my $mod_flag = ''; # flag "modification solicited"
		      if (scalar @user_list_ref_1) # checks if we have at least one value
		      {
			my $user_ref_1 = shift @user_list_ref_1;
			if (  defined param("new_login") 
			  && (param("new_login")
			  && (!(defined $$user_ref_1->{user_login}) 
			  || ($$user_ref_1->{user_login} ne &un(param("new_login"))))) 
			  || (!$$user_ref_1->{user_login} && !param("new_login"))) 
			{
			  # we have new login to check and to modify
			  my $user_id = &get_user_id(&escape_input(&un(param("new_login"))),$template,$dbh);
			  if ($user_id || !(param("new_login"))) {$new_user_login_problem = 1;}
			  $mod_flag = 1;
			}
			if (  defined param('new_password') && param('new_password') 
			    && (!(defined $$user_ref_1->{user_password}) #~there was no password stored previously
			    || (crypt(&un(param('new_password')),$$user_ref_1->{user_password}) ne $$user_ref_1->{user_password})) # setting new password
			  )
			{
			  # we have new password to check and/or to modify
			  if (
			    !(&password_check(&un(param('new_password')))) # password do not pass test
			    || !(defined param('confirm_new_password')) # empty confirmation password
			    || (&un(param('confirm_new_password')) ne &un(param('new_password'))) # incorrect confirming password
			  ) 
			  { 
			    $new_user_password_problem = 1;
			  }
			  $mod_flag = 1;
			}
			if (  $$user_ref_1->{user_password} && !param('new_password') )  # erasing password
			{
			  # we have empty new password - this is not allowed
			  if (!(&password_check(&un(param('new_password'))))) 
			  { 
			    $new_user_password_problem = 1;
			  }
			  $mod_flag = 1;
			}
			if (  defined param("new_access") 
			  && (param("new_access") 
			  && (!(defined  $$user_ref_1->{user_access}) 
			  || ($$user_ref_1->{user_access} ne &un(param("new_access")))))) 
			{
			  # we have new acccess to check and to modify
			  if (!(param("new_access") =~ /admin|curador|investigador|estudiante|local-lectura|web-lectura/i)) 
			  {
			    $new_user_access_problem = 1;
			  }
			  $mod_flag = 1;
			}
			if (!$new_user_login_problem && !$new_user_password_problem && !$new_user_access_problem) 
			{
			  $template->param(LOGIN_UPDATE => 1); # flag of update attempt
			  my $encoded_password = '';
			  if (&password_check(&un(param('new_password')))) 
			  {
			    $encoded_password = crypt(&un(param('new_password')),'a4'); # creting DES 56 digest of pasword to store it in database
			  }
			  if ($mod_flag 
			    && &user_access_update($$user_ref_1->{user_id},&escape_input(&un(param("new_login"))),$encoded_password,param("new_access"),  $template,$dbh)) 
			  {
			    $template->param(LOGIN_UPDATE_SUCCESS => 1); # flag of update success
			  }
		      
			}
			else 
			{
			  #we have some problem with input data and need to request tham ones more
			  $template->param(LOGIN_EDIT => 1);
			  $problem = 1;
			}
		      }
		    }

		    my @user_list_ref = &user_list_full($clause,$template,$dbh);
		    if (scalar @user_list_ref) # checks if we have at least one value
		    {
		      my @user_list = ();
		      foreach my $user_ref (@user_list_ref) {
			my %user = ();
			if (defined $$user_ref->{user_id}) {$user{USER_ID} = escapeHTML(&un($$user_ref->{user_id}));};
			if (defined $$user_ref->{user_login}) {$user{USER_NAME} = escapeHTML(&un($$user_ref->{user_login}));};
			if (defined $$user_ref->{user_name}) {$user{USER_REAL_NAME} = escapeHTML(&un($$user_ref->{user_name}));};
			if (defined $$user_ref->{user_access}) {$user{USER_ACCESS} = escapeHTML(&un($$user_ref->{user_access}));};
			if ((param("edit_login") || $problem)) {
			  if (defined $$user_ref->{user_access} && $$user_ref->{user_access} =~ /admin/i) {
			    $user{USER_ACCESS_ADMIN} = 1;
			  } elsif (defined $$user_ref->{user_access} && $$user_ref->{user_access} =~ /investigador/i) {
			    $user{USER_ACCESS_INVESTIGADOR} = 1;
			  } elsif (defined $$user_ref->{user_access} && $$user_ref->{user_access} =~ /curador/i) {
			    $user{USER_ACCESS_CURADOR} = 1;
			  } elsif (defined $$user_ref->{user_access} && $$user_ref->{user_access} =~ /estudiante/i) {
			    $user{USER_ACCESS_ESTUDIANTE} = 1;
			  } elsif (defined $$user_ref->{user_access} && $$user_ref->{user_access} =~ /local-lectura/i) {
			    $user{USER_ACCESS_LECTURALOCAL} = 1;
			  } else {
			    $user{USER_ACCESS_LECTURAWEB} = 1;
			  }
			}
			if (defined $$user_ref->{user_password}) 
		  {
		    # we dont need tu output user password from database, in any way it is stored as digest, byt we output only one symbol to set it as defined
		    $user{USER_PASSWORD} ='+++++';
		  } 
			if (defined $$user_ref->{date_reg}) {$user{USER_REGISTER_TIME} = escapeHTML(&un($$user_ref->{date_reg}));};
			if (defined $$user_ref->{date_mod}) {$user{USER_MODIFICATION_TIME} = escapeHTML(&un($$user_ref->{date_mod}));};
			if (defined $$user_ref->{last_login}) {$user{USER_LOGIN_TIME} = escapeHTML(&un($$user_ref->{last_login}));};
			if (defined $$user_ref->{last_login_host}) {$user{USER_LOGIN_HOST} = escapeHTML(&un($$user_ref->{last_login_host}));};
			if (defined param("update_login") && param("update_login") && $new_user_login_problem) { 
			  $user{USER_LOGIN_PROBLEM} = 1; 
			  $user{USER_NAME} = escapeHTML(&escape_input&un((param("new_login"))));
			};
			if (defined param("update_login") && param("update_login") && $new_user_password_problem) { 
			  $user{USER_PASSWORD_PROBLEM} = 1; 
			  $user{USER_PASSWORD} = escapeHTML(&un(param('new_password')));
			};
			if (defined param("update_login") && param("update_login") && $new_user_access_problem) { $user{USER_ACCESS_PROBLEM} = 1; };
			if (!($$user_ref->{user_access})) { $user{USER_REGISTER} = 1; };
			push(@user_list, \%user);
		      }
		    $template->param(USER_LIST => \@user_list);
		    }
		    else
		    {
		      $template->param(USER_LIST_NO_MATCH => 1);
		    }
	}
}

my $table = &un(param("table")) || ''; # define table to work with
my $action = &un(param("action")) || 'start';  # define action to realize

if (($table eq "view_user") || param("users")) 
{
	# interface de administracion de los usuarios
	$template->param(USER_ADMINISTRATION => 1);

	# copy from curador interface ========================================================================

	require 'db_table_definitions.pl';

	if ($table eq "view_user") {
		  &v_user($action,$table,$admin_id,$template,$dbh);
	} else {
		  # if no table is defined than we need to output interface of initial table selection
		  $template->param(TABLE_SELECT_OUTPUT => 1);
	}
	$template->param(TABLE_NAME => $table);


	# copy from curador interface ========================================================================
}

if (param("sql")) {
  # interface de execucion de sql
  $template->param(SQL_EXECUTION => 1);
  if (param("sql_code")) {
    $template->param(SQL_CODE => param("sql_code"));
    my ($sql_result,$sql_error,$ping_result) = &dump_sql(param("sql_code"),$template,$dbh);
    $template->param(SQL_CODE_RESULT => &escapeHTML(&un($sql_result)));
    $template->param(SQL_CODE_ERROR => &escapeHTML(&un($sql_error)));
    $template->param(SQL_PING_RESULT => &escapeHTML($ping_result));
  
  }
}

$template->param(
    PAGE_TITLE => &messages('9010'),
    ADMIN_INTERFACE => 1,
  );

&disconnect_dbh($dbh,$template);

# page output

print "Content-type: text/html; charset=utf-8\n\n";
binmode STDOUT, ":utf8";
print $template->output;

sub clause_user {
# sub to make conditions for search in user table
    my $clause_string = '';
    if ((defined param("search_user")) && (param("search_user") =~ /(\d+)/i)) {
        # search for user specified by user_id
        $clause_string .= "user.user_id = '$1' AND ";
    }
    if (param("add_user")) {
        # search for user specified by user_id
        $clause_string .= "user.user_id = 0 AND ";
    }
    if (param("search_login")) {
        # search for user specified by login
        my $search_login = &escape_input(param("search_login"));
        $clause_string .= "user.user_login LIKE '$search_login' AND ";
    }
    if (param("search_user_name")) {
        # search for user specified by user name
        my $search_user_name = &escape_input_1(param("search_user_name"));
        $clause_string .= "user.user_name LIKE '$search_user_name' AND ";
    }
    if (param("search_user_date")) {
        # search for user specified by date
        my $search_user_date = &escape_date(param("search_user_date"));
        $clause_string .= "user.date_mod LIKE '$search_user_date' AND ";
    }
    if (param("search_user_access_date")) {
        # search for user specified by date
        my $search_user_date = &escape_date(param("search_user_access_date"));
        $clause_string .= "user_access.date_mod LIKE '$search_user_date' AND ";
    }
  return $clause_string;
};

exit (0);

