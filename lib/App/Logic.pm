package App::Logic;

use Mojo::Base -base;

use Carp ();

# Класс общей логики контроллеров

has app       => sub { shift->c->app         };
has billing   => sub { shift->app->billing   };
has c         => undef; # контроллер
has config    => sub { shift->app->config    };
has errors    => sub { my $c = shift->c; $c ? $c->errors  : App::Errors->new };
has queue     => sub { shift->app->queue     };
has session   => sub { my $c = shift->c; $c ? $c->session : undef            };
has ua        => sub { shift->app->ua        };
has user      => sub { my $c = shift->c; $c ? $c->user    : undef            };

sub API { shift->app->API(@_) }

sub AUTOLOAD {
  my $self = shift;

  my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;

  # Call helper with current controller
  Carp::croak qq{Can't locate object method "$method" via package "$package"}
    unless my $helper = $self->app->renderer->get_helper($method);
  return $self->c ? $self->c->$helper(@_) : $self->app->$helper(@_);
}

sub L {
  my $self = shift;

  $self->app->L(@_,
    $self->c ? (
      'c' => $self->c
    ) : (
      map { $_ => $self->$_ }
      qw[errors session user]
    ),
  );
}

sub M { shift->app->M(@_) }

sub cookie { shift->c->cookie(@_) }

sub every_param {
  my $self = shift;
  $self->c ? $self->c->every_param(@_) : [];
}

sub logger {
  my $self = shift;
  $self->c ? $self->c->logger(@_) : $self->app->logger(@_);
}

sub new {
  my $self = shift;
  my $attr = @_ ? @_ > 1 ? {@_} : shift : {};

  $self = $self->SUPER::new(
    'app' => delete $attr->{'app'},
    'c'   => delete $attr->{'c'  },
  );

  $self->params($attr);
}

sub param {
  my ($self, $name) = (shift, shift);

  if (@_) {
    $self->c && $self->c->param($name => @_);
    return $self->{'__params'}->{$name} = @_ > 1 ? [@_] : $_[0];
  }

  $self->{'__params'}->{$name} || $self->c && $self->c->param($name);
}

sub params {
  my $self = shift;
  my $params = @_ ? @_ > 1 ? {@_} : shift : {};

  foreach (keys %$params) {
    if ($self->can($_)) {
      $self->$_(delete $params->{$_});
    }
    else {
      $self->{'__params'}->{$_} = $params->{$_};
    }
  }

  $self;
}

sub stash { shift->c->stash(@_) }

1;
