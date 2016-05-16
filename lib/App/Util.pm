package App::Util;

use utf8;

use Mojo::Base 'Exporter';

=encoding utf8

=head1 NAME

App::Util — утилиты общего назначения.

=cut

use Mojo::Util;
use Mojo::DOM;
use Mojo::URL;
use Mojo::JSON qw(encode_json to_json);
use Digest::MD5 ();
use Time::Local;
use DateTime;
use DateTime::TimeZone 1.76; # 2014+
use Time::HiRes qw( gettimeofday tv_interval );
use Encode ();
use Encode::Guess;
use Date::Parse;
use App::Errors;

use App::Util::Date   ':ALL';
use App::Util::Domain ':ALL';
use App::Util::Url    ':ALL';

our @EXPORT = qw(curdate from_unixtime now to_datetime unixtime);

our @EXPORT_OK = (
  qw(clone),
  qw(is_email normalize_text),
  #Date
  qw(curdate datetime2mysql from_unixtime now to_datetime unixtime),
  qw(month_to_number calc_deadline_date),
  #Domain
  qw(decode_idn decode_idn_in_url domain_re encode_idn encode_idn_in_url),
  qw(grep_bad_chars parse_domain),
  #Url
  qw(normalize_url parse_url url_re),
  qw(ip2int int2ip)
);

DateTime->DefaultLocale('ru_RU');

use constant DEBUG => 0;

my $random_seq = 0;
my $night_from = 22;
my $night_to = 8;
my $article_bonus_hours = 3;

my $ru_phone_codes = '900|901|902|903|904|905|906|908|909|910|911|912|913|914|915|916|917|918|919|920|921|922|923|924|925|926|927|928|929|930|931|932|933|934|936|937|938|939|950|951|952|953|958|960|961|962|963|964|965|966|967|968|969|978|980|981|982|983|984|985|987|988|989|992|994|995|996|997|999';

sub random_hex {
	my $len = shift;
	my $value = '';
	my $base = join '', $$, time;
	
	$len ||= 32;
	
	do {
		$value .= md5_hex($base, $random_seq += int rand(10), rand(1000));
	} while length $value < $len;
	
	$value = substr($value, 0, $len) if $len;
	$value;
}

sub chars {
	wantarray
		? map { Encode::is_utf8( $_ ) ? $_ : Encode::decode_utf8( $_ ) } @_
		: Encode::is_utf8( $_[0] ) ? $_[0] : Encode::decode_utf8( $_[0] )
}

sub bytes {
	wantarray
		? map { Encode::is_utf8( $_ ) ? Encode::encode_utf8( $_ ) : $_ } @_
		: Encode::is_utf8( $_[0] ) ? Encode::encode_utf8( $_[0] ) : $_[0]
}

sub md5_hex {
	Digest::MD5::md5_hex( bytes( @_ ) )
}

sub md5_base64 {
	Digest::MD5::md5_base64( bytes( @_ ) )
}

