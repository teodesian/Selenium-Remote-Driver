#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::Mock::RemoteConnection;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);
my %selenium_args = %{ $harness->base_caps };

# Try to find
my $t = Test::Selenium::Remote::Driver->new(
    %selenium_args
);
$t->get_ok('http://www.google.com');
$t->title_like(qr/Google/);
$t->body_like(qr/Google/);

done_testing();
