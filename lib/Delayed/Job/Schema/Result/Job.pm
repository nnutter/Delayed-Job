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
));
__PACKAGE__->uuid_columns('id');
__PACKAGE__->set_primary_key('id');

__PACKAGE__->inflate_column('handler_data', {
    inflate => sub {
        my $result_object = pop;
        my $json = shift;
        if ($result_object->handler_class->can('deserialize_handler')) {
            return $result_object->handler_class->deserialize_handler($json);
        }
        return decode_json($json);
    },
    deflate => sub {
        my $result_object = pop;
        my $handler_data = shift;
        if ($result_object->handler_class->can('serialize_handler')) {
            return $result_object->handler_class->serialize_handler($handler_data);
        }
        return encode_json($handler_data);
    },
});

__PACKAGE__->inflate_column('args', {
    inflate => sub {
        my $result_object = pop;
        my $json = shift;
        my $handler = $result_object->handler;
        if ($handler->can('deserialize_args')) {
            return $handler->deserialize_args($json);
        }
        return decode_json($json);
    },
    deflate => sub {
        my $result_object = pop;
        my $args = shift;
        my $handler = $result_object->handler;
        if ($handler->can('serialize_args')) {
            return $handler->serialize_args($args);
        }
        return encode_json($args);
    },
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

1;
