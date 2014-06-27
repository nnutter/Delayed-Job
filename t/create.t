#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use Delayed::Job::Schema;

my $dbh = Delayed::Job::Schema->connect('dbi:Pg:dbname=delayed', '', '', { AutoCommit => 1 });

my $job = $dbh->resultset('Job')->create({command => 'echo hello'});
my $got = $dbh->resultset('Job')->find($job->id);
is(lc($got->id), lc($job->id), 'got job');
