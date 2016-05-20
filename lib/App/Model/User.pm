package App::Model::User;

use Mojo::Base 'App::Model';

# use App::Util;

sub resultset { state $rs = shift->schema->resultset('User') };

=encoding utf8

=head1 NAME

App::Model::User - Модель пользователя

=cut

# sub password {
#   my ($self, $value) = @_;

#   return $self->model->password if @_ == 1;

#   $self->password_salt(App::Util::random_hex(8));
#   $self->model->password(App::Util::md5_hex($value, $self->password_salt));
#   $self;
# }

# sub check_password {
#   my ($self, $password) = @_;

#   App::Util::md5_hex($password, $self->password_salt) eq $self->password;
# }

1;
