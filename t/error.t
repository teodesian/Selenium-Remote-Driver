#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::Socket::INET;


BEGIN: {
    unless (use_ok('Selenium::Remote::Driver')) {
        BAIL_OUT("Couldn't load Selenium::Remote::Driver");
        exit;
    }
}

LOCAL: {
    throws_ok(
        sub {
            Selenium::Remote::Driver->new_from_caps( port => 80 );
        }, qr/Selenium server did not return proper status/,
        'Error message for not finding a selenium server is helpful'
    );
}

SAUCE: {
  SKIP: {
        my $host = 'ondemand.saucelabs.com';
        my $port = 80;
        my $sock = IO::Socket::INET->new(
            PeerAddr => $host,
            PeerPort => $port,
        );

        skip 'Cannot reach saucelabs for Sauce error case ', 1
          unless $sock;

        throws_ok(
            sub {
                Selenium::Remote::Driver->new_from_caps(
                    remote_server_addr => $host,
                    port => $port,
                    desired_capabilities => {
                        browserName => 'invalid'
                    }
                );
            }, qr/Sauce Labs/, 'Saucelabs errors are passed to user');

    }
}
done_testing;
