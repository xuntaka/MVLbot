package App::Controller::Auth;

use Mojo::Base 'App::Controller';

sub logged { # bridge
	my $self = shift;
	my $token = $self->config->{'telegram'}->{'auth_token'};

	if ($token eq $self->param('token')) {
		my $json = $self->req->json;

		my $message = $json->{'message'} || {};
		$self->stash('request' => $json);
		$self->stash('chat_id' => $message->{'chat'}->{'id'});

		my $user =
			$self->M('User')->search('uid' => $message->{'from'}->{'id'})->first ||
			$self->M('User')->new(
				'uid'  => $message->{'from'}->{'id'},
				'name' => $message->{'from'}->{'first_name'} . ' ' .
				          $message->{'from'}->{'last_name'},
				'data' => $message,
			)->store;

		$self->stash('user'     => $user     );
		$self->stash('user_id'  => $user->id );
		$self->stash('user_uid' => $user->uid);

		return 1;
	}

	return 0;
}

1;
