package App::Model::House;

use Mojo::Base 'App::Model';

sub resultset { state $rs = shift->schema->resultset('House') };

=encoding utf8

=head1 NAME

App::Model::House - Модель дома

=cut

1;
