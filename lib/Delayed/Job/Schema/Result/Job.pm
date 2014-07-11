package Delayed::Job::Schema::Result::Job;

use strict;
use warnings;

use parent 'DBIx::Class';

use JSON qw(encode_json decode_json);
use Module::Runtime qw(require_module);
use Storable qw(dclone);

__PACKAGE__->load_components(qw(UUIDColumns Core InflateColumn));

__PACKAGE__->table('delayed.job');
__PACKAGE__->add_columns(qw(
    id
    handler_class
    method
    handler_data
    args
    queue
    priority
    failed_at
    attempts,
    run_at,
    created_at,
));
__PACKAGE__->uuid_columns('id');
__PACKAGE__->set_primary_key('id');

__PACKAGE__->inflate_column('handler_data', {
    inflate => _delegate_or_default('inflate_handler_data', \&JSON::decode_json),
    deflate => _delegate_or_default('deflate_handler_data', \&JSON::encode_json),
});

__PACKAGE__->inflate_column('args', {
    inflate => _delegate_or_default('inflate_args', \&JSON::decode_json),
    deflate => _delegate_or_default('deflate_args', \&JSON::encode_json),
});

sub run {
    my $self = shift;
    my $handler = $self->handler;
    my $method  = $self->method;
    my @args    = @{ $self->args };
    return $handler->$method(@args);
}

sub handler {
    my $self = shift;
    require_module $self->handler_class;
    if ($self->handler_data) {
        return bless dclone($self->handler_data), $self->handler_class;
    }
    return $self->handler_class;
}

sub _delegate_or_default {
    my $delegate_method = shift;
    my $default_method = shift;
    return sub {
        my ($data, $job) = @_;
        if ($job->handler_class->can($delegate_method)) {
            return $job->handler_class->$delegate_method($data);
        }
        return $default_method->($data);
    }
}

1;
