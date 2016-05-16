package App::Util::Date;

use Mojo::Base 'Exporter';

use Time::Local;
use POSIX qw[mktime];
use DateTime;
use DateTime::TimeZone 1.76; # 2014+

DateTime->DefaultLocale('ru_RU');

=encoding utf8

=head1 NAME

App::Util::Date — функции даты и времени.

=cut

our @EXPORT = qw(curdate now unixtime);

our @EXPORT_OK =
  qw(datetime2mysql from_unixtime last_day_of_month to_datetime unixtime month_to_number);

our %EXPORT_TAGS = (ALL => [@EXPORT, @EXPORT_OK]);

my $random_seq = 0;
my $default_time_zone = 'Europe/Moscow';

=head2 curdate

Возвращает текущую дату в формате CURDATE() Mysql

=cut

sub curdate { to_datetime()->ymd }
# sub curdate {(split ' ', from_unixtime())[0]};

=head2 datetime2mysql

Возвращает текущее время в формате NOW() Mysql

=cut

sub datetime2mysql {
  my $dt = shift || to_datetime();
  return $dt->ymd('-') . ' '. $dt->hms(':');
}

=head2 from_unixtime

Принимает time(). Возвращает текущее время в формате NOW() Mysql

=cut

sub from_unixtime {
  my $time = shift || time;

  my ($sec, $min, $hour, $day, $mon, $year) = (localtime($time))[0..5];
  $mon++;
  $year += 1900;

  return sprintf(
    "%04d-%02d-%02d %02d:%02d:%02d",
    $year, $mon, $day, $hour, $min, $sec
  );
}

=head2 last_day_of_month



=cut

sub last_day_of_month {
  my $d = shift;
  my $dt;

  if ($d =~ /^(\d{4})\D(\d+)/) {
    $dt = DateTime->last_day_of_month(
      year      => $1,
      month     => $2,
    );
  }
  return $dt && $dt->ymd('-');
}

=head2 month_to_number

Номер месяца по написанию

=cut

sub month_to_number {
  {
    'jan'       => 1,  'янв' => 1,
    'feb'       => 2,  'фев' => 2,
    'mar'       => 3,  'мар' => 3,
    'apr'       => 4,  'апр' => 4,
    'may'       => 5,  'май' => 5,  'мае' => 5,  'мая' => 5, 'маю' => 5,
    'jun'       => 6,  'июн' => 6,
    'jul'       => 7,  'июл' => 7,
    'aug'       => 8,  'авг' => 8,
    'sep'       => 9,  'сен' => 9,
    'oct'       => 10, 'окт' => 10,
    'nov'       => 11, 'ноя' => 11,
    'dec'       => 12, 'дек' => 12,
  }->{lc substr($_[0], 0, 3)}
}

=head2 now

Алиас к L<App::Util::Date/datetime2mysql>

=cut

sub now { &datetime2mysql }

=head2 to_datetime

Возвращает DateTime объкт текущего времени. Опционально можно передать время
первым параметром в любом формате.

=cut

sub to_datetime {
  my $t = shift;
  my $dt;

  if (!$t) {
    $dt = DateTime->now('time_zone' => $default_time_zone)
  } elsif ($t =~ /^\d+$/) {
    my @d = localtime($t);
    $dt = DateTime->new(
      'year'      => $d[5]+1900,
      'month'     => $d[4]+1,
      'day'       => $d[3],
      'hour'      => $d[2],
      'minute'    => $d[1],
      'second'    => $d[0],
      'time_zone' => $default_time_zone,
      @_,
    );
  } elsif ($t =~ /^(\d{4})\D(\d+)\D(\d+)$/) {
    $dt = DateTime->new(
      'year'      => $1,
      'month'     => $2,
      'day'       => $3,
      'time_zone' => $default_time_zone,
      @_,
    );
  } elsif ($t =~ /^(\d{4})\D(\d+)\D(\d+)\s(\d+):(\d+):(\d+)$/) {
    $dt = DateTime->new(
      'year'      => $1,
      'month'     => $2,
      'day'       => $3,
      'hour'      => $4,
      'minute'    => $5,
      'second'    => $6,
      'time_zone' => $default_time_zone,
      @_,
    );
  } elsif ($t =~ /^\D{3}\s(\D{3})\s(\d+)\s(\d+):(\d+):(\d+)\s\D\d+\s(\d+)$/) {
    #Из формата твитера в dt
    #Tue Apr 15 07:10:39 +0000 2014
    $dt = DateTime->new(
      'year'      => $6,
      'month'     => month_to_number($1),
      'day'       => $2,
      'hour'      => $3,
      'minute'    => $4,
      'second'    => $5,
      'time_zone' => 'UTC',
      @_,
    )->set_time_zone($default_time_zone);
  }

  return $dt;
}

=head2 unixtime

Принимает время первым параметром в любом формате, возвращает unixtime. Без
параметров возвращает текущее time.

=cut

sub unixtime {
  my $t = shift or return time;

  return $t if $t =~ /^\d+$/;

  if ($t =~ /^(\d{4})-(\d+)-(\d+)\s(\d+):(\d+):(\d+)$/) { # mysql time
    return mktime($6, $5, $4, $3, $2-1, $1-1900);
  }
  elsif ($t =~ /^(\d{4})-(\d+)-(\d+)$/) { # mysql date
    return mktime('0', '0', '0', $3, $2-1, $1-1900);
  }
}

1;
