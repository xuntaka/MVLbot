package App::Plugin::Helpers;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw(url_escape xml_escape);
use Mojo::ByteStream;
use App::Util qw(decode_idn_in_url);
use JSON -convert_blessed_universally;
use POSIX ();

sub register {
	my ($self, $app) = @_;
	my $json = JSON->new->allow_nonref;
	my $json_dumper = JSON->new->allow_nonref->allow_blessed->convert_blessed->canonical->pretty;

	$app->helper('errors'   => sub { shift->errors          });
	$app->helper('user'     => sub { shift->current_user    });
	$app->helper('location' => sub { shift->current_route   });
	$app->helper('cookie'   => sub { shift->cookie(@_)      });

	$app->helper('is_dev' => sub { $app->is_dev });
	$app->helper('is_https' => sub { $_[0]->req->is_secure });
	$app->helper('is_push_supported' => sub {
		my $ua = $_[0]->req->headers->user_agent;
		if ($ua =~ m{ Chrome/(?:4[2-9]|[5-9][0-9])\.}i) { # Chrome 42+
			return if $ua =~ m{  OPR/}i; # -Opera
			return 'chrome';
		}
		if ($ua =~ m{ Firefox/(?:4[4-9]|[5-9][0-9])\.}i) { # FF 44+
			return if $ua =~ m{(?:Mobile|Tablet|TV);} || $ua =~ /mobi/i;
			return 'ff';
		}
		return;
	});

	$app->helper('url_for_full' => sub {
		my $self = shift;
		my $user = $self->stash('user') || $self->user;
		my $serv = $user && $user->is_legal_resident ? 'biz_server' : 'server';
		my $scheme = $self->stash('force_scheme') || $self->is_https ? 'https' : 'http';
		$self->url_for(@_)->scheme($scheme)->host($self->config->{$serv}->{'host'});
	});
	$app->helper('mail_url' => sub {
		my $self = shift;
		my $user = $self->stash('user') || $self->user;
		my $token = $user && $user->mail_auth_token;
		return $self->url_for_full(@_) unless $user && $token;
		my $res = $self->url_for_full('mail-login', 'user_id' => $user->id, 'token' => $token)->query('return_to' => $self->url_for(@_));
		return $self->config->{https}{on} ? $res->scheme('https') : $res;
	});
	$app->helper('unsubscribe_url' => sub {
		my ($self, $type) = @_;
		my $user = $self->stash('user') || $self->user;
		my $url = $self->url_for_full('email-unsubscribe', user_id => $user->id, code => $user->mail_code, type => $type || 'mail');
		return $self->config->{https}{on} ? $url->scheme('https') : $url;
	});
	
	$app->helper('pager'    => sub {
		my $c = shift;
		my $entries_per_page = shift || 20;
		
		my $pager = $c->stash('pager');
		return $pager if $pager;
		$pager ||= Data::Page->new;
		
		$pager->entries_per_page($entries_per_page);
		$pager->current_page($c->param('page') || 1);
		
		$c->stash('pager' => $pager);
		$c->stash('pager');
	});
	
	$app->helper('sorter'    => sub {
		my $c = shift;
		my $model = shift;
		my $sort  = shift;
		my $order = shift;
		
		my $sorter = $c->stash('sorter');
		return $sorter if $sorter;
		
		$order = undef if $c->param('sort');
		
		$sorter ||= App::Sorter->new(
			'model' => $model && $c->M($model),
			'sort'  => $c->param('sort' ) || $sort,
			'order' => $c->param('order') || $order,
		);
		
		$c->stash('sorter' => $sorter);
		$c->stash('sorter');
	});

	$app->helper('sort_icon' => sub {
		my ($self, $sorter, $id) = @_;
		my $ico = 'sort';
		if ($sorter->sort eq $id) {
			$ico = $sorter->order eq 'desc' ? 'sort-desc' : 'sort-asc';
		}
		return qq{<i class="sort-icon fa fa-$ico"></i>};
	});
	$app->helper('delta_icon' => sub {
		my ($self, $cur, $old, $reverse, $format) = @_;
		return '' unless defined $cur && defined $old;
		my $delta = $cur - $old;
		return '' unless $delta;
		my $up = $reverse ? $delta < 0 : $delta > 0; # reverse => меньше - лучше
		$format ||= '%+d'; # int по умолчанию
		return q{<i class="delta-icon fa fa-sort-}. ($up ? 'up' : 'down').
			q{ title="}. sprintf($format, $delta) . q{"></i>};
	});

	$app->helper('pre'      => sub {
		my $self = shift;
		my $text = shift;
		return '' unless defined $text;
		
		for ($text) {
			s{\s+$}{}s;
			s{<}{&lt;}g;
			s{>}{&gt;}g;
			s{\n}{<br />}g;
			return $_;
		}
	});

	$app->helper('nbsp' => sub {
		my ($self, $text)= @_;
		$text =~ s/\s+/\x{A0}/g;
		return $text;
	});

	$app->helper('js_on_ready' => sub {
		my $self = shift;
		my $stash = $self->stash;
		return $stash->{js_on_ready} unless @_;
		# CDATA
		my $cb = sub {''};
		if (ref $_[-1] eq 'CODE') {
			my $old = pop;
			$cb = sub { $old->() }
		}
		push @{$stash->{js_on_ready}}, $cb;
		return;
	});
	# Пока так, надо будет научить его нормальному JS
	$app->helper('js_config' => sub {
		my $self  = shift;
		return $self->json_dumper($self->stash('js_config')) unless @_;
		
		my $scope = shift;
		
		my $data = $self->stash->{'js_config'}->{$scope} || {};
		$self->stash->{'js_config'}->{$scope} = {
			%$data,
			@_,
		};
	});

	# plural_form $num, 'день', 'дня', 'дней'
	$app->helper('plural_form' => sub {
		my $self  = shift;
		my ($d, $d0, $d1, $d2) = @_;
		
		my $mod_ = $d % 100;
		
		return "$d2" if $mod_ > 10 &&  $mod_ < 20; # заканчивается на 11 - 19
		
		my $mod2_ = $mod_ % 10;
		return "$d2" if $mod2_ == 0;
		return "$d0" if $mod2_ == 1;
		return "$d1" if $mod2_  < 5;
		return "$d2";
	});
	
	# say_number $num, 'день', 'дня', 'дней'
	$app->helper('say_number' => sub {
		my $self  = shift;
		my ($d, $d0, $d1, $d2) = @_;
		
		return "$d " . $self->plural_form($d, $d0, $d1, $d2);
	});

	$app->helper('kilomega' => sub {
		my ($self, $num) = @_;
		my $abs = abs $num;
		return $num if $abs<1_000;
		return int($num/1_000).'k' if $abs<1_000_000;
		return int($num/1_000_000).'M' if $abs<1_000_000_000;
		return int($num/1_000_000_000).'G';
	});

	# https://ru.gravatar.com/site/implement/images/
	$app->helper('gravatar_image' => sub {
		my $self = shift;
		my $user = $self->stash('user') || $self->current_user;
		$user = shift if ref $_[0];
		my %p = @_;
		my %gp = (
			s => delete $p{s},
			r => delete $p{r},
			d => delete $p{d} || ($self->is_https ? 'https://' : 'http://'). $self->config->{'server'}->{'host'}. '/s/avatar/default.png',
		);
		my $email = $user ? $user->email : '';
		my $url = Mojo::URL->new(($self->is_https ? 'https://secure.gravatar.com/avatar/' : 'http://www.gravatar.com/avatar/').
			App::Util::md5_hex(lc $email))->query(%gp);
		my $url2x = Mojo::URL->new($url)->query([s => $gp{s}*2]);
		return $self->image($url, srcset => "$url2x 2x", width => $gp{s}, height => $gp{s}, %p);
	});
	$app->helper('svg' => sub {
		my ($self, $file, $width, $height, %p) = @_;
		return $self->tag('svg', width => $width, height => $height, %p,
			sub { $self->tag('image', 'xlink:href' => $file.'.svg', src => $file.'.png', width => $width, height => $height) });
	});

	$app->helper('xml_esc' => sub {
		my ($self, $url) = @_;
		
		$url = Mojo::Util::xml_escape($url);
		$url =~ s/&amp;/&/gs;
		
		return $url;
	});

	$app->helper('json' => sub { $json->encode($_[1]) =~ s{([<>\x{2028}\x{2029}])}{'\\u'.sprintf('%04X', ord $1)}egr }); #}
	$app->helper('json_dumper' => sub { $json_dumper->encode($_[1]) =~ s{([<>\x{2028}\x{2029}])}{'\\u'.sprintf('%04X', ord $1)}egr }); #}
	$app->helper('cut_text' => sub { shift; App::Util::cut_text(@_) });
	$app->helper('number_position' => sub { shift; App::Util::number_position(@_) }); # Форматирование больших чисел с выделением разрядов. Например 10000000 как 10 000 000
	$app->helper('translit' => sub { shift; App::Util::translit(@_) });
	$app->helper('xml_escape' => sub { shift; Mojo::Util::xml_escape(@_) });
	$app->helper('url_escape' => sub { shift; Mojo::Util::url_escape(@_) });

	$app->helper('decode_idn' => sub {
		my ($self, $url) = @_;
		return decode_idn_in_url($url);
	});

	$app->helper('checked' => sub {
		my ($self, $status) = @_;
		return $status ? Mojo::ByteStream->new('checked="checked"') : '';
	});

	$app->helper('disabled' => sub {
		my ($self, $status) = @_;
		return $status ? Mojo::ByteStream->new('disabled="disabled"') : '';
	});

	$app->helper('reply.forbidden' => sub {
		shift->render_maybe(
			'status'   => 403,
			'template' => 'forbidden',
			@_,
		);
	});
}

1;
