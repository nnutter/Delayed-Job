#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use Delayed::Command;
use Delayed::Job::Schema;

my $dbh = Delayed::Job::Schema->connect('dbi:Pg:dbname=delayed', '', '', { AutoCommit => 1 });

my $cmd = Delayed::Command->create(qw(echo hello));
my $job = $cmd->delay->capture;
my $got = $dbh->resultset('Job')->find($job->id);
is(lc($got->id), lc($job->id), 'got job');
is($got->run, $job->run, 'output matched');
