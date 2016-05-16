package App::Model::Cache;

use Mojo::Base -base;

sub cache_class { ref shift }

sub drop_from_cache {
  my $self  = shift;
  my $class = $self->cache_class or die "Only object can be dropped. $self";

  my $id;

  if ($self->can('id') && $self->id) {
    $id = $self->id;
  }
  else {
    return undef;
  }

  eval {
    $self->app->cache->delete($class . '-' . $id);
  }
    or return undef;

  $self->app->log->debug("drop_from_cache $class, $id");

  return $self;
}

sub get_from_cache {
  my $self  = shift;
  my $id    = shift;

  # кеш выключен до лучших времён
  $self->app->log->debug("Model cache is off");
  return undef;

  my $class = $self->cache_class or die "Only object can be loaded. $self";

  unless ($id) {
    if ($self->can('id') && $self->id) {
      $id = $self->id;
    }
    else {
      return undef;
    }
  }

  $self->app->log->debug("get_from_cache $class, $id");

  my $cached_value = eval {
    $self->app->cache->get($class . '-' . $id)
  }
    or return undef;

  my $model = $self->new($cached_value);

  # Убеждаем модель, что она уже есть в БД
  $model->model->in_storage(1);

  # Убеждаем модель, что она не менялась
  %{$model->model->{'_dirty_columns'}} = ();

  return $model;
}

sub store_to_cache {
  my $self  = shift;
  my $ttl   = shift;
  my $class = $self->cache_class or die "Only object can be stored. $self";

  my $id;

  if ($self->can('id') && $self->id) {
    $id = $self->id;
  }
  else {
    return undef;
  }

  eval {
    $self->app->cache->set(
      $class . '-' . $id,
      $self->to_hash,
      $ttl,
    );
  }
    or return undef;

  $self->app->log->debug("store_to_cache $class, $id");

  return $self;
}

1;
