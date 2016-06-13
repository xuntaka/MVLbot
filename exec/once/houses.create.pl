#!/usr/bin/perl
use v5.18;
use utf8;

BEGIN { require FindBin; require "$FindBin::Bin/../init.pl"; }
BEGIN { $ENV{'MOJO_USERAGENT_DEBUG'} = 1; }

my $H = [
  {
    'title' => 'Лесная 16',
    'type'  => 'house',
    'sections' => [
      [  1.. 39], #  1 14x3
      [ 40.. 78], #  2 14x3
      [ 79..122], #  3 12x4
      [123..174], #  4 14x4
      [175..207], #  5 12x3
      [208..240], #  6 12x4
      [241..278], #  7 14x4
      [279..311], #  8 12x4
      [312..344], #  9 12x3
      [345..396], # 10 14x4
      [397..440], # 11 12x4
      [441..479], # 12 14x3
      [480..518], # 13 14x3
    ],
  },
  {
    'title' => 'Лесная 17',
    'type'  => 'house',
    'sections' => [
      [  1.. 39], #  1 14x3
      [ 40.. 78], #  2 14x3
      [ 79..122], #  3 12x4
      [123..174], #  4 14x4
      [175..207], #  5 12x3
      [208..240], #  6 12x4
      [241..278], #  7 14x4
      [279..311], #  8 12x4
      [312..344], #  9 12x3
      [345..396], # 10 14x4
      [397..440], # 11 12x4
      [441..479], # 12 14x3
      [480..518], # 13 14x3
    ],
  },
  {
    'title' => 'Лесная 18',
    'type'  => 'house',
    'sections' => [
      [  1.. 39], #  1 14x3
      [ 40.. 72], #  2 12x3
      [ 73..105], #  3 12x3
      [106..157], #  4 14x4
    ],
  },
  {
    'title' => 'Кленовая 1',
    'type'  => 'house',
    'sections' => [],
  },
  {
    'title' => 'Кленовая 2',
    'type'  => 'house',
    'sections' => [],
  },
];

app->db->do('truncate houses');

foreach (@$H) {
  my $h = app->M('House')->new(
    'pid'   => 0,
    'type'  => 'house',
    'title' => $_->{'title'},
  )->store;

  next unless @{$_->{'sections'}};

  my $s_i = 0;
  foreach (@{$_->{'sections'}}) {
    my $s = app->M('House')->new(
      'pid'   => $h->id,
      'type'  => 'section',
      'title' => ++$s_i,
    )->store;

    foreach (@$_) {
      my $f = app->M('House')->new(
        'pid'   => $s->id,
        'type'  => 'flat',
        'title' => $_,
      )->store;
    }
  }
}
