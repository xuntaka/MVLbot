package App;

use utf8;
use v5.18;

use Mojo::Base 'Mojolicious';
use App::Model;

use Carp qw(confess croak longmess);

use Mojo::Loader qw[find_modules load_class];
use Mojo::ByteStream;
use Mojo::Util qw(camelize decamelize);

use JSON;
use Data::Dumper;
use FindBin;
use App::Controller;
use App::Util;

{
	$Data::Dumper::Indent = 1; $Data::Dumper::Useqq = 1;
	no strict 'refs';
	*{'Data::Dumper::qquote'} = sub {qq{"$_[0]"}}; # вывод русского текста
}

use DBI::db; # дополняет DBI функциями select и do

our $VERSION = '0.0';

=encoding utf8

=cut

has is_cli  => undef; # detect CLI
has db      => sub { shift->schema->storage->dbh };

has schema => sub {
	my $self  = shift;

	my $class = $self->config->{'model'}->{'schema_class'};

	if (my $error = load_class($class)) {
		croak("Can't load schema class $class\: $error");
	}

	my $schema = $class->connect($self->config->{'model'}->{'connect_info'});

	$schema->exception_action(sub {
		my $msg = shift;

		my (@caller, $i);
		my $re = qr/^App::/;
			 $re = qr/^main$/ if $self->is_cli;
		while (my @c = caller $i++) {
			next unless $c[0] =~ $re;
			@caller = @c;
		}

		$msg .= ' at ' . $caller[1] . ' line ' . $caller[2];

		if ($self->is_dev) {
			confess($msg);
		} else {
			croak($msg);
		}
	});

	$schema->storage->dbh->do("set names 'utf8'");

	return $schema;
};

has cache => sub {
	my $self = shift;
	my $class = $self->config->{'cache'}{'class'};

	if (my $error = load_class($class)) {
		croak("Can't load cache class $class\: $error");
	}

	return $class->new($self->config->{'cache'}{'settings'});
};

has proxy         => sub { App::Proxy    ->new('app' => shift) };
has queue         => sub { App::Queue    ->new('app' => shift) };
has request_cache => sub { +{} };

has 'ua_name' => 'Mozilla/5.0 (compatible; MVLBot;)';

sub ua {
	my $self = shift;
	# 'ua' - глобальный. Переопределение параметров ua влияют на всех
	my $ua = $self->SUPER::ua(@_);
	$ua->transactor->name($self->ua_name);
	return $ua;
};

=head2 API

API accessor

=cut

sub API {
	my $self = shift;
	my $name = shift;

	for ($name) {
		s{^\s+}{};
		s{\s+$}{};
		s{^(?:app[:-]+)?logic[:-]+}{}ix;
		s{^::}{};
	}

	my $aname = 'App::Api::' . camelize(decamelize($name));

	die longmess('Unknown API ' . $aname) if load_class($aname);

	$aname->new(
		'app' => $self,
		@_
	);
}

=head2 L

Logic accessor

=cut

sub L {
	my $self = shift;
	my $name = shift;

	for ($name) {
		s{^\s+}{};
		s{\s+$}{};
		s{^(?:app[:-]+)?logic[:-]+}{}ix;
		s{^::}{};
	}

	my $lname = 'App::Logic::' . camelize(decamelize($name));

	die longmess('Unknown logic ' . $lname) if load_class($lname);

	$lname->new(
		'app' => $self,
		@_
	);
}

=head2 M
Model accessor

	my $site = $self->M('App::Model::Site')->get(1);
	my $site = $self->M('Model::Site'     )->get(1);
	my $site = $self->M('Site'            )->get(1);
	my $site = $self->M('App-Model-Site'  )->get(1);
	my $site = $self->M('Model-Site'      )->get(1);
	my $site = $self->M('app-model-site'  )->get(1);
	my $site = $self->M('model-site'      )->get(1);
	my $site = $self->M('site'            )->get(1);

=cut
sub M {
	my $self = shift;
	my $name = shift;

	for ($name) {
		s{^\s+}{};
		s{\s+$}{};
		s{^(?:app[:-]+)?model[:-]+}{}ix;
		s{^::}{};
	}

	my $mname = 'App::Model::' . camelize(decamelize($name));

	die longmess('Unknown model ' . $mname) if load_class($mname);

	$mname->new(
		'app' => $self,
	);
}

sub is_dev { shift->mode eq 'development' }

# This method will run once at server start
sub startup {
	my $self = shift;

	$self->plugin('Config', 'file' => $self->home->rel_file('conf/app.conf'));

	$self->set_mode;
	$self->set_logs;

	$self->sessions->cookie_name  ($self->config->{'cookie'}->{'name'  });
	$self->sessions->cookie_domain($self->config->{'cookie'}->{'domain'});

	$self->secrets(['6xaYfTyvP8MQQ8qnZ8kTavDE']);

	$self->types->type('json' => 'application/json; charset=utf-8');

	my $https_conf = $self->config->{'https'};
		 $https_conf = { on => $https_conf } unless ref $https_conf;

	$self->plugin('Mail', $self->config->{'mail'});

	$self->plugin('App::Plugin::Logger'        );
	$self->plugin('App::Plugin::Helpers'       );
	$self->plugin('App::Plugin::Helpers::Dates');
	$self->plugin('App::Plugin::Recaptcha', $self->config->{'recaptha'});
	$self->plugin('App::Plugin::Notify');

	$self->controller_class('App::Controller');

	$self->plugin('App::Router'        );
	$self->plugin('App::Router::Admin' );

	$self->_load_modules;

	$self->_hooks;

	$self->log->info('Started in ' . $self->mode . ' mode.');
}

sub set_mode {
	my $self = shift;
	my $mode = shift || $self->config->{'mode'};

	# Если режим из конфига не совпадает с режимом, в котором запустились,
	# то переключаемся.
	$self->mode($mode) if $mode && $mode ne $self->mode;
}

=head2 set_logs

Всё, что связано с настройкой логов

=cut

sub set_logs {
	my $self = shift;
	my $name = $self->mode;
	my $home = $self->home;

	if ($self->is_cli) {
		($name) = $0 =~ m{(?:.*/)?(.+)\.pl$};
	}

	if ($name && -w $home->rel_file('log')) {
		$self->log(
			Mojo::Log->new(
				'path' => $home->rel_file("log/$name.log"),
			)
		);
	}

	$self->log->level('info') unless $self->is_dev;
}

sub _load_modules {
	my $self = shift;

	load_class('Data::Page');

	$self->_load_models($_) foreach qw[
		App::Errors
		App::Logic
		App::Model
		App::Queue
		App::Sorter
		App::Util
	];
}

sub _load_models { #recursion
	my $self = shift;
	my $model = shift || 'App::Model';

	my $e = load_class($model); return if ref $e;
	foreach (find_modules($model)) {
		my $e = load_class($_); next if ref $e;
		$self->_load_models($_);
	}
}

sub _hooks {
	my $app = shift;

	#referral
	$app->hook('before_dispatch' => sub {
		my $self = shift;
		$app->sessions->secure($self->is_https);
	});

	# flush req. cache
	$app->hook('after_dispatch'  => sub { $app->request_cache({}) });
}

package Mojo::ByteStream;
sub TO_JSON { shift->to_string }

package Mojo::URL;
sub TO_JSON { shift->to_string }

1;
