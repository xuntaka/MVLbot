use utf8;
package App::Schema::Result::House;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::Schema::Result::House

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<houses>

=cut

__PACKAGE__->table("houses");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'houses_id_seq'

=head2 pid

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 ctime

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 64

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
    sequence          => "houses_id_seq",
  },
  "pid",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "ctime",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 64 },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-06-11 00:57:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OmMJAx46fVrsWjmk/VmUeA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
