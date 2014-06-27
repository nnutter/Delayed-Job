package Delayed::Job::Schema::Result::Job;

use strict;
use warnings;

use parent 'DBIx::Class';
__PACKAGE__->load_components(qw(UUIDColumns Core));

__PACKAGE__->table('delayed.job');
__PACKAGE__->add_columns('id', 'command');
__PACKAGE__->uuid_columns('id');
__PACKAGE__->set_primary_key('id');

1;
