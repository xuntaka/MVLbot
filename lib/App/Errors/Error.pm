package App::Errors::Error;

use Mojo::Base -base;

use overload
	'bool'   => sub {1},
	'""'     => sub { shift->text },
	fallback => 1;

has 'code'   => undef;
has 'text'   => undef;
has 'status' => undef;

sub TO_JSON { shift->text }

1;
