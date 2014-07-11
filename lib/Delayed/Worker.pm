package Delayed::Worker;

use strict;
use warnings;

use Carp qw(croak);
use Delayed::Job;
use POSIX qw(WNOHANG);
use Time::HiRes qw(time usleep);

sub execute {
    my $schema = Delayed::Job->_dbh();
    my @jobs = $schema->resultset('Job')->search(undef, {
        columns => [ 'id' ],
        rows => 5,
    });
    my @ids = map { $_->id } @jobs;
    my @pids;
    for my $id (@ids) {
        my $pid = fork();
        if (!defined($pid)) {
            croak 'failed to fork';
        }

        if ($pid == 0) {
            my $schema = Delayed::Job->_dbh();
            $schema->resultset('Job')->try_lock_do($id, sub {
                my $result = shift;
                $result->run();
            });;
            exit(0);
        } else {
            printf STDERR "PID %d spawned\n", $pid;
            push @pids, $pid;
        }

        while (@pids == 2) {
            usleep 100_000;
            my $pid = shift @pids;
            unless (waitpid($pid, WNOHANG) == $pid) {
                push @pids, $pid;
            } else {
                printf STDERR "PID %d returned\n", $pid;
            }
        }
    }
    while (@pids) {
        usleep 100_000;
        my $pid = shift @pids;
        unless (waitpid($pid, WNOHANG) == $pid) {
            push @pids, $pid;
        } else {
            printf STDERR "PID %d returned\n", $pid;
        }
    }
}

1;
