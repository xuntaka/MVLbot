package App::Queue;

use Mojo::Base -base;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util qw(camelize decamelize);

use TheSchwartz;

has app => undef;
has config   => sub { shift->app->config };
has schwartz => sub { TheSchwartz->new(shift->_schwartz_opt) };

sub singleton { state $queue ||= shift->SUPER::new(@_) }

# site_snapshot($site // $site_id), ref $site = App::Model::Site
# Return "<job_handle_str>"
sub site_snapshot {
	my $self = shift;
	my $site = shift;

	my $site_id = ref $site ? $site->id : $site || 0;

	$self->_create_job(
		'snapshot' => $site_id,
		'uniqkey'  => "site_snapshot:$site_id",
		'site_id'  => $site_id,
		@_,
	);
}

# project_snapshot($project // $project_id), ref $project = App::Model::Project
# Return "<job_handle_str>"
sub project_snapshot {
	my $self    = shift;
	my $project = shift;

	my $project_id = ref $project ? $project->id : $project || 0;

	$self->_create_job(
		'snapshot'   => $project_id,
		'uniqkey'    => "project_snapshot:$project_id",
		'project_id' => $project_id,
		@_,
	);
}

# article_snapshot($article // $article_id), ref $article = App::Model::Article
# Return "<job_handle_str>"
sub article_snapshot {
	my $self       = shift;
	my $article    = shift;
	my $article_id = ref $article ? $article->id : $article;

	$self->_create_job('snapshot-article' => $article_id, @_);
}

