package DBIx::Class::InflateColumn::Decimal;

our $VERSION = '0.01';

use strict;
use warnings;
use base qw/DBIx::Class/;

# ABSTRACT: Auto-inflate your decimal columns into floats

__PACKAGE__->load_components(qw/InflateColumn/);

sub register_column {
  my ($self, $column, $info, @rest) = @_;

  $self->next::method($column, $info, @rest);

  return unless $info->{data_type} eq 'decimal';

  $self->inflate_column(
    $column => {
      inflate => sub {
        my ( $value, $obj ) = @_;

        return defined($value) ? $value+0 : undef;
      },
      deflate => sub {
        return shift;
      },
    }
  );
}

1;
