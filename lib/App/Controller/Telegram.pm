package App::Controller::Telegram;

use Mojo::Base 'App::Controller';

use Mojo::JSON qw(to_json);

sub set_user {
	my ($self, $chat_id) = @_;
	my $uid = $self->app->cache->get("telegram_chat:". $chat_id) or return;
	$self->user_id($uid);
	my $user = $self->M('User')->get($uid);
	return $self->user($user);
}

sub webhook {
	my $self = shift;

	my $json = $self->req->json;

	$self->app->log->debug($self->dumper($json));

#  {
#   "message" => {
#     "chat" => {
#       "first_name" => "Egor",
#       "id" => 20987610,
#       "last_name" => "Baibara",
#       "type" => "private",
#       "username" => "xuntaka"
#     },
#     "date" => "1462827362",
#     "entities" => [
#       {
#         "length" => 6,
#         "offset" => 0,
#         "type" => "bot_command"
#       }
#     ],
#     "from" => {
#       "first_name" => "Egor",
#       "id" => 20987610,
#       "last_name" => "Baibara",
#       "username" => "xuntaka"
#     },
#     "message_id" => 3,
#     "text" => "/start"
#   },
#   "update_id" => 884437478
# }


	my $message = $json->{'message'} || {};
	my $text = $message->{'text'};
	# $self->stash('telegram_request' => $json);
	# $self->stash('chat_id' => $message->{chat}{id});
	# $self->set_user($message->{chat}{id});

	my $res = {};

	if ($text =~ m{^/([a-z0-9]+)(?:@\S+)?\s*(.*)?$}) {
		my ($cmd, $params) = ($1, $2);
		my $method = "cmd_$cmd";
		if ($self->can($method)) {
			$res = $self->$method(split /\s+/, $params);
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

sub cmd_start {
	my ($self, $key) = @_;

	if ($key) {
		# my $uid = $self->app->cache->get("telegram_subscribe_key:$key");
		# if ($uid) {
		# 	my $chat_id = $self->stash('chat_id');
		# 	$self->app->cache->set("telegram_chat:$chat_id" => $uid);
		# 	$self->user_id($uid);
		# }
	}

	my $user = undef; #$self->user;

	return {
		'method' => 'sendMessage',
		'text'   => 'Привет, ' . ($user ? $user->name : 'Незнакомец') . '!',
	};
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
