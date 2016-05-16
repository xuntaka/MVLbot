package App::Plugin::Logger;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
	my ($self, $app) = @_;

	$app->helper('logger'             => \&_add_log    );
	$app->helper('logger_search'      => \&_search_logs);
	$app->helper('logger_search_user' => \&_search_all_user_logs);
}

# Get:
#  object  => $o, # App::Model:: object
#  user    => $u, # App::Model:: object
#  action  => 'varchar',
#  comment => 'text',
#  data    => {}, # varios data
sub _add_log {
	my $c = shift;

	my %p = @_;
	my $object = delete $p{'object'};
	my $user   = delete $p{'user'  } || $c->user;

	$c->M('Log')->new(
		'ip' => $c->get_ip,
		'ua' => $c->req->headers->user_agent,
		'changes' => {
			%{delete $p{'changes'} || {}},
			%{$object->{'__changes'} || {}},
		},
		%p,
	)
	->object($object)
	->user($user)
	->store_wo_reload;
}

# search_log(object => $obj)->order_by('id desc')->all
sub _search_logs {
	my $c = shift;

	my %p = @_;
	foreach my $k (keys %p) {
		if (ref($p{$k}) =~ /^App::Model::/) {
			my $o = delete $p{$k};
			$p{"$k\_class"} = ref($o);
			$p{"$k\_class"} =~ s/^App::Model:://;
			$p{"$k\_id"   } = $o->id;
		}
	}
	delete $p{'user'};
	delete $p{'object'};

	return $c->M('Log')->search(%p);
}

# Ищет все логи относящиеся к юзеру.
# _search_all_user_logs( $user )
# _search_all_user_logs( $user->id )
sub _search_all_user_logs {
	my $c    = shift;
	my $user = shift;

	my $user_id = ref $user ? $user->id : $user;

	return $c->M('Log')->search(
		{
			-or => [
				-and => [object_class => 'User', object_id => $user_id],
				-and => [user_class   => 'User', user_id   => $user_id],
			]
		}
	);
}

1;
