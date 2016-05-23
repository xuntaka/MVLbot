package App::Model::Chat;

use Mojo::Base 'App::Model';

sub resultset { state $rs = shift->schema->resultset('Chat') };

=encoding utf8

=head1 NAME

App::Model::Chat - Модель чата

=cut

1;
