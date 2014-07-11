package Delayed::Command;

use strict;
use warnings;

use Delayed;
use IPC::System::Simple qw();

sub create {
    my $class = shift;
    my @command = @_;
    return bless \@command, $class;
}

sub system { CORE::system(_args(@_)) == 0 }
sub run { IPC::System::Simple::run(_args(@_)) == 0 }
sub capture { IPC::System::Simple::capture(_args(@_)); $? == 0 }

sub _args {
    my $class = shift;
    if (ref($class)) {
        return @$class;
    } else {
        return @_;
    }
}

1;
