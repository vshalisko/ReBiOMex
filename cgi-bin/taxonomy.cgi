#!/usr/bin/perl -w

# ibug_taxonomy.cgi - to make request related to taxonomy

BEGIN {
    my $base_module_dir = (-d '/home2/rebiomex/perl' ? '/home2/rebiomex/perl' : ( getpwuid($>) )[7] . '/perl/');
    unshift @INC, map { $base_module_dir . $_ } @INC;
}

use strict;
use locale;
use CGI qw (:standard escapeHTML escape);
use HTML::Template;
use Encode;
require 'tools.pl';
require 'messages.pl';

my $template = HTML::Template->new(filename => 'ibug.tmpl', max_includes => 20,filter => sub {
                            my $ref = shift;
                            ${$ref} = Encode::decode_utf8(${$ref});
          $ref = &whitespace_clean($ref);
                        });

require 'db_connection.pl';
my $dbh=&return_dbh($template);

require 'user_login.pl';
my (undef,undef,undef,$access_mode) = &login_status($template,$dbh);

require 'db_requests.pl';

# value to look for in unit_id
my $subgeneric_id = &un(param ("subgeneric_id"));
my $familia_id = &un(param ("familia_id"));
my $genus_id = &un(param ("genus_id"));
my $familia = &un(param ("familia"));
my $genus = &un(param ("genus"));
my $specie = &un(param ("specie"));
my $infraspecific_epithet = &un(param ("infraspecific_epithet"));
my ($subgeneric_flag,$genus_flag,$familia_flag) = (0,0,0); # flags to transfer acces levels

my $clause = ();

if (defined $subgeneric_id && $subgeneric_id) 
{
  $clause .= "view_taxonomy.subgeneric_id = " . $dbh->quote(&escape_numeric_input($subgeneric_id)) . " AND\n";
  ($subgeneric_flag,$genus_flag,$familia_flag) = (1,1,1);
}
if (defined $familia_id && $familia_id) 
{
  $clause .= "view_taxonomy.familia_id = " . $dbh->quote(&escape_numeric_input($familia_id)) . " AND\n"; 
  ($subgeneric_flag,$genus_flag,$familia_flag) = (0,0,1);
}
if (defined $familia && $familia) 
{
  $clause .= "( view_taxonomy.familia LIKE " . $dbh->quote(&escape_input($familia)) . " OR view_taxonomy.familia_synonym LIKE " . $dbh->quote(&escape_input($familia)) . " ) AND\n"; 
  ($subgeneric_flag,$genus_flag,$familia_flag) = (0,0,1);
}
if (defined $genus_id && $genus_id) 
{
  $clause .= "view_taxonomy.genus_id = " . $dbh->quote(&escape_numeric_input($genus_id)) . " AND\n";  
  ($subgeneric_flag,$genus_flag,$familia_flag) = (0,1,1);
}
if (defined $genus && $genus) 
{
  $clause .= "view_taxonomy.genus LIKE " . $dbh->quote(&escape_input($genus)) . " AND\n";  
  ($subgeneric_flag,$genus_flag,$familia_flag) = (0,1,1);
}
if (defined $specie && $specie) 
{
  $clause .= "view_taxonomy.specie LIKE " . $dbh->quote(&escape_input($specie)) . " AND\n";  
  ($subgeneric_flag,$genus_flag,$familia_flag) = (1,1,1);
}
if (defined $infraspecific_epithet && $infraspecific_epithet) 
{
  $clause .= "view_taxonomy.infraspecific_epithet LIKE " . $dbh->quote(&escape_input($infraspecific_epithet)) . " AND\n";  
  ($subgeneric_flag,$genus_flag,$familia_flag) = (1,1,1);
}
$template->param( 
  SUBGENERIC_ID => $subgeneric_id || $subgeneric_flag, 
  GENUS_ID => $genus_id || $genus_flag, 
  FAMILIA_ID => $familia_id || $familia_flag,
  );

