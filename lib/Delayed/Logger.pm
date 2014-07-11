package Delayed::Logger;

use parent 'Log::Dispatch';

use Carp qw();
use Log::Dispatch qw();
use Log::Dispatch::Screen qw();
use Module::Runtime qw(module_notional_filename use_package_optimistically);
use Sub::Install qw(install_sub);

sub new {
    my $class = shift;
    my %options = @_;

    my %screen_opts;
    if (defined $options{min_level}) {
        $screen_opts{min_level} = delete $options{min_level};
    } else {
        $screen_opts{min_level} = 'info';
    }

    my $logger = $class->SUPER::new(%options);

    if (should_color_screen()) {
        $logger->add(color_screen(%screen_opts));
    } else {
        $logger->add(screen(%screen_opts));
    }

    return $logger;
}

sub should_color_screen {
    return -t STDERR && has_color_screen_package();
}

sub has_color_screen_package {
    # Log::Dispatch::Screen::Color is not a "core" Log::Dispatch module
    my $name = use_package_optimistically('Log::Dispatch::Screen::Color');
    my $file = module_notional_filename($name);
    return $INC{$file};
}

sub screen {
    return Log::Dispatch::Screen->new(name => 'screen', @_);
}

sub color_screen {
    my $screen = Log::Dispatch::Screen::Color->new(@_,
        name => 'screen',
        color => {
            debug => {
                text => 'magenta',
            },
            info => {}, # override default
            notice => {
                text => 'blue',
            },
            warning => {
                text => 'yellow',
            },
            error => {
                text => 'red',
            },
            critical => {
                text => 'red',
            },
            alert => {
                text => 'red',
            },
            emergency => {
                text => 'red',
            },
        },
    );
}

my @levels = keys %Log::Dispatch::LEVELS;
for my $level (@levels) {
    my $levelf = $level . 'f';
    install_sub({
        into => 'Delayed::Logger',
        as   => $level,
        code => sub {
            my $self = shift;
            my $message = "@_";
            chomp $message;
            $message .= "\n";
            my $m = "SUPER::$level";
            $self->$m($message);
        },
    });
    install_sub({
        into => 'Delayed::Logger',
        as   => $levelf,
        code => sub {
            my $self = shift;
            my $message = sprintf(shift, @_);
            $self->$level($message);
        },
    });
}

install_sub({
    into => 'Delayed::Logger',
    as   => 'fatal',
    code => sub {
        my $self = shift;
        $self->critical("@_");
        Carp::croak "@_";
    },
});

install_sub({
    into => 'Delayed::Logger',
    as   => 'fatalf',
    code => sub {
        my $self = shift;
        my $message = sprintf(shift, @_);
        $self->critical($message);
        Carp::croak $message;
    },
});

1;
