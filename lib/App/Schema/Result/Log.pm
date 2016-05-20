use utf8;
package App::Schema::Result::Log;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::Schema::Result::Log

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<logs>

=cut

__PACKAGE__->table("logs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'logs_id_seq'

=head2 ctime

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 object_class

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 object_id

  data_type: 'integer'
  is_nullable: 1

=head2 user_class

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 action

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 data

  data_type: 'jsonb'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "logs_id_seq",
  },
  "ctime",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "object_class",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "object_id",
  { data_type => "integer", is_nullable => 1 },
  "user_class",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "action",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "data",
  { data_type => "jsonb", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-05-16 23:02:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lXofClyjZwawgioY3I/zzw

__PACKAGE__->load_components('InflateColumn::Serializer');

__PACKAGE__->add_column(
  '+data' => {
    serializer_class => 'JSON',
  }
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
