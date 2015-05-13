#! /usr/bin/perl

use strict;
use warnings;
use Selenium::Chrome;
use Selenium::Firefox;
use Selenium::InternetExplorer;
use Selenium::PhantomJS;
use Test::More;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);

my %caps = %{ $harness->base_caps };
$caps{remote_server_addr} = '127.0.0.1';
delete $caps{browser_name};

my $firefox = Selenium::Firefox->new( %caps );
ok( $firefox->browser_name eq 'firefox', 'convenience firefox is okay' );
$firefox->quit;

my $chrome = Selenium::Chrome->new( %caps );
ok( $chrome->browser_name eq 'chrome', 'convenience chrome is okay' );
$chrome->quit;

SKIP: {
    skip 'Can only test IE on windows', 1 unless $^O eq 'MSWin32';

    my $ie = Selenium::InternetExplorer->new( %caps );
    ok( $ie->browser_name eq 'internet_explorer', 'convenience ie is okay' );
    $ie->quit;
}

done_testing;
