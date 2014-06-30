package Delayed;

use Class::AutoloadCAN; # don't qw()!
use Delayed::Job qw();
use Module::Runtime qw(require_module);
use Sub::Install qw(install_sub);

sub import {
    shift;
    for my $class (@_) {
        require_module $class;
        install_sub({
            into => $class,
            as   => 'delay',
            code => sub {
                return bless { parent => $_[0] }, __PACKAGE__;
            },
        });
    }
}

sub CAN {
    my ($starting_class, $method, $self, @arguments) = @_;

    return unless ref($self) && ref($self)->isa('Delayed');

    my $can = $self->{parent}->can($method);
    return unless $can;

    return sub {
        Delayed::Job->create($self->{parent}, $method, @arguments);
    };
}

1;
