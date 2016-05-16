package App::Controller::Index;

use Mojo::Base 'App::Controller';

sub index {
	my $self = shift;

	$self->render;
}

sub webmaster {
	my $self = shift;
	
	$self->render;
}

sub logged {
	my $self = shift;
	
	if (my $user = $self->user) {
		my %count = (
			'sites'    => $user->is_webmaster && $self->M('Site')   ->search(owner_id => $user->id, 'block_status' => {'not_in' => ['transferred', 'declined', 'deleted']})->count || 0,
			'projects' => $user->is_optimizer && $self->M('Project')->search(owner_id => $user->id, 'block_status' => {'<>' => 'deleted'})->count || 0,
		);
		my $mode;
		my $workmode = $self->cookie('workmode') || '';
		$mode = $workmode if $count{$workmode};
		$mode ||= 'projects' if $self->user->is_legal;
		$mode ||= $count{'sites'} >= $count{'projects'} ? 'sites' : 'projects';

		$self->redirect_to($mode);
	}
	
	1;
}

1;
