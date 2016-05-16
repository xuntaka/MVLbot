package App::Sorter;

use Mojo::Base -base;

has sort  => undef;
has order => undef;
has model => undef;

sub order_by {
	my $self = shift;

	if ($self->model && $self->sort && ! ref $self->sort) {
		$self->sort('id'), $self->order('desc')
			unless $self->model->can($self->sort);
	}

	$self->sort('id'), $self->order('desc') unless $self->sort;

	return $self->sort, $self->order;
}

1;
