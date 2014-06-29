package Delayed::Job::Schema::Result::Job;

use strict;
use warnings;

use parent 'DBIx::Class';

use Data::Structure::Util qw(unbless);
use JSON qw(encode_json decode_json);
use Storable qw(dclone);

__PACKAGE__->load_components(qw(UUIDColumns Core));

__PACKAGE__->table('delayed.job');
__PACKAGE__->add_columns(qw(
    id
    handler_class
    handler_data
    handler_method
    handler_args
));
__PACKAGE__->uuid_columns('id');
__PACKAGE__->set_primary_key('id');

sub run {
    my $self = shift;
    my $handler = $self->deserialize_handler;
    my $method  = $self->{handler_method};
    my @args    = $self->deserialize_args;
    return $handler->$method(@args);
}

sub serialize_handler {
    my $class = shift;
    my $handler = shift;

    if ($handler->can('serialize_handler')) {
        return $handler->serialize_handler;
    }

    my $handler_class = (ref($handler) || $handler);
    my $handler_data;
    if (ref($handler)) {
        $handler_data = encode_json(unbless(dclone($handler)));
    }

    return ($handler_class, $handler_data);
}

sub deserialize_handler {
    my $self = shift;

    my $handler_class = $self->{handler_class};
    my $handler_data  = $self->{handler_data};

    if ($handler_class->can('deserialize_handler')) {
        return $handler_class->deserialize_handler($handler_data);
    }

    my $d = decode_json($handler_data);
    return bless $d, $handler_class;
}

sub serialize_args {
    my $class = shift;
    return encode_json(\@_);
}

sub deserialize_args {
    my $self = shift;
    return decode_json($self->{handler_args});
}

1;
