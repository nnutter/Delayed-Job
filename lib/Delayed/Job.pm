package Delayed::Job;

use 5.008001;
use strict;
use warnings;

use Delayed::Job::Schema qw();

our $VERSION = "0.01";

sub create {
    my $class = shift;
    my ($handler, $handler_method, @args) = @_;

    my ($handler_class, $handler_data) = Delayed::Job::Schema::Result::Job->serialize_handler($handler);
    my $handler_args = Delayed::Job::Schema::Result::Job->serialize_args($handler_class, @args);

    my $self = _dbh()->resultset('Job')->create({
        handler_class  => $handler_class,
        handler_data   => $handler_data,
        handler_method => $handler_method,
        handler_args   => $handler_args,
    });

    return $self;
}

sub find {
    my $class = shift;
    my $id = shift;
    my $self = _dbh()->resultset('Job')->find($id);
    return $self;
}

sub _dbh {
    my $dbh = Delayed::Job::Schema->connect('dbi:Pg:dbname=delayed', '', '', { AutoCommit => 1 });
    return $dbh;
}

1;
__END__

=encoding utf-8

=head1 NAME

Delayed::Job - It's new $module

=head1 SYNOPSIS

    use Delayed::Job;

=head1 DESCRIPTION

Delayed::Job is ...

=head1 LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nathaniel Nutter E<lt>iam@nnutter.comE<gt>

=cut

