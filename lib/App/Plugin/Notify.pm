package App::Plugin::Notify;

use Mojo::Base 'Mojolicious::Plugin';
# use App::Model::Api::Sms;

use constant TYPES2TMPL => {

};

sub register {
	my ($self, $app) = @_;
	
	# $app->notify($type, $user, ...)
	# Возвращает undef или [$res_email, $res_sms]. Возможно что-то одно
	$app->helper(notify => sub {
		my ($self, $type, $user, %p) = @_;
		return unless $type && $user;
		my $config = $self->app->config;
		
		my $tmpl = TYPES2TMPL->{$type};
		unless ($tmpl) {
			warn "Notifications type $type not found";
			return;
		}

		$p{to_webmaster} ||= 1 if $type =~ /^webmaster/;
		$p{headers} ||= [
			{'Return-Path'	=> '<'. $config->{mail}{reply_to}. '>'},
		];
		if ($type eq 'news' || $type eq 'massmail') {
			push @{$p{headers}},
				{ 'List-Id' => '<news.'.$config->{server}{host}.'>' },
				{ Precedence => 'bulk' }; # Массовая рассылка одинаковых текстов, а пакеты - разных.

		} elsif ($type =~ /packages_offer/) {
			push @{$p{headers}},
				{ 'List-Id' => '<packages.'.$config->{server}{host}.'>' }, # Нужно для отписки в gmail
		}

		if ($user->isa('App::Model::User')) { # Обычный пользователь
			push @{$p{headers}}, {'List-Unsubscribe' => '<'.$self->url_for_full('email-unsubscribe', user_id => $user->id, code => $user->mail_code, type => $type)->scheme('https').'>'};
		}
		my @results;
		
		my $email = $config->{mail}{to} || $p{_to_email} || $user->email;
		if ($email && ($p{'force'} || $user->email_confirm && $user->allow_email_type($type))) {
			my $res = eval { $self->mail(
				notify_type	=> $type,
				template	=> $tmpl,
				encoding	=> '8bit',
				user		=> $user,
				to			=> $email,
				($type !~ /^(?:news|massmail|.*packages_offer.*)$/ ?
					(bcc	=> $config->{mail}{bcc}) : ()), # Скрытая копия
				($config->{mail}{_types}{$type} ? %{$config->{mail}{_types}{$type}} : ()),
				%p,
			)};
			$self->app->log->error("notify: $@") if $@;
			
			push @results, $res if $res;
		}
		
		my $phone = $p{_to_phone} || $user->phone;
		if ($phone && $user->allow_sms_type($type)) {
			my $text = $self->render_to_string($tmpl,
				notify_type	=> $type,
				user		=> $user,
				format		=> 'sms',
				%p,
				);
			if ($text) {
				$text =~ s/^\s+//s;
				$text =~ s/\s+$//s;
				$text =~ s/ {2,}/ /g;
			}
			warn "SMS: '$text' => '$phone'\n";
			if ($text) {
				push @results, $self->M('Api::Sms')->new(
					user_id		=> $user->id,
					notify_type	=> $type,
					phone		=> $phone,
					mes			=> $text,
				)->store;
			}
		}

		if ($user->allow_push_type($type)) {
			my $text = $self->render_to_string($tmpl,
				notify_type	=> $type,
				user		=> $user,
				format		=> 'push',
				%p,
				);
			if ($text) {
				$text =~ s/^\s+//s;
				$text =~ s/\s+$//s;
				$text =~ s/ {2,}/ /g;
			}
			if ($text) {
				#warn "PUSH: '$text' => '". $user->id. "'\n";

				$self->M('Push::Message')->new(
					user_id => $user->id,
					message	=> $text,
					title   => $self->stash('title'),
					url     => $self->stash('url'),
					image   => $self->stash('image'),
				)->store;

				push @results, $self->queue->send_push($user);
			}
		}
		return @results ? \@results : undef;
	});

	# Сообщаем оптимизатору/вебмастеру о новом статусе статьи
	$app->helper(notify_article => sub {
		my ($self, $article, %p) = @_;

		my $status	= $article->status;
		my $site	= $article->site;
		my $project	= $article->project;
		if (!$site || !$project) {
			warn "Site or project not found for article#".$article->id;
			return;
		}

		my @notify;
		if ($status eq 'new') {
			push @notify, ['webmaster_article_confirm'		=> $site->owner];
		} elsif ($status eq 'wait') {
			push @notify, ['webmaster_article_ready'		=> $site->owner];
		} elsif ($status eq 'cancel') {
			push @notify, ['optimisator_article_cancel'		=> $project->owner];
			push @notify, ['webmaster_article_cancel'		=> $site->owner];
		} elsif ($status eq 'replace') {
			push @notify, ['optimisator_article_replace'	=> $project->owner];
			push @notify, ['webmaster_article_replace'		=> $site->owner];
			$p{'cause'} = '' unless $p{'cause'};
		} elsif ($status eq 'optimisator_delete') {
			push @notify, ['webmaster_article_delete_links'	=> $site->owner];
		}

		foreach (@notify) {
			$self->notify(@$_,
				'article'  => $article,
				'site'     => $site,
				'project'  => $project,
				%p,
			);
		}
		return scalar(@notify);
	});
}

1;
