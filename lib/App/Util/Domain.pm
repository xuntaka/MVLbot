package App::Util::Domain;

use Mojo::Base 'Exporter';

=encoding utf8

=head1 NAME

App::Util::Domain — функции работы с доменами.

=cut

use Net::IDN::Encode;

our @EXPORT    = qw();

our @EXPORT_OK = (
	qw(decode_idn decode_idn_in_url domain_re encode_idn encode_idn_in_url),
	qw(grep_bad_chars parse_domain),
);

our %EXPORT_TAGS = (ALL => [@EXPORT, @EXPORT_OK]);

=head2 decode_idn

Раскодирует IDN в ascii.

	'xn--80aj5afg.xn--p1ai' => 'сетап.рф'

=cut

sub decode_idn {
	Net::IDN::Encode::domain_to_unicode(shift);
}

=head2 decode_idn_in_url

Расшифровка IDN внутри ссылки.

	'http://xn--80aj5afg.xn--p1ai/bla-bla' => 'http://сетап.рф/bla-bla'

=cut

sub decode_idn_in_url {
	my $url = shift or return '';

	if ($url =~ m{^(?:https?://)?([^/]+)}) {
		my $domain = $1;
		my $idn_domain = decode_idn($domain);

		if ($idn_domain ne $domain) {
			$url =~ s/$domain/$idn_domain/;
		}
	}

	return $url;
}

=head2 domain_re

Превращает домен в регекспу.

=cut

sub domain_re {
	my $domain   = shift;
	my $textmode = shift;

	for ($domain) {
		# Отрезаем от домена всё, включая www
		s{^(?:.+:)?//}{};
		s{^(?:\(\?:)?www[\.)?]+}{};
		s{/.*$}{};
		$_ = quotemeta(encode_idn($_))
	}

	my $re = '^https?:\/\/(?:www\.)?' . $domain . '\/';

	return $re if $textmode;

	qr/$re/;
}

=head2 encode_idn

Кодирует не ascii домены в IDN.

	'сетап.рф' => 'xn--80aj5afg.xn--p1ai'

=cut

sub encode_idn {
	my $dname = lc shift or return undef;
	return $dname if $dname =~ /^[\x00-\x7f]*$/; # ascii
	lc eval { Net::IDN::Encode::domain_to_ascii($dname) } or $dname;
}

=head2 encode_idn_in_url

Кодирует не ascii домены в IDN в ссылке.

	'http://яндекс.рф/bla-bla' => 'http://xn-.../bla-bla'

=cut

sub encode_idn_in_url {
	my $url = shift;
	if ($url =~ m{^(?:(?:https?:)?//)?([^/]+)}) {
		my $domain = $1;
		my $idn_domain = encode_idn($domain);
		if ($idn_domain ne $domain) {
			$url =~ s/$domain/$idn_domain/;
		}
	}
	return $url;
}

sub grep_bad_chars {
	my ($dname, $ascii_only) = @_;
	my @bad_chars = $dname =~ /[^a-zа-я0-9\-.]/ig;
	@bad_chars = grep { ord($_) <= 127 } @bad_chars if !$ascii_only && @bad_chars;
	return unless @bad_chars;
	my %c = map { $_ => 1} @bad_chars;
	my @chars = sort keys %c;
	return wantarray ? @chars : \@chars;
}

sub parse_domain { App::Util::Url::parse_url(shift)->[1] }

1;
