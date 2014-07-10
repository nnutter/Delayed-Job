package Delayed::Job::Schema::Result::Job;

use strict;
use warnings;

use parent 'DBIx::Class';

use Data::Structure::Util qw(unbless);
use JSON qw(encode_json decode_json);
use Storable qw(dclone);

__PACKAGE__->load_components(qw(UUIDColumns Core InflateColumn));

__PACKAGE__->table('delayed.job');
__PACKAGE__->add_columns(qw(
    id
    handler
    method
    args
));
__PACKAGE__->uuid_columns('id');
__PACKAGE__->set_primary_key('id');

__PACKAGE__->inflate_column('handler', {
    inflate => sub {
        my $result_object = pop;
        my $json = shift;
        return _deserialize_handler($json);
    },
    deflate => sub {
        my $result_object = pop;
        my $handler = shift;
        return _serialize_handler($handler);
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
        my $handler = $result_object->handler;
        if ($handler->can('serialize_args')) {
            return $handler->serialize_args(\@_);
        }
        return encode_json(\@_);
    },
});

sub run {
    my $self = shift;
    my $handler = $self->handler;
    my $method  = $self->method;
    my @args    = @{ $self->args };
    return $handler->$method(@args);
}

sub _serialize_handler {
    my $handler = shift;

    my $handler_data;
    if (ref($handler)) {
        if ($handler->can('serialize_handler')) {
            $handler_data = $handler->serialize_handler;
        } else {
            $handler_data = unbless(dclone($handler));
        }
    }
    my $handler_class = (ref($handler) || $handler);

    return encode_json({
        class => $handler_class,
        data  => $handler_data,
    });
}

sub _deserialize_handler {
    my $json = shift;

    my $data = decode_json($json);
    my $handler_class = $data->{class};
    if ($handler_class->can('deserialize_handler')) {
        return $handler_class->deserialize_handler($data);
    }

    my $handler_data  = $data->{data};
    if ($handler_data && ref($handler_data)) {
        return bless $handler_data, $handler_class;
    } else {
        return $handler_class;
    }
}

1;
