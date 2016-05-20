use utf8;
package App::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'users_id_seq'

=head2 ctime

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 password

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 32

=head2 password_salt

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 8

=head2 money

  data_type: 'numeric'
  is_nullable: 1
  size: [16,4]

=head2 is_deleted

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 data

  data_type: 'jsonb'
  is_nullable: 1

=head2 uid

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "users_id_seq",
  },
  "ctime",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "password",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 32 },
  "password_salt",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 8 },
  "money",
  { data_type => "numeric", is_nullable => 1, size => [16, 4] },
  "is_deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "data",
  { data_type => "jsonb", is_nullable => 1 },
  "uid",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<users_email_key>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("users_email_key", ["email"]);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-05-16 23:38:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UukP/XSjxqzDCECfwakE7A

__PACKAGE__->load_components('InflateColumn::Serializer');

__PACKAGE__->add_column(
  '+data' => {
    serializer_class => 'JSON',
  }
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
