package Delayed::Worker;

# TODO
# - How should we handle logger (and handler prints) in multi-process?

use strict;
use warnings;

use Delayed::Logger;
use Delayed::Job;
use POSIX qw(WNOHANG);
use Time::HiRes qw(time usleep);

sub new {
    my $class = shift;
    my %options = @_;

    my $self = bless {}, $class;

    my %logger_opts;
    if ($options{"log-level"}) {
        $logger_opts{min_level} = $options{"log-level"};
    }
    $self->{logger} = Delayed::Logger->new(%logger_opts);

    if (defined $options{workers}) {
        $self->{workers} = delete $options{workers};
    } else {
        $self->{workers} = 1;
    }

    if (defined $options{queue}) {
        $self->{queue} = delete $options{queue};
    }

    return $self;
}

sub logger { shift->{logger} }
sub queue { shift->{queue} }
sub workers { shift->{workers} }

sub start {
    my $self = shift;

    my $schema = Delayed::Job->_dbh();
    my $query = {
        columns => [ 'id' ],
        rows => 5,
    };
    my @jobs = $schema->resultset('Job')->search(undef, $query);
    my @ids = map { $_->id } @jobs;
    my @pids;
    for my $id (@ids) {
        my $pid = fork();
        if (!defined($pid)) {
            $self->logger->fatal('failed to fork');
        }

        if ($pid == 0) {
            my $schema = Delayed::Job->_dbh();
            $schema->resultset('Job')->try_lock_do($id, sub {
                my $result = shift;
                $result->run();
            });;
            exit(0);
        } else {
            $self->logger->debugf("PID %d spawned\n", $pid);
            push @pids, $pid;
        }

        while (@pids == $self->workers) {
            usleep 100_000;
            my $pid = shift @pids;
            unless (waitpid($pid, WNOHANG) == $pid) {
                push @pids, $pid;
            } else {
                $self->logger->debugf("PID %d returned\n", $pid);
            }
        }
    }
    while (@pids) {
        usleep 100_000;
        my $pid = shift @pids;
        unless (waitpid($pid, WNOHANG) == $pid) {
            push @pids, $pid;
        } else {
            $self->logger->debugf("PID %d returned\n", $pid);
        }
    }
}

1;
