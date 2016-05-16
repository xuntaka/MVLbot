#!/usr/bin/perl
use v5.18;
use utf8;

BEGIN { require FindBin; require "$FindBin::Bin/../init.pl"; }
BEGIN { $ENV{'MOJO_USERAGENT_DEBUG'} = 1; }

my $config = app->config->{'telegram'};

# print Data::Dumper::Dumper(
# 	app->ua->post(
# 		"https://api.telegram.org/bot". $config->{'token'}. "/getMe"
# 	)->res->json
# );

print Data::Dumper::Dumper(
	app->ua->post(
		"https://api.telegram.org/bot" . $config->{'token'} . "/setWebhook",
		'form' => {
			'url' => app->config->{'server'}{'https'} .
			         app->url_for('telegram-webhook'),
		}
	)->res->json
);
