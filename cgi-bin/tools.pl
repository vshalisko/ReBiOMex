# small useful subs
# ==================================================================================================================
use locale;
use Text::ParseWords;
use Time::Local;
use Encode;

require 'messages.pl';

sub un {
  # establish utf8 encoding for string if it has no utf8 flag yet
  my $string = shift;
  if (!Encode::is_utf8($string)) {
		return Encode::decode_utf8($string);
	} else {
		return $string; 
	}
}

sub whitespace_clean {
	# code from HTML::Template::Compiled::Filter::Whitespace module
	my $scalarref = shift;
	${$scalarref} =~ tr{\0}{ };
	my @unclean;
	while (
		${$scalarref} =~ s{(
		    < \s* (pre | code | textarea) [^>]* > 	# opening pre-, code
										# or textarea tag
		    .*?                                   			# content
		    < \s* / \2 [^>]* >                    		# closing tag
		    )}{\0}xmsi
	) 
	{
		push @unclean, $1;
	}
	${$scalarref} =~ s{
		(?: ^ \s*)              			# leading spaces and empty lines
		|
		(?: [^\S\n]* $)
		|
		([^\S\n]* (?: \n | \z)) 			# spaces at EOL
		|
		([^\S\n]{2,})           			# spaces between text
	    }{ $1 ? "\n" : $2 ? q{ } : q{} }xmsge;
#	${$scalarref} =~ s{([^\n\r])[\n\r]+}{$1\n}g;
	for my $unclean (@unclean) 
	{
		${$scalarref} =~ s{\0}{$unclean}xms;
	}
	return;
}

sub parse_unit_list {
  my $string = $_[0];
  if (!defined $string) { $string = ''; };
  return quotewords("a",0, $string);
}

sub parse_unit_pairs {
  my $string = $_[0];
  if (!defined $string) { $string = ''; };
  return quotewords("b",0, $string);
}

sub parse_csv {
  my $string = $_[0];
  if (!defined $string) { $string = ''; };
  return quotewords(",",0, $string);
}

sub parse_words {
  my $string = $_[0];
  if (!defined $string) { $string = ''; };
  return quotewords(" ",0, $string);
}

sub trim {
  my @out = @_;
  for (@out) {
    s/^\s+//;
    s/\s+$//;
  };
  return wantarray ? @out : $out[0];
}

sub URLescape { 
    # URL-encode string 
    my ($toencode) = @_; 
    if (!defined $toencode) { $toencode = ''; };
    $toencode=~s/([^a-zA-Z0-9_\-. ])/uc sprintf("%%%02x",ord($1))/eg; 
    $toencode =~ tr/ /+/;    # spaces become pluses 
    return $toencode; 
} 


sub etiquetes_number {
	my $etiquetes = shift;
	my $n = 0;
	if (defined $etiquetes) {
		my @etiquetes_list = &parse_unit_list($etiquetes);
		foreach my $etiquete (@etiquetes_list) {
			$etiquete =~ /^\d+b\d+b(\d+)b?\d*$/i;
			if (defined $1) {$n += $1;}
		}
	}
	return $n;
}

