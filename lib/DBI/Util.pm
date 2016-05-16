package DBI::Util;
use base 'DBI';
use Carp 'croak';

our $VERSION = '0.01';

sub _parse_cfg {
	my $cfg  =    shift || croak 'Bad config';
	my $attr = {%{shift || {}}, 'PrintError' => 0, 'RaiseError' => 1};
	
	return join(':',
		'dbi',
		join('',
			$cfg->{'drivername'},
			'(',
				join(',', map { "$_=>$attr->{$_}" } keys %$attr),
			')',
		),
		join(';',
			map { "$_=$cfg->{'datasource'}->{$_}" } keys %{$cfg->{'datasource'}||{}}
		)
	), @$cfg{'user', 'password'};
}

sub connect {
	shift->SUPER::connect(
		(map { $ENV{$_} = shift || $ENV{$_} } 'DBI_DSN', 'DBI_USER', 'DBI_PASS'),
		{%{shift || {}}, 'PrintError' => 0, 'RaiseError' => 1}
	)
}

package DBI::Util::db ;
use base 'DBI::db';
use Carp 'croak';

sub connected {
	shift->SUPER::connected(
		(map { $ENV{$_} = shift || $ENV{$_} } 'DBI_DSN', 'DBI_USER', 'DBI_PASS'),
		{%{shift || {}}, 'PrintError' => 0, 'RaiseError' => 1}
	)
}

sub select {    eval { shift->SUPER::selectall_arrayref(shift, {'Slice' => {}}, @_) } || croak 'Bad select: ', DBI::Util->errstr  }
sub query  { 0+(eval { shift->SUPER::do                (shift,           undef, @_) } || croak 'Bad query : ', DBI::Util->errstr) }

sub in     {
	my $self = shift;
	' in ('.(join ',', map { $self->SUPER::quote($_) } @_ or 'NULL').') ';
}

package DBI::Util::st;
use base 'DBI::st';

1;
