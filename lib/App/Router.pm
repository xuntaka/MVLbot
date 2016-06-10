package App::Router;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
	my ($self, $app) = @_;

	# Router
	my $r = $app->routes;
		 $r->namespaces(['App::Controller']);

	$r->route('/api/telegram/hook/:token')->to('telegram#webhook')->name('telegram-webhook');
}

1;
