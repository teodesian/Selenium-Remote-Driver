#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Fatal;
use Selenium::Waiter;


SIMPLE_WAIT: {
    my $ret;
    waits_ok( sub { $ret = wait_until { 1 } }, '<', 2, 'immediately true returns quickly' );
    ok($ret == 1, 'return value for a true wait_until is passed up');
    waits_ok( sub { $ret = wait_until { 0 } timeout => 3 }, '>', 2, 'never true expires the timeout' );
    ok($ret eq '', 'return value for a false wait is an empty string');
}

EVENTUALLY: {
    my $ret = 0;
    waits_ok( sub { wait_until { $ret++ > 2 } }, '>', 2, 'eventually true takes time');

    $ret = 0;
    my %opts = ( interval => 2, timeout => 5 );
    waits_ok(
        sub { wait_until { $ret++; 0 } %opts }, '>', 5,
        'timeout is respected'
    );
    ok($ret == 3, 'interval option changes iteration speed');
}

EXCEPTIONS: {
    my %opts = ( timeout => 2 );
    warning_is { wait_until { die 'caught!' } %opts } 'caught!',
      'exceptions usually only warn once';

    my %debug = ( debug => 1, %opts );
    warnings_are { wait_until { die 'caught!' } %debug } ['caught!', 'caught!'],
      'exceptions warn repreatedly when in debug mode';
}

sub waits_ok  {
    my ($sub, $cmp, $expected_duration, $test_desc) = @_;

    my $start = time;
    $sub->();
    my $elapsed = time - $start;

    cmp_ok($elapsed, $cmp, $expected_duration, $test_desc);
}

done_testing;
