package App::Router::Admin;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
	my ($self, $app) = @_;

	# Router
	my $r = $app->routes;

	$r->route('/admin/login' )->to('admin-auth#login',  'layout' => 'admin')->name('admin-login' );
	$r->route('/admin/logout')->to('admin-auth#logout', 'layout' => 'admin')->name('admin-logout');

	for ($r->under('/admin')->to('admin-auth#logged', 'layout' => 'admin')) {
		$_->route('/'                )->to('admin-main#main'       )->name('admin-main'            );

		$_->route('/profile'         )->to('admin-profile#view'    )->name('admin-profile'         );
		$_->route('/profile/password')->to('admin-profile#password')->name('admin-profile-password');
		$_->route('/profile/email'   )->to('admin-profile#email'   )->name('admin-profile-email'   );


		# Управление админами
		$_->route('/admins'               )->to('admin-admins#list'  )->name('admin-admins'      );
		$_->route('/admin/add'            )->to('admin-admins#add'   )->name('admin-admin-add'   );
		$_->route('/admin/:id'            )->to('admin-admins#edit'  )->name('admin-admin-edit'  );
		$_->route('/admin/delete/:id'     )->to('admin-admins#delete')->name('admin-admin-delete');
		#~ $_->route('/admin/log/:user_id'   )->to('admin-admins#log'   )->name('admin-admin-log'    );

		# Управление пользователями
		$_->route('/users'                            )->to('admin-users#list'              )->name('admin-users'                  );
		$_->route('/user/add'                         )->to('admin-users#add'               )->name('admin-user-add'               );
		$_->route('/user/:id'                         )->to('admin-users#edit'              )->name('admin-user-edit'              );
		$_->route('/user/delete/:id'                  )->to('admin-users#delete'            )->name('admin-user-delete'            );

		# Управление чатами
		$_->route('/chats'               )->to('admin-chats#list'  )->name('admin-chats'      );
		$_->route('/chat/add'            )->to('admin-chats#add'   )->name('admin-chat-add'   );
		$_->route('/chat/:id'            )->to('admin-chats#edit'  )->name('admin-chat-edit'  );
		$_->route('/chat/delete/:id'     )->to('admin-chats#delete')->name('admin-chat-delete');

		# Управление домом
		$_->route('/houses/:pid',      'pid' => qr/\d+/)->to('admin-houses#list', 'pid' => 0)->name('admin-houses'      );
		$_->route('/house/add'                         )->to('admin-houses#add'             )->name('admin-house-add'   );
		$_->route('/house/:id',        'id'  => qr/\d+/)->to('admin-houses#edit'            )->name('admin-house-edit'  );
		$_->route('/house/delete/:id', 'id'  => qr/\d+/)->to('admin-houses#delete'          )->name('admin-house-delete');
	}
}

1;
