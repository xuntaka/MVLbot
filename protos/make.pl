#!/usr/bin/perl -w

use v5.18;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib",
        "$FindBin::Bin/../extlib";
use local::lib "$FindBin::Bin/../local";

use Cwd;
use Carp;
use FindBin;
use File::Path qw/make_path/;
use Mojo::Util qw/slurp spurt decode encode/;
use Mojolicious 6.60;
use Mojolicious::Plugin::Config;

use Data::Dumper;
$Data::Dumper::Indent = 1;

$SIG{__WARN__} = \&Carp::cluck;
$SIG{__DIE__ } = \&Carp::confess;

# warn Dumper \%ENV;

sub run {
	my $home = Mojo::Home->new(shift);

	my $config = Mojolicious::Plugin::Config->parse(
		decode('UTF-8', slurp $ENV{'LOCAL_CONF'})
	);

	my $ver = $ENV{'REVISION'} || '';
	   $ver =~ s/(\S{7}).*/$1/s;

	$config->{'release_version'} = $ver || time();

	say "Release: $config->{'release_version'}";

	my $mt = Mojo::Template->new->vars(1);

	my $files = $home->list_files($ENV{'PROTOS'});
	foreach my $tmpl_fn (@$files) {
		next unless $tmpl_fn =~ /\.ep$/;

		my $fn = $tmpl_fn;
		   $fn =~ s/\.ep$//g;

		say "Make $fn";

		my $tmpl = $home->rel_file($ENV{'PROTOS'} . "/$tmpl_fn");
		my $output = $mt->render_file($tmpl, {
			'config'   => $config,
			'approot'  => $home->to_string,
			'userhome' => $ENV{'HOME'}
		});

		my $f_out = $home->rel_file("/$fn");
		my $dir   = $f_out =~ s{/[^/]*$}{}r;
		make_path($dir, {'verbose' => 1});
		spurt(encode('UTF-8', $output), $f_out);
		`chmod +x $f_out` if -x $tmpl;
	}
}

my $approot = Cwd::abs_path($ENV{'CURDIR'} || "$FindBin::Bin/../");

run($approot);
