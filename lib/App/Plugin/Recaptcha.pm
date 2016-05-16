package App::Plugin::Recaptcha;

use base 'Mojolicious::Plugin';

sub register {
	my ($self, $app, $conf) = @_;
	
	$conf->{'lang'} ||= 'ru';

	$app->helper(
		'recaptcha' => sub {
			my ($self, $cb) = @_;
			
			my @post_data = (
				'https://www.google.com/recaptcha/api/siteverify',
				'form' => {
					'secret'     => $conf->{'secret'},
					'remoteip'   => $self->req->headers->header('X-Real-IP') ||
					                $self->tx->{'remote_address'},
					'response'   => $self->param('g-recaptcha-response'),
				}
			);

			my $callback = sub {
				my $content = $_[1]->res->to_string;
				my $result  = $content =~ /true/;

				$self->stash('recaptcha_error' => $content =~ m{false\s*(.*)$}si)
					unless $result;

				$cb->($result) if $cb;

				return $result;
			};
			
			if ($cb) {
				$self->ua->post(
					@post_data,
					$callback,
				);
			}
			else {
				my $tx = $self->ua->post(@post_data);
				
				return $callback->('', $tx);
			}
		}
	);
}
 
1;
