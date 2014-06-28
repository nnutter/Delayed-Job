package Delayed::Job;

use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

sub create {
    my $class = shift;
    return bless { @_ }, $class;
}

sub run {
    my $self = shift;

    my $c = $self->{handler_class};
    my $d = $self->{handler_data};
    if ($d) {
        $c = bless $d, $c;
    }
    my $m = $self->{handler_method};
    my @a = @{ $self->{handler_args} };

    return $c->$m(@a);
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

