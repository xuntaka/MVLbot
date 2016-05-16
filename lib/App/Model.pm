package App::Model;

use Mojo::Base -base;
use parent 'App::Model::Cache';

use Carp ();
use Time::HiRes qw/gettimeofday tv_interval/;

=encoding utf8

=head1 NAME

App::Model - Модель

=cut

use constant BENCHMARK => 0;

has api     => sub { shift->app->api     };
has app     => sub { $::app }; # временно так, потом надо поменять на undef
# has app     => undef;
has billing => sub { shift->app->billing };
has config  => sub { shift->app->config  };
has errors  => sub { App::Errors->new    };
has model   => undef;
has queue   => sub { shift->app->queue   };
has rs      => sub { shift->resultset    };
has schema  => sub { shift->app->schema  };

sub _bench(&) {
  my $code = shift;
  return $code->() unless BENCHMARK;

  my $t0 = [gettimeofday];
  my $res = $code->();
  warn "##### BENCH ". tv_interval($t0)."\n";
  return $res;
}

sub resultset {
  my $self = shift;
  $self->schema->resultset(shift);
};

=head2 L

Logic accessor

=cut

sub L {
  my $self = shift;
  my $name = shift;

  $self->{'__logic'}->{$name} //= $self->app->L($name, @_);
}

=head2 M

Model accessor

  Alias for App::M()

=cut

sub M { shift->app->M(@_) }

=head2 new

Конструктор модели. Принимает хеш или ссылку на хеш, заполняет существующие
акцессоры при наличии, всё незнакомое кладёт в data.

=cut

sub new {
  my $self = shift;
  my $attr = @_ ? @_ > 1 ? {@_} : shift : {};

  $self = $self->SUPER::new(
                                                              # V вот это убить потом
    'app' => delete $attr->{'app'} || ref $self && $self->app || $self->app,
  );

  $self->model(delete $attr->{'model'} || $self->resultset->new_result({}));
  $self->set($attr);

  return $self;
}

=head2 clone

Клонирование модели. Возвращает новый экземпляр.

=cut

sub clone {
  my $self = shift;
  my %columns = $self->model->get_inflated_columns;
  delete $columns{'id'};
  delete $columns{'ctime'};
  return $self->new(%columns, @_);
}

=head2 columns

Список полей, которые нужны в запросе

=cut

sub columns { shift->search(undef, { 'columns' => [@_] }) }

=head2 data

Акцессор к полю data

=cut

sub data {
  my $self = shift;

  return undef unless $self->model->can('data');

  my $data = $self->model->data || {};

  # Если не передали параметров, то просто отдаем содержимое data
  return $data unless @_;

  if (@_ == 1) {
    # Возвращаем модель, если передали undef
    return $self unless defined $_[0];

    # Если передали ссылку на хеш, то присваиваем его
    if (ref $_[0] eq 'HASH') {
      $self->model->data($_[0]);
      return $self;
    }
    # Если передали строку, то отдаем значение
    if (! ref $_[0]) {
      return $data->{$_[0]};
    }
    # Остальные случаи с одним параметром не обрабатываем
    return undef;
  }

  # Если передали 2 параметра, то это установка значения
  if (@_ == 2) {
    my ($k, $v) = @_;
    if (defined $v) {
      $data->{$k} = $v;
    } else {
      delete $data->{$k};
    }
    $self->model->data(%$data ? $data : undef);
  }

  $self;
}

=head2 get

Загрузка модели по первичному ключу. Сначала модель пытается загрузиться из
локального кеша приложения (при передаче флага get($id, 'skip_local_cache')),
затем пытается загрузиться из общего кеша и в конце концов грузится из БД.

=cut

sub get { #get by pk
  my $self             = shift;
  my $id               = shift;
  my $skip_local_cache = shift;

  return undef unless $id;

  my $class = ref $self;

  my ($package, $filename, $line) = caller;
  $self->app->log->debug("Loading: $class $id [$package at $line]");

  if (
    ! $skip_local_cache &&
    (my $obj = $self->app->request_cache->{'model'}->{$class}->{$id})
  ) {
    $self->app->log->debug('ALREADY_LOADED');
    return $obj;
  }

  my $obj = $self->get_from_cache($id);

  if ($obj) {
    $self->app->log->debug('LOADED_FROM_CACHE');
  }
  else {
    $self->app->log->debug('LOADED_FROM_DB');

    $obj = $self->find($id);

    return undef unless $obj;

    $obj->store_to_cache;
  }

  $self->app->request_cache->{'model'}->{$class}->{$id} = $obj;

  return $obj;
}

=head2 reget

Алиас к get($id, 'skip_local_cache'))

=cut

sub reget { #get by pk. flush cache
  my ($self, $id) = @_;
  return $self->get($id, 'skip_local_cache');
}

=head2 find

Загрузка модели по первичному ключу из БД.

=cut

sub find { #get by pk
  my ($self, $id) = @_;
  return undef unless $id;

  _bench {
  my $model = $self->resultset->find($id) or return undef;
  $self->new(
    'app'   => $self->app,
    'model' => $model,
  );
  };
}

=head2 for_update

Загрузка модели из БД с блокировкой в транзакции.

=cut

sub for_update {
  my $self  = shift;

  $self->search(undef,
    { 'for' => 'update' }
  );
}

=head2 set

Принимает хеш или ссылку на хеш, заполняет существующие акцессоры при наличии,
всё незнакомое кладёт в data.

=cut

