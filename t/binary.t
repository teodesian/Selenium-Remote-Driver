#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Selenium::Binary;
use Selenium::Firefox::Binary;
use Selenium::Chrome;
use Selenium::PhantomJS;
use Selenium::Firefox;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);
my %caps = %{ $harness->base_caps };
delete $caps{browser_name};

PHANTOMJS: {
    my $ghost = Selenium::PhantomJS->new( %caps );
    is( $ghost->browser_name, 'phantomjs', 'binary phantomjs is okay');
    isnt( $ghost->port, 4444, 'phantomjs can start up its own binary');
}

CHROME: {
    $ENV{PATH} .= ':/usr/local/lib/node_modules/protractor/selenium';
    my $chrome = Selenium::Chrome->new( %caps );
    ok( $chrome->browser_name eq 'chrome', 'convenience chrome is okay' );
    isnt( $chrome->port, 4444, 'chrome can start up its own binary');
    $chrome->quit;
}

FIREFOX: {
    my $binary = Selenium::Firefox::Binary::path();
    ok(-x $binary, 'we can find some sort of firefox');

}

done_testing;
