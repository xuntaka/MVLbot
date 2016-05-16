package App::Queue::Common;

use Mojo::Base -base;
use parent 'TheSchwartz::Worker';

use Carp qw[croak];
use Mojo::Loader qw[load_class];
use Mojo::JSON qw[decode_json encode_json];
use TheSchwartz;
use TheSchwartz::Job;

has app       => undef;
has billing   => sub { shift->app->billing   };
has config    => sub { shift->app->config    };
has queue     => sub { shift->app->queue     };
has scheduler => sub { shift->app->scheduler };

=head2 API

API accessor

=cut

sub API {
  my $self = shift;
  my $name = shift;

  $self->app->API($name)->params(@_);
}

=head2 L

Logic accessor

=cut

sub L {
  my $self = shift;
  my $name = shift;

  $self->app->L($name)->params(@_);
}

=head2 M

Model accessor

  Alias for App::M()

=cut

sub M { shift->app->M(@_) }

sub max_retries { 5 }
sub retry_delay { 60 * $_[1] }
sub keep_exit_status_for { 3600 }
sub grab_for { 600 } # TODO: 600-3600 for production

sub work {
	my $self = shift->new('app' => $::app);

	my TheSchwartz::Job $job = shift;
	my TheSchwartz $ts = $job->handle->client;

	$ts->debug('data: ' . $job->arg) if $job->arg;
	my $data = eval { decode_json($job->arg) };

	unless ($data) {
		my $err = "Bad json data: $@";
		$ts->debug($err);
		return $job->permanent_failure($err);
	}

	$self->app->request_cache({});

	return $self->_work($job, $ts, $data);
}

1;
