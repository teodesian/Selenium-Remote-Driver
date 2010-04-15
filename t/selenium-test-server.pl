use strict;
use warnings;

use HTTP::Daemon;
use HTTP::Status;
use Data::Compare;
use JSON;

# Port where Selenium server listens
my $port = 4444;
my $daemon = HTTP::Daemon->new( LocalPort => $port )
  || die "Couldn't start HTTP server at $port ";
print "Server listening at: ", $daemon->url, "\n";

my $resource = {
    '/wd/hub/session' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/window_handle' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/window_handles' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/url' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/forward' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/back' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/refresh' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/execute' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/screenshot' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/frame' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/window' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/speed' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/cookie' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/cookie/foo-bar' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/source' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/title' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/elements' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/active' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/element' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/elements' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/click' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/submit' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/text' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/value' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/name' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/clear' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/selected' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/toggle' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/enabled' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/attribute/attrName' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/equals/otherElemID' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/displayed' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/location' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/location_in_view' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/size' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/css/propName' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/hover' => {
        'input'  =>,
        'output' =>,
    },
    '/wd/hub/session/123456789/element/elemID/drag' => {
        'input'  =>,
        'output' =>,
    },
};

my $json = new JSON;
while ( my $client = $daemon->accept ) {
    while ( my $request = $client->get_request ) {
        my $url = $request->uri->path;

        # Check if the resource is defined
        if ( !( defined $resource->{$url} ) ) {
            $client->send_error(404);
        }
        elsif ( $url eq '/wd/hub/session' ) {
            # our dummy session 123456789...
            my $rs = new HTTP::Response(303);
            $rs->header( 'Location' => 'http://localhost:4444/wd/hub/session/123456789' );
            my $resp = {
                'sessionId' => '123456789',
                'value'     => {
                    'browserName'       => 'firefox',
                    'version'           => '',
                    'javascriptEnabled' => JSON::true,
                    'class' => 'org.openqa.selenium.remote.DesiredCapabilities',
                    'platform' => 'ANY'
                },
                'status' => 0,
                'class'  => 'org.openqa.selenium.remote.Response'
            };
            my $json_data = $json->allow_nonref->utf8(1)->encode($resp);
            $rs->content($json_data);
            $client->send_response($rs);
        }
        else {
            my $rs = new HTTP::Response(200);
            my $json_data = '';
            if ( defined $resource->{$url}->{'input'} ) {
                my $post_data =
                  $json->allow_nonref->utf8(1)->decode( $request->content );
                if ( !( Compare( $post_data, $resource->{$url}->{'input'} ) ) )
                {
                    $rs->code(400);
                    $json_data = "";
                }
                else {
                    $json_data =
                      $json->allow_nonref->utf8(1)
                      ->encode( $resource->{$url}->{'output'} );
                }
            }
            $rs->header( 'Content-Type' => 'application/json; charset=utf-8' );
            $rs->content($json_data);
            $client->send_response($rs);
        }
    }

    # clean up
    $client->close();
    undef($client);
}
