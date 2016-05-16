use utf8;
package App::Schema::Result::AdminUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::Schema::Result::AdminUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<admin_users>

=cut

__PACKAGE__->table("admin_users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'admin_users_id_seq'

=head2 ctime

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 login

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 email

  data_type: 'varchar'
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
    sequence          => "admin_users_id_seq",
  },
  "ctime",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "login",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "password",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 32 },
  "password_salt",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 8 },
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

=head1 UNIQUE CONSTRAINTS

=head2 C<admin_users_email_key>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("admin_users_email_key", ["email"]);

=head2 C<admin_users_login_key>

=over 4

=item * L</login>

=back

=cut

__PACKAGE__->add_unique_constraint("admin_users_login_key", ["login"]);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-05-16 23:02:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b7TdW8dguGtKVRmsTeK2eg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
