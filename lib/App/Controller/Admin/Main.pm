package App::Controller::Admin::Main;

use Mojo::Base 'App::Controller::Admin';
use Mojo::Loader qw[load_class];

sub main {
  my $self = shift;

  my $modules;
  foreach my $m (qw/
      Mojolicious
      Mojolicious::Plugin::Mail
      Mojolicious::Plugin::BasicAuthPlus
      EV
      DBI
      DBD::mysql
      DBIx::Class
      /) {
    my $v;
    if (my $e = load_class $m) {
      $v = ref $e ? "Exception: $e" : 'Not found!';
    } else {
      $v = $m->VERSION || 'unknown';
    }
    push @$modules, [$m, $v];
  }

  $self->render(
    'modules' => $modules,
  );
}

1;