sub password_check {
	# return 0 if there is a problem, and 1 if iti is ok
	my $candidate = shift;
	if ($candidate =~ s/\s//gi) { return 0; };
	if ( length($candidate) > 6 ) { return $candidate; };
	return 0;
}

sub check_update {
	my ($old,$new) = @_;
	my $update = 0;
	if ((!$old && $new) || ($old && !$new) || (defined $old && defined $new && ($old ne $new))) 
	{ 
		$update = 1; 
	};
	return $update;
}

sub deg2sec {
  # transforms coordinates to html-compartible string
  # it is necessary to implement here control of 
  # rouning or truncating level 
  my $value = shift;
  my $sign = ();
  if ($value < 0) {$sign = "-";} else {$sign = "+";};
  my $deg = int $value;
  my $fract = abs ($value-$deg);
  my $min = int ($fract*60);
  my $fract1 = abs(($fract*60)-$min);
  my $sec = int ($fract1*60);
        $deg = abs $deg;
  my $string = $deg."°".$min."'".$sec."\"";
  return ($string,$sign);
}

sub format_date {
	my ($unformated_date) = @_;
	my $formated_date = $unformated_date;
	if ($unformated_date && $unformated_date =~ /(\d+)-(\d+)-(\d+)/)
	{
		# first type date
		$formated_date = '';
		my ($yyyy, $mm, $dd) = ($unformated_date =~ /(\d+)-(\d+)-(\d+)/);
		if ($yyyy) { $formated_date = $yyyy;}
		if ($mm && $formated_date) { $formated_date .= "-" . $mm ;}
		if ($dd && $formated_date) { $formated_date .= "-" . $dd ;}
		if (!$formated_date && $mm && $dd) { $formated_date = $mm . "-" . $dd ;}
	}
	elsif (($unformated_date && $unformated_date =~ /(\d+)\/(\d+)\/(\d+)/))
	{
		# second type date
		$formated_date = '';
		my ($dd, $mm, $yyyy) = ($unformated_date =~ /(\d+)\/(\d+)\/(\d+)/);
		if ($yyyy) { $formated_date = $yyyy;}
		if ($mm && $formated_date) { $formated_date = $mm . "/" . $formated_date;}
		if ($dd && $formated_date) { $formated_date = $dd ."/" . $formated_date ;}
		if (!$formated_date && $mm && $dd) { $formated_date = $dd . "/" . $mm ;}
	}
	return $formated_date;
}

sub cmp_date {
	# compare two dates in YYYY-MM-DD format
	# if first is less than second than output is -1, if first is more than second than output is 1, if they are equal than 0
	my ($first_date,$second_date) = @_;
	my ($f_yyyy, $f_mm, $f_dd) = ($first_date =~ /(\d+)-(\d+)-(\d+)/);
	my ($s_yyyy, $s_mm, $s_dd) = ($second_date =~ /(\d+)-(\d+)-(\d+)/);
	if ($f_yyyy eq '0000') { $f_yyyy++ }
	if ($s_yyyy eq '0000') { $s_yyyy++ }
	if ($f_mm eq '00') { $f_mm++ }
	if ($s_mm eq '00') { $s_mm++ }
	if ($f_dd eq '00') { $f_dd++ }
	if ($s_dd eq '00') { $s_dd++ }
	# calculate epoch seconds at midnight on that day in this timezone
	my $f_epoch_seconds = timelocal(0, 0, 0, $f_dd, $f_mm-1, $f_yyyy);
	my $s_epoch_seconds = timelocal(0, 0, 0, $s_dd, $s_mm-1, $s_yyyy);
	if ($f_epoch_seconds < $s_epoch_seconds)
	{
		return -1;
	}
	elsif ($f_epoch_seconds > $s_epoch_seconds)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

# subs to preformat strings and remove undesired symbols ==============================================================
# string in the input - string in the output
# ==================================================================================================================

sub format_flag {
	# only alphanumeric symbols and _ % are allowed; others are substututed by _
	my $string = shift;
	if (defined $string && $string) {
		return 1;
	} else {
		return undef;
	}
}

sub escape_input_common {
	# all is allowed excepting spaces in the begining and at the end, and new lines, as well transform several spaces to one
	my $string = shift;
	if (defined $string) {
		$string =~ s/\s+/ /msg;
		$string = &trim($string);
	}
	return $string;
}

sub escape_input {
	# only alphanumeric symbols and _ % are allowed; others are substututed by _
	my $string = shift;
	if (defined $string) {
		$string = &trim($string);
		$string =~ s/\s+//msg;
		$string =~ s/[^\p{Word}_%-]/_/gi;
	}
	return $string;
}

sub escape_input_1 {
	# only spaces, alphanumeric symbols and _ % are allowed others are substituted by _
	my $string = shift;
	if (defined $string) {
		$string = &trim($string);
		$string =~ s/\s+/ /msg;
		$string =~ s/[^\p{Word}\s_%-]/_/gi;
	}
	return $string;
}

sub escape_input_2 {
	# only spaces, alphanumeric symbols and _ are allowed others are substituted by _
	my $string = shift;
	if (defined $string) {
		$string = &trim($string);
		$string =~ s/\s+/ /msg;
		$string =~ s/%//msg;
		$string =~ s/[^\p{Word}\s_-]/_/gi;
	}
	return $string;
}

sub escape_numeric_input {
	# only numbers and _ %are allowed
#	my $string = shift;
#	if (defined $string) {
#		$string =~ s/[^0-9%_]//g;
#		$string = &trim($string);
#	}
#	return $string;
	my @string = @_;
	foreach my $st (@string) {
		$st =~ s/[^0-9%_]//g;
		&trim($st);
	};
	return wantarray ? @string : $string[0];
}

sub escape_decimal_input {
	# only numbers and - . _ %are allowed
	my $string = shift;
	if (defined $string) {
		$string =~ s/,/./g;
		$string =~ s/[^0-9-\.%_]//g;
		$string = &trim($string);
	}
	return $string;
}

sub escape_date {
	# only numbers, - and % ? are allowed; / are substituted by -
	my $string = shift;
	if (defined $string) {
		$string =~ s/\//-/g;
		$string =~ s/[^0-9-%_]//g;
		$string = &trim($string);
	}
	return $string;
}

sub escape_date_1 {
	# only numbers, - and % ? are allowed; / are substituted by -
	my $string = shift;
	if (defined $string) {
		$string =~ s/[^0-9%_\/]//g;
		$string = &trim($string);
	}
	return $string;
}


sub escape_etiquetes_list {
	# only a, b symbols, numbers and - are allowed
	my $string = shift;
	if (defined $string) {
		$string =~ s/[^ab0-9-]//gi;
		$string = &trim($string);
	}
	return $string;
}


# subs to check input for correct format and result error string or 0 if there is no problem  ========================================
# this subs require messages.pl module to return messages

sub check_text {
	# only checks for presence of numbers
	my $candidate = shift;
	if ($candidate =~ m/\d/gi) { return &messages('2001'); };
	return 0;
}

sub check_number {
	# only checks for presence of no-numbers
	my $candidate = shift;
	if ($candidate =~ m/\D/gi) { return &messages('2002'); };
	return 0;
}

sub check_decimal_number {
	my $candidate = shift;
	# checks for presence of all excepting decimal numbers
	if ($candidate =~ m/[^0-9-\.]/gi) { return &messages('2006'); };
	return 0;
}

sub check_image_basename {
	# only allows letters and numbers _ -
	my $candidate = shift;
	if ($candidate =~ m/[^A-Za-z0-9-_]/gi) { return &messages('2007'); };
	return 0;
}

sub check_gag {
	# this do nothing, only works as a gag
	my $candidate = shift;
	return 0;
}

sub check_date {
	my $candidate = shift;
	if (!($candidate =~ m/\d\d\d?\d?-\d\d?-\d\d?/i)) { return &messages('2003'); };
	return 0;
}

1;