package App::Logic::Commands;

use Mojo::Base 'App::Logic';

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
