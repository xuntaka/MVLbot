package App::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-10-25 17:23:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xOJn2Bs6c3GiUiuwQQh+Iw

our $VERSION = 1.001;

sub disconnect {
	my $self = shift;
	$self->storage->disconnect;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
