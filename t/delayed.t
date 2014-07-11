#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use File::Spec qw();
use File::Temp qw();
use IO::File qw();

my $dir = File::Temp->newdir();
unshift @INC, $dir->dirname;

{
    my $filepath = File::Spec->join($dir->dirname, 'Foo.pm');
    my $file = IO::File->new($filepath, 'w');
    $file->print(join("\n",
        'package Foo;',
        '1;',
    ), "\n");
    $file->close();
}

{
    my $filepath = File::Spec->join($dir->dirname, 'Qux.pm');
    my $file = IO::File->new($filepath, 'w');
    $file->print(join("\n",
        'package Qux;',
        'sub delay { return q(Qux) }',
        '1;',
    ), "\n");
    $file->close();
}

subtest 'initially' => sub {
    plan tests => 4;

    eval 'use Qux';
    ok(!Bar->can('delay'), q(Bar can't delay yet));
    ok(!Foo->can('delay'), q(Foo can't delay yet));
    ok(Qux->can('delay'), q(Qux can delay));
    ok(!$INC{'Delayed.pm'}, q(even though Delayed hasn't been loaded));
};


subtest q(after 'use Delayed qw(Foo)') => sub {
    plan tests => 3;
    eval 'use Delayed qw(Foo)';
    ok(!Bar->can('delay'), q(Bar still can't delay));
    ok(Foo->can('delay'), 'but now Foo can');
    isnt(Qux->can('delay'), Foo->can('delay'), 'and Qux and Foo still have different delays');
};

subtest q(after 'use Delayed') => sub {
    plan tests => 4;
    eval 'use Delayed';
    ok(Bar->can('delay'), 'now Bar can delay too');
    ok(Foo->can('delay'), 'and Foo still can as well');
    is(Bar->can('delay'), Foo->can('delay'), 'Bar and Foo have the same delay');
    isnt(Qux->can('delay'), Foo->can('delay'), 'and Qux and Foo still have different delays');
};

subtest q(after 'use Delayed qw(Qux)') => sub {
    eval 'use Delayed qw(Qux)';
    is(Qux->can('delay'), Foo->can('delay'), q(now Qux's delay has been redefined to Foo's));
};
