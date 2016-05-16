#!/usr/bin/env perl
use strict;
use v5.18;

use Cwd;
use FindBin;
use Mojo::Home;
use Mojo::Util qw[slurp spurt decode encode];
use Mojo::Template;
use Mojolicious::Plugin::Config;

use DBIx::Class::Schema::Loader qw[make_schema_at];

say $DBIx::Class::Schema::Loader::VERSION;

my $approot = Cwd::abs_path("$FindBin::Bin/");
my $home    = Mojo::Home->new($approot);
my $config  = Mojolicious::Plugin::Config->parse(decode('UTF-8', slurp $home->rel_file('conf/local.conf')));

make_schema_at(
  'App::Schema',
  {
    'debug'                   => 1,
    'dump_directory'          => './lib',
    'overwrite_modifications' => 1,
  },
  [
    "dbi:Pg:dbname=$config->{'db'}->{'database'};" .
    "host=$config->{'db'}->{'host'};" .
    "port=$config->{'db'}->{'port'}",
    $config->{'db'}->{'user'    },
    $config->{'db'}->{'password'},
  ],
);
