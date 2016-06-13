package App::Controller::Admin::Houses;

use Mojo::Base 'App::Controller::Admin';

sub list {
  my $self = shift;
  my $pid  = $self->param('pid') || 0;

  my $houses = $self->M('House')
    ->search('pid'        => $pid)
    ->search('is_deleted' => 0)
    ->all;

  $self->render(
    'list' => $houses,
  );
}

sub edit {
  my $self = shift;

  my $errors = $self->errors;

  my $house = $self->M('House')->get($self->param('id'))
    or return $self->not_found;

  if ($house && $self->is_post) {
    foreach (qw{title}) {
      my $p = $self->param($_) or next;
      $house->$_($p);
    }

    $errors->add('title'  => 'Имя не может быть пустым') if $house->title !~ /\S/;
    $errors->add('type'   => 'Необходимо указать тип'  ) if $house->type  !~ /\S/;

    unless ($errors->count) {
      $house->store;
      $self->message_success('Изменения успешно сохранены');
      return $self->redirect_to('admin-house-edit', 'id' => $house->id);
    }
  }

  $self->render(
    'house' => $house,
  );
}

sub add {
  my $self = shift;

  my $errors = $self->errors;
  my ($title, $type) =
    map { $self->param($_) } qw(title type);

  if ($self->is_post) {
    $errors->add('title'  => 'Имя не может быть пустым') if $title  !~ /\S/;
    $errors->add('type'   => 'Необходимо указать type'  ) if $type   !~ /\S/;

    unless ($errors->count) {
      warn 'before house store';
      my $house = $self->M('House')->new(
        'title' => $title,
        'type'  => $type,
      )->store;
      warn 'after house store';

      $self->message_success('Новый ' . $house->type . ' добавлен');

      return $self->redirect_to('admin-houses');
    }

    $errors->add('form' => 'Ошибка добавления');
  }

  $self->render;
}

sub delete {
  my $self = shift;

  my $house = $self->M('House')->get($self->param('id'))
    or return $self->not_found;

  $house
    ->is_deleted(1)
    ->store;

  $self->message_success($house->type . ' ' . $house->title . ' удалён');

  $self->redirect_to('admin-houses');
}

1;
