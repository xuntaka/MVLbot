package App::Logic::Request;

use Mojo::Base 'App::Logic';

sub request {
  my $self = shift;
  my $method = shift;

  my $r = $self->ua->post(
    'https://api.telegram.org/bot' . $self->config->{'telegram'}->{'token'} . '/' . $method,
    'form' => { @_ }
  );

  # warn $self->app->dumper($r->req);

  $r->res->json
}

1;
