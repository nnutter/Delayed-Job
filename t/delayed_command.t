#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use Test::Fatal qw(exception);

use Delayed::Command;
use Delayed::Job::Schema;

subtest 'retrieved and ran a persisted, delayed command object' => sub {
    plan tests => 2;
    my $cmd = Delayed::Command->create(qw(echo hello));
    my $job = $cmd->delay->capture;
    my $got = Delayed::Job->find($job->id);
    is(lc($got->id), lc($job->id), 'got job');
    is($got->run, $job->run, 'output matched');
};

subtest 'retrieved and ran a persisted, delayed command class' => sub {
    plan tests => 2;
    my $job = Delayed::Command->delay->capture(qw(echo hello));
    my $got = Delayed::Job->find($job->id);
    is(lc($got->id), lc($job->id), 'got job');
    is($got->run, $job->run, 'output matched');
};

subtest 'exception thrown when trying to delay an invalid method' => sub {
    plan tests => 2;
    my $cmd = Delayed::Command->create(qw(echo hello));
    my $m = 'foo';
    ok(!$cmd->can($m), qq(command cannot '$m'));
    my $e = exception { $cmd->delay->$m };
    ok($e, 'got an exception');
};
