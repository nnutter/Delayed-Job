package Delayed::Job::Schema::Result::Job;

use strict;
use warnings;

use parent 'DBIx::Class';

use JSON qw(encode_json decode_json);
use Module::Runtime qw(require_module);
use Storable qw(dclone);
use Time::Piece qw();

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
),
    attempts   => { default_value => sub { 1 } },
    run_at     => { default_value => sub { Time::Piece->new() } },
    created_at => { default_value => sub { Time::Piece->new() } },
);
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

for my $column (qw(run_at failed_at created_at)) {
    __PACKAGE__->inflate_column($column, {
        inflate => sub { Time::Piece->new($_[0]) },
        # SQL style timestamp
        deflate => sub { $_[0]->strftime('%m/%d/%Y %T.00 %Z') },
    });
}

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    if (defined $self->created_at) {
        warn 'created_at should not be set manually';
    }
    for my $column ($self->result_source->columns) {
        my $default = $self->result_source->column_info($column)->{default_value};
        if (!defined($self->$column) && $default) {
            my $default_value = $default->();
            $self->$column($default_value);
        }
    }
    return $self;
}

sub run {
    my $self = shift;
    my $handler = $self->handler;
    my $method  = $self->method;
    my @args    = @{ $self->args };

    $self->attempts($self->attempts - 1);
    my $rv = eval { $handler->$method(@args) };
    if ($rv) {
        $self->delete;
    } elsif ($self->attempts <= 0) {
        $self->failed_at(Time::Piece->new());
    }
    return $rv;
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
