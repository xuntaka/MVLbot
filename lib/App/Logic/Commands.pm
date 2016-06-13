package App::Logic::Commands;

use Mojo::Base 'App::Logic';

use Mojo::JSON qw(to_json);

sub chats {
  my $self = shift;

  return {
    'method'                   => 'sendMessage',
    'parse_mode'               => 'HTML',
    'disable_web_page_preview' => 1,
    'text'                     => $self->c->render_to_string(
      'telegram/chats',
      'format' => 'html',
      'chats'  => $self->M('Chat')
                    ->search('is_deleted' => 0)
                    ->all,
    ),
  };
}

sub help {
  my $self = shift;

  return {
    'method'                   => 'sendMessage',
    'parse_mode'               => 'HTML',
    'disable_web_page_preview' => 1,
    'text'                     => $self->c->render_to_string(
      'telegram/help',
      'format' => 'html',
    ),
  };
}

sub start {
  my $self = shift;
  my $key  = shift;

  my $user = $self->user;

  # return {
  #   'method' => 'sendMessage',
  #   'text'   => 'Привет, ' . ($user ? $user->name : 'Незнакомец') . '!',
  # };

  return {
    'method'                   => 'sendMessage',
    'parse_mode'               => 'HTML',
    'disable_web_page_preview' => 1,
    'text'                     => $self->c->render_to_string(
      'telegram/start',
      'format' => 'html',
    ),
  };

}

sub acquaint {
  my $self = shift;
  my $pid = shift || 0;

  my $user = $self->user;

  warn $user;
  warn $user->id;

  my $parent = $self->M('House')->get($pid);

  warn $parent;
  warn $parent->id;
  warn $parent->type;

  if ($parent && $parent->type eq 'flat') { # номер квартиры, запоминаем
    $user
      ->data('flat_id' => $parent->id)
      ->store;

    return {
      'method'                   => 'sendMessage',
      'parse_mode'               => 'HTML',
      'disable_web_page_preview' => 1,
      'text'                     => $self->c->render_to_string(
        'telegram/acquaint',
        'format' => 'html',
        'parent' => $parent,
      ),
    };
  }

  my $per_line = 4;
  my $kb_data = [];

  $per_line = 1 unless $parent; # Дома показываем по одному на строку

  my $houses = $self->M('House')
    ->search('pid' => $pid)
    ->all;

  while (@$houses) {
    push @$kb_data, [
      map {+{'text' => $_->title, 'callback_data' => '/acquaint:' . $_->id}}
      splice @$houses, 0, $per_line
    ];
  }

  return {
    'method'                   => 'sendMessage',
    'parse_mode'               => 'HTML',
    'disable_web_page_preview' => 1,
    'text'                     => $self->c->render_to_string(
      'telegram/acquaint',
      'format' => 'html',
      'parent' => $parent,
    ),
    'reply_markup' => to_json({
      'inline_keyboard' => $kb_data,
    }),
  };

}

1;
