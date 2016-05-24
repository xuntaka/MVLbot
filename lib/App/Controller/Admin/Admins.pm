package App::Controller::Admin::Admins;

use Mojo::Base 'App::Controller::Admin';

use App::Util qw[is_email];

sub list {
  my $self = shift;

  my $users = $self->M('Admin::User')
    ->search('is_deleted' => 0)
    ->order_by('id', 'desc')
    ->all;

  $self->render(
    'list' => $users,
  );
}

sub edit {
  my $self = shift;

  my $errors = $self->errors;

  my $user = $self->M('Admin::User')->get($self->param('id'))
    or return $self->not_found;

  if ($user && $self->is_post) {
    foreach (qw{name email password}) {
      my $p = $self->param($_) or next;
      $user->$_($p);
    }

    $user->data('permissions' => {
      map  { $_ => 1 }
      grep { $self->config->{'permissions'}->{$_} }
      map  { @$_ }
      $self->every_param('permissions')
    });

    $errors->add('name'  => 'Имя не может быть пустым') if $user->name  !~ /\S/;
    $errors->add('email' => 'Необходимо указать email') if $user->email !~ /\S/;
    $errors->add('email' => 'Не корректный email'     )
      unless is_email($user->email);

    unless ($errors->count) {
      $user->store;
      $self->message_success('Изменения успешно сохранены');
      return $self->redirect_to('admin-admin-edit', 'id' => $user->id);
    }
  }

  $self->render(
    'user' => $user,
  );
}

sub add {
  my $self = shift;

  my $errors = $self->errors;
  my ($login, $name, $email, $password) =
    map { $self->param($_) } qw(login name email password);

  if ($self->is_post) {
    $errors->add('login'    => 'Логин не может быть пустым'     ) if $login !~ /\S/;
    $errors->add('name'     => 'Имя не может быть пустым'       ) if $name  !~ /\S/;
    $errors->add('email'    => 'Необходимо указать email'       ) if $email !~ /\S/;
    $errors->add('email'    => 'Не корректный email'            ) unless App::Util::is_email($email);
    $errors->add('email'    => 'Такой email уже зарегистрирован') if $self->M('Admin::User')->search('email' => $email)->first;
    $errors->add('password' => 'Пароль не может быть пустым'    ) if $password !~ /\S/;

    unless ($errors->count) {
      my $user = $self->M('Admin::User')->new(
        'login'       => $login,
        'name'        => $name,
        'email'       => $email,
        'password'    => $password,
        'permissions' => {
          map  { $_ => 1 }
          grep { $self->config->{'permissions'}->{$_} }
          map  { @$_ }
          $self->every_param('permissions')
        }
      )->store;

      $self->message_success('Новый пользователь добавлен');

      return $self->redirect_to('admin-admins');
    }

    $errors->add('form' => 'Ошибка регистрации');
  }

  $self->render;
}

sub delete {
  my $self = shift;

  my $user = $self->M('Admin::User')->get($self->param('id'))
    or return $self->not_found;

  $user->is_deleted(1);
  $user->store;

  $self->message_success('Админ ' . $user->login . ' заблокирован');

  $self->redirect_to('admin-admins');
}

1;
