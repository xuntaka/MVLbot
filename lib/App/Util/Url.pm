package App::Util::Url;

use Mojo::Base 'Exporter';

=encoding utf8

=head1 NAME

App::Util::Url — функции работы со ссылками.

=cut

our @EXPORT    = qw();

our @EXPORT_OK = qw(normalize_url parse_url url_re);

our %EXPORT_TAGS = (ALL => [@EXPORT, @EXPORT_OK]);

=head2 normalize_url

Приводит url к виду, пригодному для сравнения (us-ascii с '%').

Принимает charset сайта, на котором расположен url. (charset площадки для
кодирования kw копирам)

=cut

sub normalize_url {
	my ($url, $charset) = @_;

	$url =~ s/^\s+//;
	$url =~ s/\s+$//;

	my ($s, $h, $p, $q, $f) = parse_url($url);

	foreach ($p, $q, $f) {
		next unless length;
		s/&amp;/&/gi;
		s{/+}{/}g;
		# Всегда utf-8, как в браузерах /вася/%D0%9E
		$_ = Encode::encode('utf-8', $_) if Encode::is_utf8($_);
		# символы >127 кодируем в '%XX'
		$_ = Mojo::Util::url_escape($_, '^\x00-\x7f');
		s/(%[0-9a-fA-F]{2})/uc $1/ge; # '%xy' => '%XY'
	}

	Mojo::URL->new
		->scheme($s || 'http')
		->host(App::Util::Domain::encode_idn($h))
		->path($p || '/')
		->query($q)
		->fragment($f)
		->to_string;
}

=head2 parse_url

parse_url

	return ($scheme, $host, $path, $query, $fragment)

=cut

sub parse_url {
	my $url = shift;
	my ($s, $h, $p, $q, $f);

	for ($url) {
		s{^\s+}{};
		s{\s+$}{};

		($s, $h, $p, $q, $f) = m{^
			(?:(.+):)?
			(?://)?
			((?:[^/?#]+\.)+(?:[^/?#]+))
			([^?#]+)?
			(?:\?([^#]+))?
			(?:\#(.+))?
		}xi;
	}

	return wantarray
		? ($s, $h, $p, $q, $f)
		: [$s, $h, $p, $q, $f];
}

=head2 url_re

Превращает URL в регекспу. Старается не ломать уже переданную регекспу.

=cut

sub url_re {
	my $url      = shift;
	my $strict   = shift;
	my $textmode = shift;

	my ($s, $h, $p, $q, $f) = parse_url($url);

	my $path = ($p || '/') . ($q ? '?' . $q : '') . ($f ? '#' . $f : '');

	my $re = '';
	$re .= App::Util::Domain::domain_re($h, 1) if $h;

	if ($path && $path ne '/') {
		for (App::Util::bytes($path)) {
			s/^\/// if $h;

			next unless length;

			s/([^A-Za-z0-9+\-–._~\/=?&%:])/sprintf('%%%02X',ord($1))/ge; #/
			$re .= quotemeta;

			if (m{/+$}) {
				s{/+$}{};
				$re .= '/?';
			} elsif (!(/[?#]/ || /(?:\.[^?#]+)(?:[?#]|$)/)) {
				$re .= '/?';
			}
		}
	} else {
		$re .= '?';
	}

	$re .= '$' if $strict;

	return $re if $textmode;

	qr/$re/;
}

1;
