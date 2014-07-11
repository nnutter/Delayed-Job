#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

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

subtest 'failure state gets set' => sub {
    plan tests => 4;
    my $job = Delayed::Command->delay->capture('false');
    is($job->attempts, 1, 'defaulted to one attempt');
    ok(!$job->failed_at, 'failed_at is not set');
    $job->run;
    is($job->attempts, 0, 'attempts was decremented to zero');
    ok($job->failed_at, 'failed_at is set');
    $job->delete;
};

subtest 'success deleted job' => sub {
    plan tests => 2;
    my $job = Delayed::Command->delay->capture(qw(echo hello));
    ok(Delayed::Job->find($job->id), 'got job');
    $job->run;
    ok(!Delayed::Job->find($job->id), 'job is gone');
};
