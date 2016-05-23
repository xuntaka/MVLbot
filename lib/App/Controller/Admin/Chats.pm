package App::Controller::Admin::Chats;

use Mojo::Base 'App::Controller::Admin';

sub list {
  my $self = shift;

  my $chats = $self->M('Chat')
    ->search('is_deleted' => 0)
    ->order_by('id', 'desc')
    ->all;

  $self->render(
    'list' => $chats,
  );
}

sub edit {
  my $self = shift;

  my $errors = $self->errors;

  my $chat = $self->M('Chat')->get($self->param('id'))
    or return $self->not_found;

  if ($chat && $self->is_post) {
    foreach (qw{name link}) {
      my $p = $self->param($_) or next;
      $chat->$_($p);
    }

    $errors->add('name'  => 'Имя не может быть пустым') if $chat->name  !~ /\S/;
    $errors->add('link'   => 'Необходимо указать link'  ) if $chat->link   !~ /\S/;

    unless ($errors->count) {
      $chat->store;
      $self->message_success('Изменения успешно сохранены');
      return $self->redirect_to('admin-chat-edit', 'id' => $chat->id);
    }
  }

  $self->render(
    'chat' => $chat,
  );
}

sub add {
  my $self = shift;

  my $errors = $self->errors;
  my ($name, $link) =
    map { $self->param($_) } qw(name link);

  if ($self->is_post) {
    $errors->add('name'  => 'Имя не может быть пустым') if $name  !~ /\S/;
    $errors->add('link'   => 'Необходимо указать link'  ) if $link   !~ /\S/;

    unless ($errors->count) {
      warn 'before chat store';
      my $chat = $self->M('Chat')->new(
        'name' => $name,
        'link'  => $link,
      )->store;
      warn 'after chat store';

      $self->message_success('Новый чат добавлен');

      return $self->redirect_to('admin-chats');
    }

    $errors->add('form' => 'Ошибка добавления');
  }

  $self->render;
}

sub delete {
  my $self = shift;

  my $chat = $self->M('Chat')->get($self->param('id'))
    or return $self->not_found;

  $chat
    ->is_deleted(1)
    ->store;

  $self->message_success('Чат ' . $chat->name . ' удалён');

  $self->redirect_to('admin-chats');
}

1;
