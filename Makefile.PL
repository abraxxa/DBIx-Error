use inc::Module::Install;

name "DBIx-Error";
license "perl";
all_from "lib/DBIx/Error.pm";
test_requires "Test::More";
test_requires "Test::Exception";
test_requires "DBI";
test_requires "DBIx::Class";
test_requires "Catalyst::Model::DBIC::Schema";

requires "Moose";
requires "MooseX::StrictConstructor";
requires "namespace::autoclean";
requires "Throwable::Error";

WriteAll;
