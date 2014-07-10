package Delayed;

use Carp qw(croak);
use Class::AutoloadCAN; # don't qw()!
use Delayed::Job qw();
use Module::Runtime qw(require_module);
use Sub::Install qw(install_sub);

sub import {
    shift;
    @_ = 'UNIVERSAL' unless @_;
    for my $class (@_) {
        require_module $class;
        install_sub({
            into => $class,
            as   => 'delay',
            code => sub {
                if (@_ != 1) {
                    croak 'delay should receive one argument';
                }
                my $handler = shift;
                my $d = do { \my $s };
                $$d = $handler;
                return bless $d, __PACKAGE__;
            },
        });
    }
}

sub CAN {
    my ($starting_class, $method, $self, @arguments) = @_;

    return unless ref($self) && ref($self)->isa('Delayed');

    my $handler = $$self;
    my $can = $handler->can($method);
    return unless $can;

    return sub {
        Delayed::Job->create($handler, $method, @arguments);
    };
}

1;
