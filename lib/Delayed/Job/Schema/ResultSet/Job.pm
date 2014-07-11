package Delayed::Job::Schema::ResultSet::Job;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Carp qw(croak);

sub try_lock_do {
    my $self = shift;
    my $id = shift;
    my $block = shift;
    my $timeout = shift || 100;

    my $txn_depth = $self->result_source->storage->transaction_depth;
    if ($txn_depth) {
        croak 'timeout will abort transation';
    }

    my $schema = $self->result_source->schema;
    $schema->txn_begin;
    $schema->storage->dbh_do(\&_set_txn_statement_timeout, $timeout);
    my $result = eval {
        $self->SUPER::find($id, {
            for => 'update',
        });
    };
    if ($result) {
        $block->($result);
        $schema->txn_commit;
    } else {
        $schema->txn_rollback;
    }
}

sub _set_txn_statement_timeout {
    my ($storage, $dbh, $timeout) = @_;
    $dbh->do(qq(SET LOCAL statement_timeout TO $timeout;));
}

1;
