package App::Controller::Auth;

use Mojo::Base 'App::Controller';

sub logged { # bridge
	my $self = shift;
	my $token = $self->config->{'telegram'}->{'auth_token'};

	if ($token eq $self->param('token')) {
		return 1;
	}

	return 0;
}

1;
