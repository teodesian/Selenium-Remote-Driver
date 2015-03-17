#! /usr/bin/perl

use strict;
use warnings;
use Selenium::Firefox::Binary;
use Selenium::Chrome;
use Selenium::PhantomJS;
use Selenium::Firefox;
use Test::More;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);
my %caps = %{ $harness->base_caps };
delete $caps{browser_name};

PHANTOMJS: {
    my $phantom = Selenium::PhantomJS->new( %caps );
    is( $phantom->browser_name, 'phantomjs', 'binary phantomjs is okay');
    isnt( $phantom->port, 4444, 'phantomjs can start up its own binary');

    ok( Selenium::BinaryModeBuilder::probe_port( $phantom->port ), 'the phantomjs binary is listening on its port');
}

CHROME: {
    $ENV{PATH} .= ':/usr/local/lib/node_modules/protractor/selenium';
    my $chrome = Selenium::Chrome->new( %caps );
    ok( $chrome->browser_name eq 'chrome', 'convenience chrome is okay' );
    isnt( $chrome->port, 4444, 'chrome can start up its own binary');

    ok( Selenium::BinaryModeBuilder::probe_port( $chrome->port ), 'the chrome binary is listening on its port');
}

FIREFOX: {
    my $binary = Selenium::Firefox::Binary::firefox_path();
    ok(-x $binary, 'we can find some sort of firefox');

    my $command = Selenium::BinaryModeBuilder::_construct_command('firefox', 1234);
    ok($command =~ /firefox -no-remote/, 'firefox command has proper args');

    my $firefox = Selenium::Firefox->new;
    isnt( $firefox->port, 4444, 'firefox can start up its own binary');
    ok( Selenium::BinaryModeBuilder::probe_port( $firefox->port ), 'the firefox binary is listening on its port');
}

done_testing;
