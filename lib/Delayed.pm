package Delayed;

use Class::AutoloadCAN; # don't qw()!
use Data::Structure::Util qw(unbless);
use Delayed::Job qw();
use Module::Runtime qw(require_module);
use Storable qw(dclone);
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

    # dclone or the unbless causes side effects
    my $data = unbless(dclone($self->{parent}));

    my $handler_class = (ref($self->{parent}) || $self->{parent});
    my $handler_data = ref($data) ? $data : undef;

    return sub {
        Delayed::Job->create(
            handler_class  => $handler_class,
            handler_data   => $handler_data,
            handler_method => $method,
            handler_args   => \@arguments,
        )
    };
}

1;