sub project_kw_positions_update {
	my $self    = shift;
	my $project = shift;

	my $project_id = ref $project ? $project->id : $project || 0;

	$self->_create_job('position' => $project_id,
		'project_id' => $project_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub project_utm_check {
	my $self    = shift;
	my $project = shift;

	my $project_id   = ref $project ? $project->id : $project || 0;

	$self->_create_job('project-utm_check' => $project_id,
		'project_id' => $project_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub project_vk_ban_check {
	my $self    = shift;
	my $project = shift;

	my $project_id   = ref $project ? $project->id : $project || 0;

	$self->_create_job('project-vk_ban_check' => $project_id,
		'project_id' => $project_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub kw_budget_update {
	my $self = shift;
	my $kw   = shift;

	my $kw_id = ref $kw ? $kw->id : $kw || 0;

	$self->_create_job('keyword-budget' => $kw_id,
		'kw_id' => $kw_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub kw_positions_update {
	my $self = shift;
	my $kw   = shift;

	my $kw_id = ref $kw ? $kw->id : $kw || 0;

	$self->_create_job('keyword-position' => $kw_id,
		'kw_id' => $kw_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub kw_relevant {
	my $self = shift;
	my $kw   = shift;

	my $kw_id = ref $kw ? $kw->id : $kw || 0;

	$self->_create_job('keyword-relevant' => $kw_id,
		'kw_id' => $kw_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub kw_wordstat {
	my $self = shift;
	my $kw   = shift;

	my $kw_id = ref $kw ? $kw->id : $kw || 0;

	$self->_create_job('keyword-wordstat' => $kw_id,
		'kw_id' => $kw_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub site_solomono {
	my $self = shift;
	my $site = shift;

	my $site_id = ref $site ? $site->id : $site || 0;

	$self->_create_job('solomono' => $site_id,
		'site_id' => $site_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub site_phrases {
	my $self = shift;
	my $site = shift;

	my $site_id = ref $site ? $site->id : $site || 0;

	$self->_create_job('phrases' => $site_id,
		'site_id' => $site_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub check_article_index_go {
	my $self    = shift;
	my $article = shift;

	my $article_id = ref $article ? $article->id : $article || 0;

	$self->_create_job('article-check-index-google' => $article_id,
		'article_id' => $article_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub check_article_index_ya {
	my $self    = shift;
	my $article = shift;

	my $article_id = ref $article ? $article->id : $article || 0;

	$self->_create_job('article-check-index-yandex' => $article_id,
		'article_id' => $article_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub check_site_articles {
	my $self = shift;
	my $site = shift;

	my $site_id = ref $site ? $site->id : $site || 0;

	$self->_create_job('article-check' => $site_id,
		'site_id' => $site_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub check_site_social_articles {
	my $self = shift;
	my $site = shift;

	my $site_id = ref $site ? $site->id : $site || 0;

	$self->_create_job('article-social-check' => $site_id,
		'site_id' => $site_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub main_link_check {
	my $self    = shift;
	my $article = shift;

	my $article_id = ref $article ? $article->id : $article || 0;

	$self->_create_job('article-main_link_check' => $article_id,
		'article_id' => $article_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub site_social_vk_group_members {
	my $self = shift;
	my $site = shift;

	my $site_id = ref $site ? $site->id : $site || 0;

	$self->_create_job('site-social-vk_group_members' => $site_id,
		'site_id' => $site_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub site_social_params_update {
	my $self = shift;
	my $site = shift;

	my $site_id = ref $site ? $site->id : $site || 0;

	$self->_create_job('site-social_params_update' => $site_id,
		'site_id' => $site_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub social_stat_update {
	my $self    = shift;
	my $project = shift;

	my $project_id   = ref $project ? $project->id : $project || 0;

	$self->_create_job('project-social_stat_update' => $project_id,
		'project_id' => $project_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub site_rating_recount {
	my $self = shift;
	my $site = shift;

	my $site_id = ref $site ? $site->id : $site || 0;

	$self->_create_job('site-rating_recount' => $site_id,
		'site_id' => $site_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub site_check_approve {
	my $self = shift;
	my $site = shift;

	my $site_id = ref $site ? $site->id : $site || 0;

	$self->_create_job('site-check_approve' => $site_id,
		'site_id' => $site_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub get_category {
	my $self   = shift;
	my $object = shift;

	my $object_id = ref $object ? $object->id : $object || 0;

	$self->_create_job('get_category' => $object_id,
		'object_id' => $object_id, # для совместимости, удалить в марте 2016
		'type'      => {
			'App::Model::Site'    => 'site',
			'App::Model::Project' => 'project',
		}->{ref $object},
		@_,
	);
}

sub pagetester {
	my $self    = shift;
	my $article = shift;

	my $article_id = ref $article ? $article->id : $article || 0;

	$self->_create_job('page_tester' => $article_id,
		'article_id' => $article_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

sub metrika_clicks {
	my $self   = shift;
	my $object = shift;
	my %args   = @_;

	my $object_id = ref $object ? $object->id : $object || 0;
	my $type      = $args{'type'};

	$self->_create_job('get_metrika_clicks' => $object_id,
		'object_id' => $object_id, # для совместимости, удалить в марте 2016
		'coalesce'  => $type . $object_id,
		'uniqkey'   => 'get_metrika_clicks_' . $type . $object_id,
		%args,
	);
}

# mailer( $user, { notify_type => 'news', subject => $subject, text => $text, html => $html }
# Return "<job_handle_str>"
sub mailer {
	my ($self, $user, %args) = @_;
	
	my $user_id   = ref $user ? $user->id : 0;
	delete $args{'users'};

	my $massmail_id =
		$args{'notify_type'} && $args{'notify_type'} eq 'massmail'
		? $args{'massmail_id'}
		: undef;

	$self->_create_job('mailer' => $user_id,
		'user_id' => $user_id, # для совместимости, удалить в марте 2016
		'uniqkey' => $massmail_id
			? "massmail_$massmail_id:$user_id"
			: "mailer:$user_id",
		%args,
	);
}

sub mass_mail_create {
	my $self     = shift;
	my $massmail = shift;

	my $massmail_id = ref $massmail ? $massmail->id : $massmail;

	$self->_create_job('massmail-create' => $massmail_id,
		'massmail_id' => $massmail_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

# Отправляем Push сообщение в браузер
sub send_push {
	my $self = shift;
	my $user = shift;

	my $user_id = ref $user ? $user->id : 0;

	$self->_create_job('notifications-web_push' => $user_id,
		'user_id' => $user_id, # для совместимости, удалить в марте 2016
		@_,
	);
}

# Используется в App::Queue::Worker
sub get_schwartz {
	my $self = shift;
	return $self->{'_schwartz'} ||= TheSchwartz->new($self->_schwartz_opt);
}

sub _create_job {
	my ($self, $func, $id, %args) = @_;

	$id ||= 0;

	for ($func) {
		s{^\s+}{};
		s{\s+$}{};
		s{^(?:app[:-]+)?queue[:-]+}{}ix;
		s{^::}{};
		$_ = decamelize($_);
	}

	$args{'id'} = $id;

	my $run_after = delete $args{'run_after'};
	my $delay     = delete $args{'delay'    };
	my $uniqkey   = delete $args{'uniqkey'  };
	my $coalesce  = delete $args{'coalesce' };

	$run_after = time() + $delay if $delay;

	my $job = TheSchwartz::Job->new(
		'funcname' => 'App::Queue::' . camelize($func),
		'arg'      => encode_json(\%args),
		'coalesce' => $coalesce || $id,
		'uniqkey'  => $uniqkey  || "$func:$id",
		($run_after ? ('run_after' => $run_after) : ()),
	);

	my $jobhandle = eval { local $SIG{__DIE__}; $self->schwartz->insert($job) };
	return $jobhandle && $jobhandle->as_string;
}

sub _schwartz_opt {
	my $self = shift;
	my $ts_opts = $self->config->{'theschwartz'};
	foreach my $db (@{$ts_opts->{'databases'}}) {
		next if exists $db->{'dsn'};
		$db->{'dsn'}  = "DBI:mysql:database=$db->{'name'}";
		$db->{'dsn'} .= ";host=$db->{'host'}" if $db->{'host'};
		$db->{'dsn'} .= ";port=$db->{'port'}" if $db->{'port'};
		$db->{'dsn'} .= $db->{'dsn_params'} if $db->{'dsn_params'};
	}

	return %$ts_opts;
}

1;
