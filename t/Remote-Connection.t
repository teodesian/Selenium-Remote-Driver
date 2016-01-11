use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::LWP::UserAgent;

BEGIN: {
    unless (use_ok('Selenium::Remote::RemoteConnection')) {
        BAIL_OUT("Couldn't load Selenium::Remote::RemoteConnection");
        exit;
    }
}

REDIRECT: {
    my $tua = Test::LWP::UserAgent->new(
        max_redirect => 0
    );

    $tua->map_response(qr/redirect/, HTTP::Response->new(303, undef, ['Location' => 'http://localhost/elsewhere']));
    $tua->map_response(qr/elsewhere/, HTTP::Response->new(200, 'OK', undef, ''));

    my $conn = Selenium::Remote::RemoteConnection->new(
        remote_server_addr => 'localhost',
        port => '',
        ua => $tua
    );

    my $redirect_endpoint = {
        method => 'GET',
        url => 'http://localhost/redirect'
    };

    is( exception { $conn->request($redirect_endpoint) }, undef,
        '303 redirects no longer kill us');
}

WD_CONTEXT: {
    my $tua = Test::LWP::UserAgent->new;
    my $hit_custom_context = 0;
    my $response = sub {
        is($_[0]->uri, 'http://addr:port/test/anything', 'can construct url with custom wd_context' );
        $hit_custom_context++;
        return HTTP::Response->new(200, 'OK', undef, '')
    };
    $tua->map_response(qr/test/, $response);

    my $conn = Selenium::Remote::RemoteConnection->new(
        remote_server_addr => 'addr',
        port => 'port',
        wd_context_prefix => '/test',
        ua => $tua
    );

    my $endpoint = { method => 'GET', url => 'anything' };

    $conn->request($endpoint);
    ok($hit_custom_context, 'wd_context is set up properly');
}


done_testing;