sub set {
  my $self = shift;
  my $attr = @_ ? @_ > 1 ? {@_} : shift : {};

  foreach (keys %$attr) {
    if ($self->can($_)) {
      $self->$_($attr->{$_});
    }
    else {
      $self->data($_ => $attr->{$_});
    }
  }

  return $self;
}

=head2 store

Сохраняет модель в БД, после чего перезагружает данные из БД и сохраняет в кеш.

=cut

sub store {
  my $self = shift;
  _bench { $self->model->update_or_insert->discard_changes };
  $self->store_to_cache;
  return $self;
}

=head2 store_wo_reload

Сохраняет модель в БД, без перезагрузки из БД и удаляет из кеша.

<B>Использовать с осторожностью.</B>

=cut

sub store_wo_reload {
  my $self = shift;
  _bench { $self->model->update_or_insert };

  # Костыль от падения JSON на ссылках на скаляры
  if (grep {ref eq 'SCALAR'} values %{$self->to_hash}) {
    # Удаляем из кеша, т.к. даты типа \'now()' всё сломают
    $self->drop_from_cache;
    return $self;
  }

  $self->store_to_cache;
  return $self;
}

sub in_storage      { shift->model->in_storage       }
sub delete          { shift->model->delete           }

# Get: $column_name
# Return: DBIx::Class::ResultSetColumn object
sub get_column      { shift->rs->get_column(@_)      }

sub search {
  my $self = shift;

  if (@_ <= 2 && (!defined($_[0]) || ref $_[0])) {
    $self->rs($self->rs->search_rs(@_));
  }
  else {
    $self->rs($self->rs->search_rs({shift, shift})) while @_;
  }

  $self;
}

#~ ->order_by(\'block_status desc, status desc')
#~ ->order_by(['block_status', 'status'], 'desc')
#~ ->order_by('status', 'desc')
sub order_by {
  my $self  = shift;

  my $sort  = shift || 'id';
  my $order = shift || 'asc';

  $order = 'asc' unless $order eq 'asc' || $order eq 'desc';
  #~ return $self unless can($sort); # HOW?

  $self->search(undef,
    {
      'order_by' => ref $sort ? $sort : {'-' . $order => $sort}
    }
  );
}

sub limit {
  my $self   = shift;
  my $offset = shift || 0;
  my $count  = shift || 0;

  return $self unless $offset || $count;

  if ($offset && not $count) {
    $count  = $offset;
    $offset = 0;
  }

  $self->rs(scalar $self->rs->slice($offset, $offset + $count - 1));
  $self;
}

sub all {
  my $self = shift;

  _bench {
  [
    map { $self->new('app' => $self->app, 'model' => $_) }
    grep {$_}
    $self->rs->all
  ];
  };
}

sub first {
  my $self = shift;
  _bench { $self->new('app' => $self->app, 'model' => $self->rs->first || return undef) };
}

sub paginate { # должен быть после всех search в цепочке (м.б. стоит его помнить и делать в all)
  my $self  = shift;
  my $pager = shift;

  $pager->total_entries($self->count); # достаем количество записей

  $self->search(undef,
    {
      'page' => $pager->current_page,
      'rows' => $pager->entries_per_page,
    }
  );

  $self;
}

sub count { my $self = shift; _bench { $self->rs->count } }

sub can {
  my $self = shift;
  return @_ && $self->SUPER::can(@_) || $self->model && $self->model->can(@_);
}

sub update {
  my $self = shift;
  my $params = ref $_[0] ? $_[0] : {@_};
  _bench { $self->rs->update($params) };
}

sub AUTOLOAD {
  my $self = $_[0];
  my ($package, $method) = our $AUTOLOAD =~ /^([\w:]+)::(\w+)$/;

  my $rs = $self->resultset;
  state %rs_can;
  if ($rs_can{$AUTOLOAD} //= $rs->can($method)) {
    $self->app->log->debug("!!!!!!!!!!!!!!!!!!! $package -> $method");

    my $code = sub { shift->resultset->$method(@_) };
    no strict 'refs';
    *{$AUTOLOAD} = $code;
    use strict 'refs';
    goto &{$code};
  }

  if (my $model = $self->model) {
    my $code;
    if ($model->can($method)) {
      $code = sub {
        my $self = shift;
        if (@_) {
          $self->{'__changes'}->{$method}->[0] ||= $self->model->$method
            if $self->in_storage;
          $self->model->$method(@_);
          if ($self->in_storage) {
            my $val = $self->model->$method;
            $self->{'__changes'}->{$method}->[1] =
              ref($val) eq 'SCALAR' ? $$val : $val;
            delete $self->{'__changes'}->{$method}
              if $self->{'__changes'}->{$method}->[0] &&
                 $self->{'__changes'}->{$method}->[0] eq $val;
          }
          return $self;
        } else {
          return $self->model->$method;
        }
      };
    } else {
      $code = sub {
        my $self = shift;
        return $self->model->get_column($method)
          if $self->model->has_column_loaded($method);

        Carp::croak("Can't find method $package->$method");
      };
    }

    no strict 'refs';
    *{$AUTOLOAD} = $code;
    use strict 'refs';
    goto &{$code};
  }

  Carp::croak("Can't find method $package->$method");
}

sub to_hash { +{shift->model->get_inflated_columns} }

# sub TO_JSON { shift->to_hash }
sub TO_JSON {
  my $self = shift;
  return [
    ref $self,
    {$self->model->get_inflated_columns},
  ];
}

sub DESTROY {}

1;
