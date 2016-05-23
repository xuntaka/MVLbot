package App::Logic::Commands;

use Mojo::Base 'App::Logic';

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

1;
