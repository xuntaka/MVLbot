package App::Controller::Main;

use Mojo::Base 'App::Controller';

sub main {
	my $self = shift;
	
	if (my $user = $self->user) {
		my %count = (
			'sites'    => $user->is_webmaster && $self->M('Site')   ->search(owner_id => $user->id, 'block_status' => {'not_in' => ['transferred', 'declined', 'deleted']})->count || 0,
			'projects' => $user->is_optimizer && $self->M('Project')->search(owner_id => $user->id, 'block_status' => {'<>' => 'deleted'})->count || 0,
		);
		my $mode;
		my $workmode = $self->cookie('workmode') || '';
		$mode = $workmode if ($workmode && $count{$workmode} > 0);
		$mode ||= 'projects' if $self->user->is_legal;
		$mode ||= $count{sites} >= $count{projects} ? 'sites' : 'projects';
		return $self->redirect_to($mode);
	}
	
	$self->render;
}

sub manifest {
	my $self = shift;

	$self->res->headers->cache_control('public, max-age=86400');
	return $self->render('manifest', format => 'json');
}

1;
