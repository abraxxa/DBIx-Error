#!perl -T

our $bindir;
use FindBin;
BEGIN { ( $bindir ) = ( $FindBin::Bin =~ /^(.*)$/ ) } # Untaint

use Test::More;
use Test::Exception;
use File::Spec::Functions qw ( :ALL );
use DBI;
use strict;
use warnings;

BEGIN {
  use_ok ( "DBIx::Error" );
}

# We need to allow regression tests to run without a proper database
# backend such as Postgres to test against.  We therefore use SQLite.
# The DBI driver for SQLite does not support SQLSTATE; we hack around
# this by parsing the error message for some recognised keywords, and
# set the SQLSTATE accordingly.
#
sub sqlite_fake_sqlstate {
  ( my $h, my $err, my $errstr, my $state ) = @_;
  if ( $err && ! defined $state ) {
    if ( $errstr =~ /NULL/i ) {
      $state = "23502";
    } elsif ( $errstr =~ /unique/i ) {
      $state = "23505";
    }
    $_[3] = $state;
  }
  return undef;
}

my $dbfile = catfile ( $bindir, "lib", "test.db" );
my $dbh = DBI->connect ( "dbi:SQLite:".$dbfile, undef, undef,
			 { HandleError => DBIx::Error->HandleError,
			   HandleSetErr => \&sqlite_fake_sqlstate } );

# Unique constraint violation
{
  $dbh->begin_work();
  lives_ok { $dbh->do ( "INSERT INTO test ( id, name ) VALUES ( 1, 'Me' )" ) };
  throws_ok { $dbh->do ( "INSERT INTO test ( id, name ) VALUES ( 1, 'You' )" ) }
      "DBIx::Error::UniqueViolation";
  $dbh->rollback();
}

# Null constraint violation
{
  $dbh->begin_work();
  throws_ok { $dbh->do ( "INSERT INTO test ( id, name ) VALUES ( 1, NULL )" ) }
      "DBIx::Error::NotNullViolation";
  $dbh->rollback();
}

done_testing();