sub is_email {
  $_[0] =~ /^
    [^()<>@,;:\\"\[\]\ \000-\031]+
    \@
    (?:[^()<>@,;:\\".\[\]\ \000-\031]+\.)+
    [^()<>@,;:\\".\[\]\ \000-\031]{2,}
  $/x ? 1 : 0
}

sub is_phone {
	my $tel = shift;
	$tel =~ s/[^\d]+//g;
	return $tel =~ /\d+/;
}

=head2 clone

deep copy for structures
Перловая реализация Storable::dclone.

=cut

sub clone {
	my $ref = shift;
	my $pas = shift // {};

	die "Can't clone $ref"
		if
			ref $ref eq 'CODE' ||
			ref $ref eq 'GLOB' ||
			ref $ref eq 'REF';

	if (ref($ref) eq 'ARRAY') {
		return [map {ref $_ ? $pas->{$_} //= clone($_, $pas) : $_} @$ref];
	} elsif (ref($ref) eq 'HASH') {
		return {map {
			$_ => (ref($ref->{$_})
				 ?
				$pas->{$ref->{$_}} //= clone($ref->{$_}, $pas)
				 :
				$ref->{$_})
			} keys %$ref};
	} elsif (ref($ref) eq 'SCALAR') {
		return \do {my $r = $$ref};
	} elsif (ref $ref) {
		$ref =~ /=([A-Z]+)/;
		return $pas->{$ref} //= bless clone(
			$1 eq 'HASH'   && {%$ref} ||
			$1 eq 'ARRAY'  && [@$ref] ||
			$1 eq 'SCALAR' && \do {my $r = $$ref} ||
			undef
		) => ref $ref;
	}

	return $ref;
}

sub cut_text {
	my ($s, $limit) = @_;
	$limit ||= 20;
	return $s if length($s) <= $limit;
	$s =~ s/^(.{1,$limit})\s.*/$1…/s or
		$s =~ s/^(.{$limit}).*/$1…/s;
	return $s;
}

# Param: [1, 2, 3.14, ...]
# Return: 0..N
sub weighted_rand {
	my $weights = shift or return;
	my $total = 0;
	my @ranges; # [0, w1), [w1, w1+w2), ...
	foreach (@$weights) {
		$total += $_;
		push @ranges, $total;
	}
	my $rand = rand $total;
	my $i;
	for($i = 0; $i < @ranges; $i++) {
		last if $rand < $ranges[$i];
	}
	return $i;
}

# Get: {a => "123", b => undef, c => { d => undef }}
# Result: {a => 123, c => {}} 
sub filter_json {
	my $hashref = shift;
	foreach (keys %$hashref) {
		my $v = $hashref->{$_};
		unless (defined $v) {
			delete($hashref->{$_});
			next;
		}
		my $ref = ref $v;
		if ($ref && $ref eq 'HASH') {
			filter_json($v);
			next;
		}
		$hashref->{$_} = $v+0 if $v =~ /^\-?\d+(?:\.\d+)?$/;
	}
	return $hashref;
}

# Форматирование больших чисел с выделением разрядов. Например 10000000 как 10 000 000
sub number_position {
	my $number   = shift;
	# my $splitter = shift || "\x{2009}"; # &thinsp;
	my $splitter = shift || "\x{00a0}"; # &nbsp;
	$number =~ s/(?<=\d)(?=(\d{3})+(?!\d))/$splitter/g;
	return $number;
}

sub translit {
	my ( $text ) = @_;
	# http://ru.wikipedia.org/wiki/Транслит
	$text =~ s/ё/yo/g;
	$text =~ s/ж/zh/g;
	$text =~ s/х/kh/g;
	$text =~ s/ц/tc/g;
	$text =~ s/ч/ch/g;
	$text =~ s/ш/sh/g;
	$text =~ s/щ/sch/g;
	$text =~ s/ю/yu/g;
	$text =~ s/я/ya/g;
	$text =~ tr/ъь//d;
	$text =~ tr/абвгдезийклмнопрстуфы/abvgdeziyklmnoprstufy/;
	$text =~ tr/\x20-\x7f//cd;
	return $text;
}

# from Lingua::RU::Numeric::Declension
# printf "%i %s", 38, numdecl(38, 'parrot', 'parrota', 'parrotov');
sub numdecl {
	my ($number, $nominative, $genitive, $plural) = @_;

	return $plural if $number =~ /1.$/;

	my ($last_digit) = $number =~ /(.)$/;

	return $nominative if $last_digit == 1;
	return $genitive if $last_digit > 0 && $last_digit < 5;
	return $plural;
}

sub normalize_text {
	my $text = shift;
	
	$text =~ s/(\xA0)+/ /sg;
	$text =~ s/(\x2014)+/-/sg;
	$text =~ s/\?/|/sg;
	$text =~ s/\s+/ /sg;
	$text =~ s{^\s+}{}s;
	$text =~ s{\s+$}{}s;
	#Вырезаем управляющие символы. Кроме гризонтальной табуляции, возврата каретки и перевода строки.
	$text =~ s{(:?\N{U+0000}|\N{U+0001}|\N{U+0002}|\N{U+0003}|\N{U+0004}|\N{U+0005}|\N{U+0006}|\N{U+0007}|\N{U+0008}
		                      |\N{U+000B}|\N{U+000C}           |\N{U+000E}|\N{U+000F}|\N{U+0010}|\N{U+0011}|\N{U+0012}
		|\N{U+0013}|\N{U+0014}|\N{U+0015}|\N{U+0016}|\N{U+0017}|\N{U+0018}|\N{U+0019}|\N{U+001A}|\N{U+001B}|\N{U+001C}
		|\N{U+001D}|\N{U+001E}|\N{U+001F})}{}g;
	
	return $text;
}

1;
