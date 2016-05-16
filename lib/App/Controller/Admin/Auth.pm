package App::Controller::Admin::Auth;

use Mojo::Base 'App::Controller::Admin';

sub login {
  my $self = shift;

  return $self->redirect_to('main') if $self->user;

  if (!$self->is_https && $self->config->{'https'}->{'force_admin'}) {
    return $self->redirect_to_https;
  }

  my $errors = $self->errors;
  my ($login, $password, $remember) = map { $self->param($_) } qw(login password remember);

  if ($login || $password) {
    my $user = $self->M('Admin::User')->search('login' => $login)->first;

    $errors->add('password' => 'Введите пароль'        ) if $password !~ /\S/;
    $errors->add('login'    => 'Пользователь не найден') unless $user;
    $errors->add('login'    => 'Пользователь удален'   )
      if $user && $user->is_deleted;

    if ($user && !$errors->count) {
      if (!$errors->count && $user && $user->check_password($password)) {
        $self->authenticate_user($user, 'remember' => $remember);

        return $self->redirect_to('admin-main');
      }
    }

    $errors->add('login' => 'Ошибка авторизации');
  }

  $self->render;
}

sub logout {
  my $self = shift;
  $self->deauthenticate_user;
  return $self->redirect_to('admin-main');
}

sub logged { # bridge
  my $self = shift;

  if (!$self->is_https && $self->config->{'https'}->{'force_admin'}) {
    $self->redirect_to_https;
    return 0;
  }

  if ($self->user) {
    $self->L('Main')->main;
    return 1;
  }

  $self->redirect_to('admin-login');
  return 0;
}

sub permissions { # bridge
  my $self = shift;

  my $permissions = $self->stash('user.permissions');
  if ($permissions && @$permissions) {
    return 1 if $self->user->allow(@$permissions);

    $self->forbidden;
    return 0;
  }

  return 1;
}

1;
