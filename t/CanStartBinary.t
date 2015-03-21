#! /usr/bin/perl

use strict;
use warnings;
use File::Which qw/which/;
use Selenium::Firefox::Binary;
use Selenium::Chrome;
use Selenium::PhantomJS;
use Selenium::Firefox;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan skip_all => "Author tests not required for installation.";
}

PHANTOMJS: {
  SKIP: {
        my $has_phantomjs = which('phantomjs');
        skip 'Phantomjs binary not found in path', 3
          unless $has_phantomjs;

        skip 'PhantomJS binary not found in path', 3
          unless is_proper_phantomjs_available();

        my $phantom = Selenium::PhantomJS->new;
        is( $phantom->browser_name, 'phantomjs', 'binary phantomjs is okay');
        isnt( $phantom->port, 4444, 'phantomjs can start up its own binary');

        ok( Selenium::CanStartBinary::probe_port( $phantom->port ), 'the phantomjs binary is listening on its port');
    }
}

CHROME: {
  SKIP: {
        my $has_chromedriver = which('chromedriver');
        skip 'Chrome binary not found in path', 3
          unless $has_chromedriver;

        my $chrome = Selenium::Chrome->new;
        ok( $chrome->browser_name eq 'chrome', 'convenience chrome is okay' );
        isnt( $chrome->port, 4444, 'chrome can start up its own binary');

        ok( Selenium::CanStartBinary::probe_port( $chrome->port ), 'the chrome binary is listening on its port');
    }
}

FIREFOX: {
    my $command = Selenium::CanStartBinary::_construct_command('firefox', 1234);
    ok($command =~ /firefox -no-remote/, 'firefox command has proper args');

  SKIP: {
        my $binary = Selenium::Firefox::Binary::firefox_path();
        skip 'Firefox binary not found in path', 3
          unless $binary;

        ok(-x $binary, 'we can find some sort of firefox');

        my $firefox = Selenium::Firefox->new;
        isnt( $firefox->port, 4444, 'firefox can start up its own binary');
        ok( Selenium::CanStartBinary::probe_port( $firefox->port ), 'the firefox binary is listening on its port');
    }
}

sub is_proper_phantomjs_available {
    my $ver = `phantomjs -v` // '';
    chomp $ver;

    $ver =~ s/^(\d\.\d).*/$1/;
    return $ver >= 1.9;
}

done_testing;
