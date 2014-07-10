package Delayed::Job;

use 5.008001;
use strict;
use warnings;

use Delayed::Job::Schema qw();

our $VERSION = "0.01";

sub create {
    my $class = shift;
    my ($handler, $method, @args) = @_;

    my $self = _dbh()->resultset('Job')->create({
        handler => $handler,
        method  => $method,
        args    => \@args,
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

