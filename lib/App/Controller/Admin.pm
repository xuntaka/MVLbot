package App::Controller::Admin;

use Mojo::Base 'App::Controller';

use JSON;
use Digest::MD5 qw(md5_hex);
use Mojo::Util qw(camelize decamelize);

has user_id => sub {
  my $data = shift->session('admin_auth');
  return ref $data eq 'HASH' && $data->{'user_id'} || undef;
};

has user => sub {
  my $c = shift;

  my $user_id = $c->user_id or return undef;

  my $user = $c->M('Admin::User')->get($user_id);

  return $user if $user;

  $c->session('expires' => 1);
  return undef;
};

sub authenticate_user {
  my ($self, $user, %args) = @_;

  my $data = {
    'user_id' => $user->id,
    %args,
  };

  $self->session('expiration' => 86400) if $args{'remember'};
  $self->session('admin_auth' => $data);
}

sub deauthenticate_user { shift->session('expires' => 1) }

1;
