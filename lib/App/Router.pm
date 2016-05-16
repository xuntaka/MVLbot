package App::Router;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
	my ($self, $app) = @_;

	# Router
	my $r = $app->routes;
		 $r->namespaces(['App::Controller']);

	# $r->route('/')->to('main#main')->name('main');
	for ($r->under->to('index#logged')) {
		$_->route('/'         )->to('index#index',     'layout' => 'index')->name('main');
		$_->route('/webmaster')->to('index#webmaster', 'layout' => 'index')->name('main-webmaster');
	}

	$r->route('/login' )->to('auth#login' )->name('login' );
	$r->route('/logout')->to('auth#logout')->name('logout');

	for ($r->under->to('auth#logged')) {
		$r->route('/api/telegram/hook/:token')->to('telegram#webhook')->name('telegram-webhook');
	}

}

1;
