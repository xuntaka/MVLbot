package App::Queue::Worker;

use Net::Server 0.96 ();
use Mojo::Base -base;
use parent 'Net::Server::MultiType';

use Mojo::Loader qw[load_class];

use Carp;
use TheSchwartz 1.10;

$SIG{__DIE__} = \&Carp::confess;

has app => undef;

my @workers;

sub default_values {
	return {
		'min_servers'       => 1,  # min num of servers to always have running
		'max_servers'       => 8,  # max num of servers to run
		'min_spare_servers' => 1,  # min num of servers just sitting there
		'max_spare_servers' => 1,  # max num of servers just sitting there
		'max_requests'      => 10, # num of requests for each child to handle
		'log_level'         => 4,
	};
}

sub bind {
	my $self = shift;
	$self->{server}{sock} = [];

	my $ts = $self->{server}{_schwartz} = $self->app->queue->schwartz;

	$ts->set_verbose( sub {
		my $msg = shift;
		$self->log(3, $msg, @_) unless $msg eq 'TheSchwartz::work_once found no jobs';
	} );
	
	foreach my $module ( @workers ) {
		$self->log(3, "TheSchwartz->can_do('$module')");
		$ts->can_do($module);
	}
}

sub accept {
	my $self = shift;
	my TheSchwartz $ts = $self->{server}{_schwartz};

	while (1) {
		$ts->restore_full_abilities;
		return 1 if $self->{server}{job} = $ts->find_job_for_workers;
		sleep 5;
	}
}

sub run_client_connection {
	my $self = shift;
	$self->{'server'}{'requests'}++;
	my TheSchwartz $ts = $self->{server}{_schwartz};
	$ts->work_once($self->{server}{job});
}

sub child_finish_hook { shift->app->schema->disconnect }

sub start {
	my $self = shift;
	@workers = @{shift()};

	foreach my $w (@workers) {
		warn $w;
		if (my $error = load_class($w)) {
			croak("Can't load queue class $w\: $error");
		}
	}

	my @types = qw(Single PreFork PreForkSimple);

	$self->run(server_type=>\@types, @_);
}

1;
