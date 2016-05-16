package App::Controller::Admin::Profile;

use Mojo::Base 'App::Controller::Admin';

sub view {
  my $self = shift;

  my $user = $self->user;

  if ($self->is_post) {
    $user->name($self->param('name'));
    $user->store;

    $self->message_success('Данные успешно сохранены');
    $self->redirect_to('admin-profile');
  }

  $self->render;
}

sub password {
  my $self = shift;

  my $user   = $self->user;
  my $errors = $self->errors;

  if ($self->is_post) {
    my ($password, $new_password, $new_password_check) = map { $self->param($_) } qw(password new_password new_password_check);

    $errors->add('password'           => 'Необходимо ввести текущий пароль') if $password !~ /\S/;
    $errors->add('password'           => 'Пароль введен не верно'          ) unless $user->check_password($password);
    $errors->add('new_password'       => 'Пароль не может быть пустым'     ) if $new_password !~ /\S/;
    $errors->add('new_password_check' => 'Пароль надо ввести дважды'       ) if $new_password_check !~ /\S/;
    $errors->add('new_password_check' => 'Пароли должны совпадать'         ) if $new_password ne $new_password_check;

    unless ($errors->count) {
      $user->password($new_password);
      $user->store;

      $self->message_success('Пароль успешно изменен');
      $self->redirect_to('admin-profile');
    }
  }

  $self->render;
}

sub email {
  my $self = shift;

  my $user   = $self->user;
  my $errors = $self->errors;

  if ($self->is_post) {
    my ($email, $password) = map { $self->param($_) } qw(email password);

    $errors->add('password' => 'Необходимо ввести текущий пароль') if $password !~ /\S/;
    $errors->add('password' => 'Пароль введен не верно'          ) unless $user->check_password($password);
    $errors->add('email'    => 'Необходимо указать Email'        ) if $email !~ /\S/;
    $errors->add('email'    => 'Не корректный email'             ) unless App::Util::is_email($email);

    unless ($errors->count) {
      $user->email($email);
      $user->store;

      $self->message_success('Email успешно изменен');
      $self->redirect_to('admin-profile');
    }
  }

  $self->render;
}

1;
