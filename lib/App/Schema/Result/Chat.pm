use utf8;
package App::Schema::Result::Chat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::Schema::Result::Chat

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<chats>

=cut

__PACKAGE__->table("chats");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'chats_id_seq'

=head2 ctime

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 chat_id

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 link

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 256

=head2 is_deleted

  data_type: 'boolean'
  default_value: false
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
    sequence          => "chats_id_seq",
  },
  "ctime",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "chat_id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "link",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 256 },
  "is_deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "data",
  { data_type => "jsonb", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-05-23 23:59:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GTYZdImmqSVdgxkC6wh+Og


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
