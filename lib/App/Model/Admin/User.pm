package App::Model::Admin::User;

use utf8;
use strict;

use Mojo::Base 'App::Model';

sub resultset { state $rs = shift->schema->resultset('AdminUser') }

sub email_confirm() { 1 }
sub phone() { undef }
sub money() { undef }
sub account() { undef }
sub is_seopult() { 0 }
sub allow_email_type { !$_[0]->is_deleted }
sub allow_sms_type() { 0 }
sub allow_push_type() { 0 }
sub mail_auth_token() { '' }
sub is_legal             () { undef }
sub is_legal_resident    () { undef }
sub is_legal_nonresident () { undef }
sub has_active_sites     () { undef }
sub cancellation() { 0 }

sub auth_token {
	my $self = shift;
	App::Util::md5_hex(
		join '', $self->id, $self->email, $self->password, $self->password_salt
	);
}

sub password {
	my ($self, $value) = @_;
	
	return $self->model->password if @_ == 1;
	
	$self->password_salt(App::Util::random_hex(8));
	$self->model->password(App::Util::md5_hex($value, $self->password_salt));
}

sub check_password {
	my ($self, $password) = @_;
	
	App::Util::md5_hex($password, $self->password_salt) eq $self->password;
}

# Get: 'perm1', 'perm2', ...
# Result: 1 if have perm1 && perm2 && ...
sub allow {
	my $self       = shift;

	foreach (@_) {
		return 0 unless $self->data('permissions')->{$_};
	}
	return 1;
}

has new_tickets_count => sub {
	shift->M('Ticket')
		->search(
			'is_upsale' => 0,
			'status'    => 'new',
			'writer_id' => 0,
		)
		->count;
};

has unread_tickets_count => sub {
	my $self  = shift;
	$self->M('Ticket')
		->search(
			'is_upsale'    => 0,
			'admin_id'     => $self->id,
			'status'       => 'work',
			'admin_readed' => 0,
		)
		->count;
};

has missed_tickets_count => sub {
	my $self  = shift;
	$self->M('Ticket')
		->search(
			'is_upsale'         => 0,
			'status'            => {'<>' => 'close'},
			'last_message_type' => 'user',
			'writer_id'         => 0,
		)
		->count;
};

has unread_tickets_upsale_count => sub {
	my $self  = shift;
	$self->M('Ticket')
		->search(
			'is_upsale' => 1,
			'status'    => {'<>' => 'close'},
			'-or' => [
				{'last_message_type' => 'user'},
				{'upsale_attach'     => 1},
			],
		)
		->count;
};

1;
