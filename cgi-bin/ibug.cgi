#!/usr/bin/perl -w

# ibug.cgi - simple templated output & user login process
BEGIN {
    my $base_module_dir = (-d '/home2/rebiomex/perl' ? '/home2/rebiomex/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use strict;
use locale;

use Carp; # carp - debug module, comment this to reduce log size
$SIG{__WARN__} = \&carp;
$SIG{__DIE__} = \&confess;

use CGI qw (:standard escapeHTML escape);
use HTML::Template;
use Data::Random::String;
use Encode;
require 'tools.pl';
require 'messages.pl';

my $template = HTML::Template->new(filename => 'ibug.tmpl', max_includes => 20, filter => sub {
                            my $ref = shift;
                            ${$ref} = Encode::decode_utf8(${$ref});
          $ref = &whitespace_clean($ref);
                        });

require 'db_connection.pl';
my $dbh=&return_dbh($template);

require 'user_login.pl';

require 'db_requests.pl';
require 'db_requests_extended.pl';

my $about = param ("about") || '';
my $help = param ("help") || '';
my $error = param ("error") || '';

{
# user identification or login
my ($user_id,$complete_login,$login_logout,$logout,$expired,$user_name,$proposed_user_access,$authorized_user_access,$user_password,$password_form,$etiquetes);

if (param('user_login')) {
  # user just logged in, cookie with session identifier should be established
  # it is necessary to check if this user is registered one with rights specified or not 
  # (check presence in "user" table, if present - output form with password field for full login, 
  # if not - proceed with read-only access)
  $user_name = &escape_input( &un(param('user_login')) );
  $user_password = &escape_input( &un(param('user_password')) );
  # generation of unique user identifier
  $user_id = Data::Random::String->create_random_string(length=>'50', contains=>'alphanumeric');
  my ($authorized_user_id,$authorized_password);
  # check for presence of authorized account with this name
  ($authorized_user_id,$proposed_user_access,$authorized_password) = &get_user_id($user_name,$template,$dbh);
  if (!(defined $proposed_user_access)) {$proposed_user_access = 'web-lectura';}
  $authorized_user_access = 'web-lectura';
  if ($authorized_user_id) {
    # user name was recognized as authorized login, password check form to login and set access mode
    if ($user_password) {
            # password verification: if good - $complete_login, if not - $password_form
            if (crypt($user_password, $authorized_password) eq $authorized_password) # using of crypt() function to check DES 56 digest of password
            
                        
            {
        $authorized_user_access = $proposed_user_access;
        &set_login($user_id,$authorized_user_id,$user_name,$authorized_user_access,$ENV{'REMOTE_ADDR'},$ENV{'REMOTE_HOST'},$template,$dbh);
        $complete_login = 1;
            } else {
        $template->param(USER_ACCESS => $proposed_user_access);
        $template->param(PASSWORD_ERROR => 1);
        $password_form = 1;
           }
    } else {
        # empty password form
        $template->param(USER_ACCESS => $proposed_user_access);
        $password_form = 1;
    }
  } else {
    if ($user_password) {
      # password here as indicatir of confirmation of login
      # storage of identifier en DB with default read-only access (web-lectura)
      $template->param(USER_NOT_RECOGNISED => 1);
      &set_login($user_id,0,$user_name,$authorized_user_access,$ENV{'REMOTE_ADDR'},$ENV{'REMOTE_HOST'},$template,$dbh);
      $complete_login = 1; # in case that login is complete and wee need to establish cookie
    } else {
      # login as unrecognised user is not confirmed
      $template->param(USER_NOT_RECOGNISED => 1, GUEST_LOGIN_CONFIRMATION => 1,);
      $password_form = 1;
    }
  }
  $login_logout = 1; # login/logout process flag
} elsif (cookie('user_identifier')) {
    # user had logged in previously and have cookie with sessionidentifier
    $user_id = cookie('user_identifier');
    (undef,$user_name,$authorized_user_access,$etiquetes) = &get_user_login($user_id,$template,$dbh);   # gen username from user identifier using DB 
    if (!(defined $user_name)) {
      # expired login: should remove cookie and cancel logged in status
      $expired = 1;
    }
    if (param('logout')) {
      # user that had logged in previously want to logout
      # logout means elimination of ccokie and elimination of record in DB
      &set_logout($user_id,$template,$dbh);
      $logout = 1;
      $login_logout = 1; # login/logout process flag
    }
} 
# if user is identified (logged-in previously) and his login is not expired and we are not logging out
#if (((defined $user_name) && (not $logout) && (not $password_form)) || ($complete_login))
if ((defined $user_name && not $logout) || ($complete_login))
{
    $dbh = &set_user_access($user_name,$authorized_user_access,$template,$dbh);
    if (defined $etiquetes) {
    # there are some etiquetes ordened
    my $etiquetes_number = &etiquetes_number($etiquetes);
    $template->param(
    CANASTA => 1,
    ETIQUETES_NUMBER => escapeHTML($etiquetes_number),
    );
    }
};

if ($about) 
{
  $template->param(
  PAGE_TITLE => &messages('9001'),
  ABOUT => 1,
  );
 } 
 elsif ($help) 
 {
  $template->param(
  PAGE_TITLE => &messages('9016'),
  HELP => 1,
  );
} 
elsif ($login_logout) 
{
  if ($logout) 
  {
    # logout report
    $template->param(
    PAGE_TITLE => &messages('9002'),
    LOGIN => 1,
    LOGIN_LOGOUT => 1,
    LOGIN_LOGOUT_NAME => &un($user_name),
    );
  } 
  elsif ($complete_login) 
  {
    # login complete report
    $template->param(
    PAGE_TITLE => &messages('9004'),
    LOGIN => 1,
    LOGIN_LOGIN => 1,
    );
  }
  elsif ($password_form)
  {
    # login incomplete form
    $template->param(
    PAGE_TITLE => &messages('9003'),
    LOGIN => 1,
    LOGIN_LOGIN_FORM => 1,
    );
  } 
} 
elsif (!($about || $error || $help)) 
{
  if (cookie('user_identifier'))
  {
    # login complete report
    $template->param(
    PAGE_TITLE => &messages('9003'),
    LOGIN => 1,
    LOGIN_LOGIN => 1,
    );
  }
  else
  {
    # login incomplete form
    $template->param(
    PAGE_TITLE => &messages('9003'),
    LOGIN => 1,
    LOGIN_FORM => 1,
    );
  }
}

# header output
if ($complete_login) {
    #sending cookie to store session and set expiration time of 2 days, record in DB should expire before expiration of cookie in normal conditions
    # may be it would be useful to check if user had accessed records recently to set expiration period
    my $cookie = cookie (-name=>'user_identifier',value=>$user_id,-expires=>'+2d');
    print header (-type=>"text/html", -charset=>"utf-8", -cookie=>$cookie);
} elsif ($logout || $expired) {
    #sending expiration time of cookie to now
    my $cookie = cookie (-name=>'user_identifier',value=>$user_id,-expires=>'-10m');
    print header (-type=>"text/html", -charset=>"utf-8", -cookie=>$cookie);
} else {
  print header (-type=>"text/html", -charset=>"utf-8");
}

}

&disconnect_dbh($dbh,$template);

# page output
# printing of http header is not necessary here (we already have one)
binmode STDOUT, ":utf8";
print $template->output;

exit (0);



