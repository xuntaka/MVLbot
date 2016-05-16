package DBI::db;

use Carp 'croak';

sub select {    eval { shift->selectall_arrayref(shift, {'Slice' => {}}, @_) } || croak 'Bad select: ', DBI->errstr  }
sub query  { 0+(eval { shift->do                (shift,           undef, @_) } || croak 'Bad query : ', DBI->errstr) }

sub in     {
	my $self = shift;
	' in ('.(join ',', map { $self->quote($_) } @_ or 'NULL').') ';
}

1;