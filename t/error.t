#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::LWP::UserAgent;
use IO::Socket::INET;


BEGIN: {
    unless (use_ok('Selenium::Remote::Driver')) {
        BAIL_OUT("Couldn't load Selenium::Remote::Driver");
        exit;
    }
}

UNAVAILABLE_BROWSER: {
    my $tua = Test::LWP::UserAgent->new;

    $tua->map_response(qr{status}, HTTP::Response->new(200, 'OK'));
    $tua->map_response(qr{session}, HTTP::Response->new(
        500,
        'Internal Server Error',
        ['Content-Type' => 'application/json'],
        '{"status":13,"sessionId":null,"value":{"message":"The path to..."} }'
    ));

    throws_ok(
        sub {
            Selenium::Remote::Driver->new_from_caps(
                ua => $tua,
                desired_capabilities => {
                    browserName => 'chrome'
                }
            );
        }, qr/Could not create new session.*path to/,
        'Errors in browser configuration are passed to user'
    );
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