if ($clause) 
{
  my (@taxonomy_ref,@taxonomy_list) = ();
  if ($subgeneric_flag == 0 && $genus_flag == 0 && $familia_flag == 1)
  {
    @taxonomy_ref = &get_taxonomy_familia($clause,$template,$dbh);
  }
  else
  {
    @taxonomy_ref = &get_taxonomy($clause,$template,$dbh);
  }
  $template->param(TAXONOMY_RECORD_NUM => scalar @taxonomy_ref);
  if (scalar @taxonomy_ref > 1)
  {
    $template->param(TAXONOMY_LIST_VIEW => 1);
  } 
  elsif (scalar @taxonomy_ref < 1)
  {
    $template->param(NO_MATCH => 1);
  }
  foreach my $entity_ref (@taxonomy_ref) 
  {
    my %taxonomy = ();
    my $subgeneric_id = ();
    if (defined $$entity_ref->{subgeneric_id}) 
    {
      $taxonomy{SUBGENERIC_ID} = $$entity_ref->{subgeneric_id};
      $subgeneric_id = $$entity_ref->{subgeneric_id};
    }
    else
    {
      $taxonomy{SUBGENERIC_ID} = $subgeneric_id || $subgeneric_flag;
    }
    if (defined $$entity_ref->{genus_id}) 
    {
      $taxonomy{GENUS_ID} = $$entity_ref->{genus_id};
    }
    else
    {
      $taxonomy{GENUS_ID} = $genus_id || $genus_flag;
    }
    if (defined $$entity_ref->{familia_id}) 
    {
      $taxonomy{FAMILIA_ID} = $$entity_ref->{familia_id};
    }
    else
    {
      $taxonomy{FAMILIA_ID} = $familia_id || $familia_flag;
    }   
    if (defined $$entity_ref->{genus}) 
    {
      # genus level
      if (defined $$entity_ref->{genus_author_id}) 
      {
        my $author = &get_author($$entity_ref->{genus_author_id},$template,$dbh);
        if (defined $author)
        {
          $taxonomy{GENUS_AUTHOR} = escapeHTML(&un($author));
        }
      }
      $taxonomy{GENUS} = escapeHTML(&un($$entity_ref->{genus}));
      if (defined $$entity_ref->{genus_comment}) 
      {
        $taxonomy{GENUS_COMMENT} = escapeHTML(&un($$entity_ref->{genus_comment}));
      }
    }
    else
    {
      $taxonomy{GENUS} = &messages('8001');
    }
    if (defined $$entity_ref->{specie}) 
    {
      # specie level
      $taxonomy{SPECIE} = escapeHTML(&un($$entity_ref->{specie}));
      if (defined $$entity_ref->{infraspecific_epithet}) 
      {
        # Infraspecific level
        $taxonomy{INFRASPECIFIC} = '1';
        if (defined $$entity_ref->{infraspecific_flag}) 
        {
          $taxonomy{INFRASPECIFIC_FLAG} = escapeHTML(&un($$entity_ref->{infraspecific_flag}));
        }
        if (defined $$entity_ref->{infraspecific_epithet}) 
        {
          $taxonomy{INFRASPECIFIC_EPITHET} = escapeHTML(&un($$entity_ref->{infraspecific_epithet}));
          if (defined $$entity_ref->{specie} && ($$entity_ref->{specie} eq $$entity_ref->{infraspecific_epithet}))
          {
            if (defined $$entity_ref->{specie_author_id})
            {
              $taxonomy{AUTHOR} = escapeHTML(&un(&get_author($$entity_ref->{specie_author_id},$template,$dbh)));
            }
            elsif (defined $$entity_ref->{infraspecific_author_id})
            {
              # correcting error if no specie author, but infraspecific author only is defined
              $taxonomy{AUTHOR} = escapeHTML(&un(&get_author($$entity_ref->{infraspecific_author_id},$template,$dbh)));
            }
          }
          else
          {
            if (defined $$entity_ref->{infraspecific_author_id}) 
            {
              my $author = &get_author($$entity_ref->{infraspecific_author_id},$template,$dbh);
              if (defined $author)
              {
                $taxonomy{INFRASPECIFIC_AUTHOR} = escapeHTML(&un($author));
              }
            }
          }
        }
      }
      else
      {
        # No-infraspecific
        if (defined $$entity_ref->{specie_author_id}) 
        {
          my $author = &get_author($$entity_ref->{specie_author_id},$template,$dbh);
          if (defined $author)
          {
            $taxonomy{AUTHOR} = escapeHTML(&un($author));
          }
        } 
      }
    }
    else
    {
      $taxonomy{SPECIE} = &messages('8003');
    }
    if (defined $$entity_ref->{hybrid_specie}) 
    {
      # hybrid specie
      $taxonomy{HYBRID} = '1';
      if (defined $$entity_ref->{hybrid_flag}) 
      {
        $taxonomy{HYBRID_FLAG} = escapeHTML(&un($$entity_ref->{hybrid_flag}));
      }
      else 
      {
        $taxonomy{HYBRID_FLAG} = 'x';
      }
      if (defined $$entity_ref->{hybrid_genus_id}) 
      { ;
        my $hybrid_genus = &get_genus($$entity_ref->{hybrid_genus_id},$template,$dbh);
        if (defined $hybrid_genus) {
          $taxonomy{HYBRID_GENUS} = escapeHTML(&un($hybrid_genus));
        }
        my $hybrid_family = &get_family($$entity_ref->{hybrid_genus_id},$template,$dbh);
        if (defined $hybrid_family)
        {
          $taxonomy{HYBRID_FAMILY} = escapeHTML(&un($hybrid_family));
        }
      }
      else
      {
        $taxonomy{HYBRID_GENUS} = &messages('8001');
      }
      if (defined $$entity_ref->{hybrid_specie}) 
      {
        $taxonomy{HYBRID_SPECIE} = escapeHTML(&un($$entity_ref->{hybrid_specie}));
      }
      else
      {
        $taxonomy{HYBRID_SPECIE} = &messages('8003');
      }
      if (defined $$entity_ref->{hybrid_author_id}) 
      {
        my $author = &get_author($$entity_ref->{hybrid_author_id},$template,$dbh);
        if (defined $author) 
        {
          $taxonomy{HYBRID_AUTHOR} = escapeHTML(&un($author));
        }
      }
    }
    if (defined $$entity_ref->{subgeneric_comment}) 
    {
      $taxonomy{SUBGENERIC_COMMENT} = escapeHTML(&un($$entity_ref->{subgeneric_comment}));
    }
    if (defined $$entity_ref->{taxa_count}) 
    {
      $taxonomy{TAXA_COUNT} = escapeHTML(&un($$entity_ref->{taxa_count}));
    }
    if (defined $$entity_ref->{preferred_taxa_count}) 
    {
      $taxonomy{PREFERRED_TAXA_COUNT} = escapeHTML(&un($$entity_ref->{preferred_taxa_count}));
    }

#========= status list ==============================================================
    if ($subgeneric_id)
    {
      my @status_list_ref = &status_list($subgeneric_id,$template,$dbh); 
      if (scalar @status_list_ref) # checks if we have at least one reference
      {
        my @status_list = ();
        foreach my $status_ref (@status_list_ref) 
        {
          my %status = ();
          $status{SUBGENERIC_ID} = escapeHTML(&un($subgeneric_id));
          if (defined $$status_ref->{pubid}) 
          {
            $status{PUBID} = escapeHTML(&un($$status_ref->{pubid}));
          }
          if (defined $$status_ref->{status_detail} && defined $$status_ref->{pubabbreviation}) 
          {
            $status{STATUS} = escapeHTML(&un($$status_ref->{status_detail}));
            $status{PUBABBREVIATION} = escapeHTML(&un($$status_ref->{pubabbreviation}));
            if (defined $$status_ref->{pubdate}) 
            {
              $status{PUBDATE} = escapeHTML(&un($$status_ref->{pubdate}));
            }
          }
          if (defined $$status_ref->{comment}) 
          {
            $status{STATUS_COMMENT} = escapeHTML(&un($$status_ref->{comment}));
          }
          push(@status_list, \%status);
        }
        $taxonomy{STATUS_LIST} = \@status_list;
      }
    }
#=========== end of status list ============================================================
    
    if (defined $$entity_ref->{familia}) 
    {
      # family and higher levels
      $taxonomy{FAMILY} = escapeHTML(&un($$entity_ref->{familia}));
      if (defined $$entity_ref->{familia_comment}) 
      {
        $taxonomy{FAMILY_COMMENT} = escapeHTML(&un($$entity_ref->{familia_comment}));
      }
      if (defined $$entity_ref->{familia_author_id}) 
      {
        my $author = &get_author($$entity_ref->{familia_author_id},$template,$dbh);
        if (defined $author) 
        {
          $taxonomy{FAMILY_AUTHOR} = escapeHTML(&un($author));
        }
      }
      if (defined $$entity_ref->{ordo}) 
      {
        $taxonomy{ORDO} = escapeHTML(&un($$entity_ref->{ordo}));
      }
      if (defined $$entity_ref->{classis}) 
      {
        $taxonomy{CLASSIS} = escapeHTML(&un($$entity_ref->{classis}));
      }     
      if (defined $$entity_ref->{phylum}) 
      {
        $taxonomy{PHYLUM} = escapeHTML(&un($$entity_ref->{phylum}));
      }
    }
    if (defined $$entity_ref->{regnum}) 
    {
      # regnum level
      $taxonomy{REGNUM} = escapeHTML(&un($$entity_ref->{regnum}));
      if (defined $$entity_ref->{regnum_comment}) 
      {
        $taxonomy{REGNUM_COMMENT} = escapeHTML(&un($$entity_ref->{regnum_comment}));
      }
    }
    
    push(@taxonomy_list, \%taxonomy);
  }
  $template->param(TAXONOMY_LIST => \@taxonomy_list);
} 
else
{
  # if we have nothing in clause we need to prepare request form
  $template->param( NO_CLAUSE => 1,);
}

$template->param(
      PAGE_TITLE => &messages('9015'),
      TAXONOMY => 1,
    );

&disconnect_dbh($dbh,$template);

# page output
print "Content-type: text/html; charset=utf-8\n\n";
binmode STDOUT, ":utf8";
print $template->output;

exit (0);
