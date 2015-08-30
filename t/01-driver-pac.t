#! /usr/bin/perl

use strict;
use warnings;
use JSON;
use Selenium::Remote::Driver;
use Test::More;
use Test::Fatal;
use Test::LWP::UserAgent;

my $croaking_tests = [
    {
        name => 'no PAC url',
        proxy => {
            proxyType => 'pac',
        },
        pattern => qr/not provided/,
    },
    {
        name => 'PAC url is not http or file',
        proxy => {
            proxyType => 'pac',
            proxyAutoconfigUrl => ''
        },
        pattern => qr{of format http:// or file://}
    }
];

foreach my $test (@$croaking_tests) {
    like(
        exception {
            Selenium::Remote::Driver->new(proxy => $test->{proxy});
        },
        $test->{pattern},
        'Coercion croaks for case: ' . $test->{name}
    );
}

my $passing_tests = [
    {
        name => 'PAC url is http',
        proxy => {
            proxyType => 'pac',
            proxyAutoconfigUrl => 'http://pac.file'
        }
    },
    {
        name => 'PAC url is file',
        proxy => {
            proxyType => 'pac',
            proxyAutoconfigUrl => 'file://' . __FILE__
        }
    }
];

my $tua = mock_simple_webdriver_server();
foreach my $test (@$passing_tests) {
    is(
        exception {
            Selenium::Remote::Driver->new(
                proxy => $test->{proxy},
                ua => $tua
            );
        },
        undef,
        'Coercion passes for case: ' . $test->{name}
    );
}

sub mock_simple_webdriver_server {
    my $tua = Test::LWP::UserAgent->new;
    $tua->map_response(qr/status/, HTTP::Response->new(200, 'OK'));
    $tua->map_response(
        qr/session/,
        HTTP::Response->new(
            204,
            'OK',
            ['Content-Type' => 'application/json'],
            to_json({
                cmd_return => {},
                cmd_status => 'OK',
                sessionId => '123123123'
            })
        )
    );

    return $tua;
}

done_testing;
