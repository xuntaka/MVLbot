package App::Plugin::Helpers::Dates;

use utf8;

use Mojo::Base 'Mojolicious::Plugin';
use App::Util;
use POSIX ();

sub register {
	my ($self, $app) = @_;
	
	my @M  = qw(0 января февраля марта апреля мая июня июля августа сентября октября ноября декабря);
	my @DP = qw(0 Январь Февраль Март  Апрель Май Июнь Июль Август  Сентябрь Октябрь Ноябрь Декабрь);
	
	# dp => 1 - datepicker formate
	$app->helper('date' => sub {
		my $self    = shift;
		my $sqltime = shift || '';
		my %p = @_;
		my $localtime = $self->stash('_localtime');
		$self->stash('_localtime' => ($localtime = [localtime])) unless $localtime;
		
		$sqltime = App::Util::from_unixtime($sqltime) if $sqltime =~ /^\d+$/;
		
		my ($date, $time) = split ' ', $sqltime;
		$date //= ''; $time //= '';
		return '—' if !$date || $date =~ /^0{4}-/;
		my @ymd = split '-', $date;
		
		return sprintf("%02d.%02d.%02d", $ymd[2], $ymd[1], $ymd[0] % 100) if $p{'simple'} && $p{'with_year'};
		return sprintf("%02d.%02d",      $ymd[2], $ymd[1]               ) if $p{'simple'};
		my $value = ( $p{'dp'} ? sprintf("%02d", $ymd[2]) : $ymd[2]+0 ) . ' ';
		   $value = '' if $p{'no_days'};
		my $month = $p{'dp'} ? $DP[$ymd[1]] : $M[$ymd[1]];
		   $month = ucfirst $month       if $p{'upper'};
		   $month = substr($month, 0, 3) if $p{'short'};
		$value .= $month;
		
		$value .= ' ' . $ymd[0]                        if $localtime->[5]+1900 != $ymd[0] || $p{'with_year'} || $p{'dp'};
		$time =~ s/:\d{2}$//                           if $time && ! $p{'with_seconds'};
		$value .= qq{ <span class="time">$time</span>} if $time && ! $p{'no_time'} && ! $p{'dp'};
		return $value;
	});
	
	$app->helper('sms_date' => sub {
		my $self    = shift;
		my $sqltime = shift || '';
		my %p = @_;
		
		$sqltime = App::Util::from_unixtime($sqltime) if $sqltime =~ /^\d+$/;
		
		my ($date, $time) = split ' ', $sqltime;
		return '--' if !$date || $date =~ /^0{4}-/;
		my @ymd = split '-', $date;
		my $value = sprintf("%02d.%02d", $ymd[2], $ymd[1]);
		$time =~ s/:\d{2}$// unless $p{'with_seconds'};
		$value .= ' '. $time if $time && !$p{'no_time'};
		return $value;
	});
	
	my $nm = -1;
	my @MS = qw(0 Янв Фев Мар Апр Май Июн Июл Авг Сен Окт Ноя Дек);
	my %MShort = map { $_ => length(++$nm) == 1 ? "0$nm" : $nm } @MS;
	$app->helper('date_reverse' => sub {
		my $self = shift;
		my $date = shift;
		
		return '0000-00-00' unless $date;
		my ($d, $m, $y) = split('\s', $date);
		
		return "$y-" . $MShort{$m} . "-$d";
	});
	
	# Atom / RFC-3339 date format:
	# - '2003-12-13T18:30:02+01:00'
	# - '2003-12-13T18:30:02.25Z'
	$app->helper('date3339' => sub {
		my $self = shift;
		my $date = shift or return '';
		
		$date =~ s/ /T/;
		my $tz = POSIX::strftime('%z', localtime);
		$date .= $tz if $tz =~ s/^([+-]\d\d)(\d\d)$/$1:$2/;
		return $date;
	});
	
	# ISO 8601 date: YYYY-MM-DD
	$app->helper('isodate' => sub {
		my $self = shift;
		my $date = shift or return '';
		$date =~ s/\s.*//; # drop time
		return $date;
	});
	
	# ГОСТ Р 6.30-2003 date: DD.MM.YYYY
	$app->helper('gostdate' => sub {
		my $self = shift;
		my $date = shift or return '';
		$date =~ s/^(\d+)-(\d+)-(\d+).*/$3.$2.$1/; # drop time
		return $date;
	});

	# 'September 20, 2013'
	$app->helper('invoice_mdy_date' => sub {
		my $self = shift;
		my $dt = App::Util::to_datetime(shift, locale => 'en_US');
		return $dt->month_name.' '.$dt->day.', '.$dt->year;
	});
	
	# Возраст (now - date) в днях, часах
	$app->helper('age' => sub {
		my ($self, $date, $time) = @_;

		return '—' unless $date;
		return '—' if     $date =~ /^0000/;

		$date = unixtime($date) if $date =~ /^\d{4}-/;
		$time ||= time();

		my $delta = $time - $date; # sec
		my @age;
		if (my $delta_days = int($delta / 86400)) {
			push @age, "$delta_days\x{A0}д"; # nbsp
			$delta -= 86400 * $delta_days;
		}
		if (my $delta_hours = int($delta / 3600)) {
			push @age, "$delta_hours\x{A0}ч";
			$delta -= 3600 * $delta_hours;
		}
		if (@age < 2 && (my $delta_mins = int($delta / 60))) {
			push @age, "$delta_mins\x{A0}м";
		}
		return join(' ', @age);
	});
	
	$app->helper('sec2time' => sub {
		my ($self, $sec, %p) = @_;
		return '—' unless $sec;
		my $d = int($sec / 86400); $sec -= $d * 86400;
		my $h = int($sec / 3600 ); $sec -= $h * 3600;
		my $m = int($sec / 60   ); $sec -= $m * 60;
		return
			($d ? "$d\x{A0}д.\x{A0}" : '') .
			sprintf($p{'no_sec'} ? "%02d:%02d" : "%02d:%02d:%02d", $h, $m, $sec);
	});

	$app->helper('unixtime' => sub { shift; unixtime(@_) });
}

1;
