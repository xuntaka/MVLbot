package App::Controller::Telegram;

use Mojo::Base 'App::Controller';

use Mojo::JSON qw(to_json);

sub webhook {
	my $self = shift;

	my $json = $self->req->json or return $self->forbidden;
	my $message = $json->{'message'} || {};
	my $text = $message->{'text'};

	my $token = $self->config->{'telegram'}->{'hook_token'};

warn $token;
warn $self->param('token');


	if ($token ne $self->param('token')) {
		return $self->forbidden;
	}

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

	warn Data::Dumper::Dumper($json, $res);

	$self->render('json' => $res);
}

sub cmd_projects {
	my $self = shift;
	my $user = $self->user or return;

	my @projects = sort { $a->name cmp $b->name }
		@{$self->M('Project')
			->search('owner_id' => $user->id)
			->search('block_status' => {'<>' => 'deleted'})
			->all};

	my $res = {
		method => 'sendMessage',
		parse_mode => 'HTML',
		disable_web_page_preview => 1,
		text => $self->render_to_string("bots/telegram/projects", format => "html", projects => \@projects),
	};

	if (@projects > 0 && @projects < 17) {
		$res->{reply_markup} = $self->_keyboard([ map { $_->id } @projects ]);
	}

	return $res;
}

sub cmd_sites {
	my $self = shift;
	my $user = $self->user or return;

	my @sites = sort { $a->name cmp $b->name }
		@{$self->M('Site')->search({
			'owner_id'     => $user->id,
			'is_archived'  => 0,
			'status'       => {'<>' => 'nobody'},
		})->all};

	my $res = {
		method => 'sendMessage',
		parse_mode => 'HTML',
		disable_web_page_preview => 1,
		text => $self->render_to_string('bots/telegram/sites', format => 'html', sites => \@sites),
	};

	if (@sites > 0 && @sites < 17) {
		$res->{reply_markup} = $self->_keyboard([ map { $_->id } @sites ]);
	}

	return $res;
}

sub _keyboard {
	my ($self, $array, @params) = @_;
	return unless @$array;

	my $rows = int(sqrt(@$array));
	$rows = 1 if $rows < 1;
	$rows = 4 if $rows > 4;

	my @map;
	while (@$array) {
		push @map, [ splice @$array, 0, $rows ];
	}

	return to_json({
		keyboard => \@map,
		# resize_keyboard => 1,
		# one_time_keyboard => 1,
		# selective => 1,
		force_reply_keyboard => 1,
		@params
	});
}

1;
