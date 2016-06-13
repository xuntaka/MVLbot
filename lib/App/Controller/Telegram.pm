package App::Controller::Telegram;

use Mojo::Base 'App::Controller';

use Mojo::JSON qw(to_json);

sub webhook {
	my $self = shift;

	my $token = $self->config->{'telegram'}->{'hook_token'};

	return $self->forbidden
		unless $token eq $self->param('token');

	my $json = $self->req->json
		or return $self->forbidden;

	$self->stash('request' => $json);

	return $self->process_message
		if $json->{'message'};

	return $self->process_callback
		if $json->{'callback_query'};

	warn $self->dumper($json);

	$self->render('json' => {
		'method' => 'sendMessage',
		'text'   => 'Хм. Я в замешательстве',
	});
}

sub process_message {
	my $self = shift;

	my $json = $self->stash('request');

	my $message = $json->{'message'} || {};

	my $text = $message->{'text'};
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

	my $res = {};

	if ($text =~ m{^/([a-z0-9]+)(?:@\S+)?\s*(.*)?$}) {
		my $commands = $self->L('Commands')
			->params(
				'message' => $message,
				'chat_id' => $message->{'chat'}->{'id'},
			);

		my ($cmd, $params) = ($1, $2);
		if ($commands->can($cmd)) {
			$res = $commands->$cmd(split /\s+/, $params);
		} else {
			$res = {
				'method' => 'sendMessage',
				'text'   => 'Команда не найдена',
			};
		}
	}

	if ($res->{'method'}) {
		$res->{'chat_id'} = $message->{'chat'}->{'id'},
	}

	warn $self->dumper($json, $res);

	$self->render('json' => $res);
}

sub process_callback {
	my $self = shift;

	my $json = $self->stash('request');

	my $callback = $json->{'callback_query'} || {};

	my $message = $callback->{'message'} || {};

	my $text = $message->{'text'};
	$self->stash('chat_id' => $message->{'chat'}->{'id'});

	my $user =
		$self->M('User')->search('uid' => $callback->{'from'}->{'id'})->first ||
		$self->M('User')->new(
			'uid'  => $callback->{'from'}->{'id'},
			'name' => $callback->{'from'}->{'first_name'} . ' ' .
			          $callback->{'from'}->{'last_name'},
			'data' => $callback,
		)->store;

warn $user;

	$self->stash('user'     => $user     );
	$self->stash('user_id'  => $user->id );
	$self->stash('user_uid' => $user->uid);

	my $res = {};

	my $data = $callback->{'data'};
	if ($data =~ m{^/([a-z0-9]+)(?::\s*(.*)?)?$}) {
		my $commands = $self->L('Commands')
			->params(
				'message' => $message,
				'chat_id' => $message->{'chat'}->{'id'},
			);

		my ($cmd, $params) = ($1, $2);
		if ($commands->can($cmd)) {
			$res = $commands->$cmd(split /\s+/, $params);
		} else {
			$res = {
				'method' => 'sendMessage',
				'text'   => 'Команда не найдена',
			};
		}
	}

	if ($res->{'method'}) {
		$res->{'chat_id'} = $message->{'chat'}->{'id'},
	}

	warn $self->dumper($json, $res);

	$self->render('json' => $res);
}

1;
