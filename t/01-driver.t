use strict;
use warnings;

use JSON;
use Test::More;
use LWP::UserAgent;
use Test::LWP::UserAgent;
use IO::Socket::INET;
use Selenium::Remote::Driver;
use Selenium::Remote::Mock::Commands;
use Selenium::Remote::Mock::RemoteConnection;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;
use Test::Fatal;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);
my %selenium_args = %{ $harness->base_caps };

my $driver = Selenium::Remote::Driver->new(%selenium_args);
my $website = 'http://localhost:63636';
my $ret;

my $chrome;
eval { $chrome = Selenium::Remote::Driver->new(
    %selenium_args,
    browser_name => 'chrome'
); };

DESIRED_CAPABILITIES: {
    # We're using a different test method for these because we needed
    # to inspect payload of the POST to /session, and the method of
    # recording the RES/REQ pairs doesn't provide any easy way to do
    # that.
    my $tua = Test::LWP::UserAgent->new;
    my $res = {
        cmd_return => {},
        cmd_status => 'OK',
        sessionId => '123124123'
    };

    $tua->map_response(qr{status}, HTTP::Response->new(200, 'OK'));

    my $requests_count = 0;
    my $mock_session_handler = sub {
        my $request = shift;
        $requests_count++;

        if ($request->method eq 'POST') {
            my $caps = from_json($request->decoded_content)->{desiredCapabilities};

            my @keys = keys %$caps;
            if (scalar @keys) {
                ok(scalar @keys == 2, 'exactly 2 keys passed in if we use desired_capabilities');

                my $grep = grep { 'browserName' eq $_ } @keys;
                ok($grep, 'and it is the right one');
                ok($caps->{superfluous} eq 'thing', 'and we pass through anything else');
                ok($caps->{browserName} eq 'firefox', 'and we override the "normal" caps');
                ok(!exists $caps->{platform}, 'or ignore them entirely');
            }
            else {
                ok(to_json($caps) eq '{}', 'an empty constructor defaults to an empty hash');
            }

            return HTTP::Response->new(204, 'OK', ['Content-Type' => 'application/json'], to_json($res));
        }
        else {
            # it's the DELETE when the driver calls
            # DESTROY. This should be the last call to /session/.
            return HTTP::Response->new(200, 'OK')
        }
    };

    $tua->map_response(qr{session}, $mock_session_handler);

    my $caps_driver = Selenium::Remote::Driver->new_from_caps(
        auto_close => 0,
        browser_name => 'not firefox',
        platform => 'WINDOWS',
        desired_capabilities => {
            'browserName' => 'firefox',
            'superfluous' => 'thing'
        },
        ua => $tua
    );

    ok($caps_driver->auto_close eq 0, 'and other properties are still set');

    $caps_driver = Selenium::Remote::Driver->new(
        auto_close => 0,
        browser_name => 'not firefox',
        platform => 'WINDOWS',
        desired_capabilities => {
            'browserName' => 'firefox',
            'superfluous' => 'thing'
        },
        ua => $tua
    );

    ok($caps_driver->auto_close eq 0, 'and other properties are set if we use the normal constructor');

    $caps_driver = Selenium::Remote::Driver->new_from_caps(ua => $tua);
    ok($requests_count == 3, 'The new_from_caps section has the correct number of requests to /session/');
}

GRID_STARTUP: {
    # Mimicking a grid server; /wd/hub/status fails, and we expect
    # grid/api/hub/status to be checked instead.
    my $tua = Test::LWP::UserAgent->new;
    my $not_ok = sub {
        return HTTP::Response->new(500, 'NOTOK');
    };
    $tua->map_response(qr{wd/hub/status}, $not_ok);

    my $grid_status_count = 0;
    my $ok = sub {
        my $res = {
            cmd_return => {},
            cmd_status => 'OK',
            sessionId => '123124123'
        };
        $grid_status_count++;
        return HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], to_json($res));
    };
    $tua->map_response(qr{(?:grid/api/hub/status|session)}, $ok);

    my $grid_driver = Selenium::Remote::Driver->new(ua => $tua);

    ok(defined $grid_driver, 'Grid: Object loaded fine using grid/api/hub/status');
    ok($grid_driver->isa('Selenium::Remote::Driver'), 'Grid: ...and of right type');
    ok($grid_status_count == 2, 'checked Grid specific status');
}

CHECK_DRIVER: {
    ok(defined $driver, 'Object loaded fine...');
    ok($driver->isa('Selenium::Remote::Driver'), '...and of right type');
    ok(defined $driver->{'session_id'}, 'Established session on remote server');
    $ret = $driver->get_capabilities;
    is($ret->{'browserName'}, 'firefox', 'Right capabilities');
    my $status = $driver->status;
    ok($status->{build}->{version},"Got status build.version");
    ok($status->{build}->{revision},"Got status build.revision");
    ok($status->{build}->{time},"Got status build.time");
}

IME: {
  SKIP: {
        eval {$driver->available_engines;};
        if ($@) {
            skip "ime not available on this system",3;
        }
    }
}

LOAD_PAGE: {
    $driver->get("$website/index.html");
    pass('Loaded home page');
    $ret = $driver->get_title();
    is($ret, 'Hello WebDriver', 'Got the title');
    $ret = $driver->get_current_url();
    ok($ret =~ m/$website/i, 'Got proper URL');
}

WINDOW: {
    $ret = $driver->get_current_window_handle();
    ok($ret =~ m/^{.*}$/, 'Proper window handle received');
    $ret = $driver->get_window_handles();
    is(ref $ret, 'ARRAY', 'Received all window handles');
    $ret = $driver->set_window_position(100,100);
    is($ret, 1, 'Set the window position to 100, 100');
    $ret = $driver->get_window_position();
    is ($ret->{'x'}, 100, 'Got the right X Co-ordinate');
    is ($ret->{'y'}, 100, 'Got the right Y Co-ordinate');
    $ret = $driver->set_window_size(640, 480);
    is($ret, 1, 'Set the window size to 640x480');
    $ret = $driver->get_window_size();
    is ($ret->{'height'}, 640, 'Got the right height');
    is ($ret->{'width'}, 480, 'Got the right width');
    $ret = $driver->maximize_window();
    is ($ret, 1, "Got confirmation from maximize");

  SKIP: {
        skip 'headless browsers don\'t get maximized', 2
          unless $^O =~ /darwin|MSWin32/;
        $ret = $driver->get_window_size();
        ok ($ret->{'height'} > 640, 'Height has increased');
        ok ($ret->{'width'} > 480, 'Width has increased');
    }

    $ret = $driver->get_page_source();
    ok($ret =~ m/^<html/i, 'Received page source');
    eval {$driver->set_implicit_wait_timeout(20001);};
    ok(!$@,"Set implicit wait timeout");
    eval {$driver->set_implicit_wait_timeout(0);};
    ok(!$@,"Reset implicit wait timeout");
    $ret = $driver->get("$website/frameset.html");
    $ret = $driver->switch_to_frame('second');

  SKIP: {
        skip 'Cannot rotate desktop browsers', 3;
        ok($driver->get_orientation eq 'PORTRAIT', 'Can get default orientation');
        $ret = $driver->set_orientation('LANDSCAPE');
        ok($ret, 'Can change orientation to LANDSCAPE');
        ok($driver->get_orientation eq 'LANDSCAPE', 'Can get changed orientation');
    }
}

COOKIES: {
    $driver->get("$website/cookies.html");
    $ret = $driver->get_all_cookies();
    is(@{$ret}, 2, 'Got 2 cookies');
    $ret = $driver->delete_all_cookies();
    pass('Deleting cookies...');
    $ret = $driver->get_all_cookies();
    is(@{$ret}, 0, 'Deleted all cookies.');
    $ret = $driver->add_cookie('foo', 'bar', '/', 'localhost', 0);
    pass('Adding cookie foo...');
    $ret = $driver->get_all_cookies();
    is(@{$ret}, 1, 'foo cookie added.');
    is($ret->[0]{'secure'}, 0, 'foo cookie insecure.');
    $ret = $driver->delete_cookie_named('foo');
    pass('Deleting cookie foo...');
    $ret = $driver->get_all_cookies();
    is(@{$ret}, 0, 'foo cookie deleted.');
    $ret = $driver->delete_all_cookies();
}

MOVE: {
    $driver->get("$website/index.html");
    $driver->get("$website/formPage.html");
    $ret = $driver->go_back();
    pass('Clicked Back...');
    $ret = $driver->get_title();
    is($ret, 'Hello WebDriver', 'Got the right title');
    $ret = $driver->go_forward();
    pass('Clicked Forward...');
    $ret = $driver->get_title();
    is($ret, 'We Leave From Here', 'Got the right title');
    $ret = $driver->refresh();
    pass('Clicked Refresh...');
    $ret = $driver->get_title();
    is($ret, 'We Leave From Here', 'Got the right title');
}

FIND: {
    my $elem = $driver->find_element("//input[\@id='checky']");
    ok($elem->isa('Selenium::Remote::WebElement'), 'Got WebElement via Xpath');
    $elem = $driver->find_element('checky', 'id');
    ok($elem->isa('Selenium::Remote::WebElement'), 'Got WebElement via Id');
    $elem = $driver->find_element('checky', 'name');
    ok($elem->isa('Selenium::Remote::WebElement'), 'Got WebElement via Name');

    $elem = $driver->find_element('multi', 'id');
    $elem = $driver->find_child_element($elem, "option");
    ok($elem->isa('Selenium::Remote::WebElement'), 'Got child WebElement...');
    $ret = $elem->get_value();
    is($ret, 'Eggs', '...right child WebElement');
    $ret = $driver->find_child_elements($elem, "//option[\@selected='selected']");
    is(@{$ret}, 4, 'Got 4 WebElements');
    my $expected_err = "An element could not be located on the page using the "
      . "given search parameters: "
      . "element_that_doesnt_exist,id"
      # the following needs to always be right before the eval
      . " at " . __FILE__ . " line " . (__LINE__+1);
    eval { $driver->find_element("element_that_doesnt_exist","id"); };
    chomp $@;
    like($@,qr/$expected_err/,"find_element croaks properly");
    my $elems = $driver->find_elements("//input[\@id='checky']");
    is(scalar(@$elems),1, 'Got an arrayref of WebElements');
    my @array_elems = $driver->find_elements("//input[\@id='checky']");
    is(scalar(@array_elems),1, 'Got an array of WebElements');
    is($elems->[0]->get_value(),$array_elems[0]->get_value(), 'and the elements returned are the same');
}

EXECUTE: {
    my $script = q{
          var arg1 = arguments[0];
          var elem = window.document.getElementById(arg1);
          return elem;
        };
    my $elem = $driver->execute_script($script,'checky');
    ok($elem->isa('Selenium::Remote::WebElement'), 'Executed script');
    is($elem->get_attribute('id'),'checky','Execute found proper element');
    $script = q{
          var links = window.document.links
          var length = links.length
          var results = new Array(length)
          while(length--) results[length] = links[length];
          return results;
        };
    $elem = $driver->execute_script($script);
    ok($elem, 'Got something back from execute_script');
    isa_ok($elem, 'ARRAY', 'What we got back is an ARRAY ref');
    ok(scalar(@$elem), 'There are elements in our array ref');
    foreach my $element (@$elem) {
        isa_ok($element, 'Selenium::Remote::WebElement', 'Element was converted to a WebElement object');
    }
    $script = q{
          var arg1 = arguments[0];
          var callback = arguments[arguments.length-1];
          var elem = window.document.getElementById(arg1);
          callback(elem);
        };
    $elem = $driver->execute_async_script($script,'multi');
    ok($elem->isa('Selenium::Remote::WebElement'),'Executed async script');
    is($elem->get_attribute('id'),'multi','Async found proper element');

    $script = 'return ""';
    my $empty_string = $driver->execute_script($script);
    cmp_ok($empty_string, 'eq', '', 'Empty strings are returned properly');
}

ALERT: {
    $driver->get("$website/alerts.html");
    $driver->find_element("alert",'id')->click;
    is($driver->get_alert_text,'cheese','alert text match');
    eval {$driver->dismiss_alert;};
    ok(!$@,"dismissed alert");
    $driver->find_element("prompt",'id')->click;
    is($driver->get_alert_text,'Enter your name','prompt text match');
    $driver->send_keys_to_prompt("Larry Wall");
    eval {$driver->accept_alert;};
    ok(!$@,"accepted prompt");
    is($driver->get_alert_text,'Larry Wall','keys sent to prompt');
    $driver->dismiss_alert;
    $driver->find_element("confirm",'id')->click;
    is($driver->get_alert_text,"Are you sure?",'confirm text match');
    eval {$driver->dismiss_alert;};
    ok(!$@,"dismissed confirm");
    is($driver->get_alert_text,'false',"dismissed confirmed correct");
    $driver->accept_alert;
    $driver->find_element("confirm",'id')->click;
    eval {$driver->accept_alert;};
    ok(!$@,"accepted confirm");
    is($driver->get_alert_text,'true',"accept confirm correct");
    $driver->accept_alert;
}

PAUSE: {
    my $starttime=time();
    $driver->pause();
    my $endtime=time();
    ok($starttime <= $endtime-1,"starttime <= endtime+1"); # Slept at least 1 second
    ok($starttime >= $endtime-2,"starttime >= endtime-2"); # Slept at most 2 seconds
}

AUTO_CLOSE: {
    my %stay_open_selenium_args = %selenium_args;
    $stay_open_selenium_args{auto_close} = 0;
    my $stayOpen = Selenium::Remote::Driver->new(
        %stay_open_selenium_args
    );

    $stayOpen->DESTROY();
    ok(defined $stayOpen->{'session_id'}, 'auto close in init hash is respected');
    $stayOpen->auto_close(1);
    $stayOpen->DESTROY();
    ok(!defined $stayOpen->{'session_id'}, 'true for auto close is still respected');

    $driver->auto_close(0);
    $driver->DESTROY();
    ok(defined $driver->{'session_id'}, 'changing autoclose on the fly keeps the session open');
    $driver->auto_close(1);
}

INNER_WINDOW_SIZE: {
    my %normal_selenium_args = %selenium_args;
    my $normal = Selenium::Remote::Driver->new(%normal_selenium_args)->get_window_size;
    my %resized_selenium_args = %selenium_args;
    $resized_selenium_args{inner_window_size} = [ 640,480];
    my $resized = Selenium::Remote::Driver->new(
        %resized_selenium_args
    )->get_window_size;

    ok($normal->{height} != $resized->{height}, 'inner window size: height is immediately changed');
    ok($normal->{width} != $resized->{width}, 'inner window size: width is immediately changed');
}

BASE_URL: {
    {
        package MySeleniumRemoteDriver;
        use Moo;
        extends 'Selenium::Remote::Driver';
        sub _execute_command { $_[2]->{url} }
        1;
    }

    my @tests = ({
        base_url => 'http://example.com',
        url      => '/foo',
        expected => 'http://example.com/foo',
    },{
        base_url => 'http://example.com/',
        url      => '/foo',
        expected => 'http://example.com/foo',
    },{
        base_url => 'http://example.com',
        url      => 'foo',
        expected => 'http://example.com/foo',
    },{
        base_url => 'http://example.com/a',
        url      => '/foo',
        expected => 'http://example.com/a/foo',
    },{
        base_url => 'http://example.com/a',
        url      => 'foo',
        expected => 'http://example.com/a/foo',
    },{
        base_url => 'http://example.com/a',
        url      => 'http://blog.example.com/foo',
        expected => 'http://blog.example.com/foo',
    });
    my $mock_commands = Selenium::Remote::Mock::Commands->new;
    for my $test (@tests) {
        my $base_url_driver = MySeleniumRemoteDriver->new(
            browser_name => 'firefox',
            base_url     => $test->{base_url},
            remote_conn => Selenium::Remote::Mock::RemoteConnection->new(
                spec => {
                    get =>
                      sub { my ( undef, $params ) = @_; return $params->{url} }
                  },
                mock_cmds => $mock_commands
            ),
            commands => $mock_commands,
        );
        my $got = $base_url_driver->get($test->{url});
        is $got, $test->{expected}, "base_url + $test->{url}";
    }
}

USER_AGENT: {
    my $ua = $driver->get_user_agent;
    ok($ua =~ /Firefox/, 'we can get a user agent');
}

STORAGE: {
  SKIP: {
        eval {
            $chrome->get($website);
        };

        if ($@ || !defined $chrome) {
            skip 'FirefoxDriver does not support Storage APIs; Chromedriver must be configured to perform storage tests', 3;
        }

        my ($key, $value) = ('testKey', 'testValue');
        $chrome->execute_script('localStorage.' . $key . ' = "' . $value . '"; return 1');

        my $actual = $chrome->get_local_storage_item($key);
        ok($actual eq $value, 'can retrieve local storage by key');

        ok($chrome->delete_local_storage_item($key), 'can delete local storage by key');
        my $now_empty = $chrome->get_local_storage_item($key);
        ok(!(defined $now_empty), 'retrieving an empty or deleted local storage key returns undef');
    }
}

HTML5: {
  SKIP: {
        skip 'HTML5 Application Cache is not supported by firefox or chrome', 1 if 1;
        $driver->get($website);
        my $status = $driver->cache_status;
        ok($status, 'we can get application cache status');
    }

  SKIP: {
        skip 'Geolocation requires Chrome to test', 2 unless $chrome;

        my $ret = $chrome->set_geolocation( location => {
            latitude => 40.714353,
            longitude => -74.005973,
            altitude => 0.056747
        });
        ok($ret, 'can set geolocation');

      TODO: {
            local $TODO = 'GET geolocation has a cast Long to Double error in Chromedriver';
            my $ret = {};
            eval { $ret = $chrome->get_geolocation };
            ok(exists $ret->{location}, 'get_geolocation returns a location dictionary.');
        }
    }
}

LOGS: {
    $driver->get($website);

    my $types = $driver->get_log_types;
    ok(scalar @$types >= 4, 'Can get log types');
    foreach (@$types) {
        my $log = $driver->get_log($_);
        ok(defined $log, 'Can get logs from the ' . $_);
    }
}

UPLOAD: {
    #Webdriver only returns the full filename if there isn't any path components in it, so test both cases
    my $testFile = "UEsDBBQACAAIAFtuNEYAAAAAAAAAAAAAAAAKABUAdXBsb2FkVGVzdFVUCQADjbG+VJ6xvlRVeAQA\n6APoAytJLS4BAFBLBwgMfn/YBgAAAAQAAABQSwECFAMUAAgACABbbjRGDH5/2AYAAAAEAAAACgAN\nAAAAAAAAAAAApIEAAAAAdXBsb2FkVGVzdFVUBQABjbG+VFV4AABQSwUGAAAAAAEAAQBFAAAAUwAA\nAAAA\n";
    my $otherTestFile = "UEsDBBQACAAIAFtuNEYAAAAAAAAAAAAAAAAMABUAdC91cGxvYWRUZXN0VVQJAAOesb5UnrG+VFV4\nBADoA+gDK0ktLgEAUEsHCAx+f9gGAAAABAAAAFBLAQIUAxQACAAIAFtuNEYMfn/YBgAAAAQAAAAM\nAA0AAAAAAAAAAACkgQAAAAB0L3VwbG9hZFRlc3RVVAUAAZ6xvlRVeAAAUEsFBgAAAAABAAEARwAA\nAFUAAAAAAA==\n";
    like( $driver->upload_file('uploadTest',$testFile),qr/uploadTest$/,'upload_file returns FULL path to the file: cwd');
    like( $driver->upload_file('t/uploadTest',$otherTestFile),qr/uploadTest$/,'upload_file returns FULL path to the file: subdir');

    #Negative tests to verify that our expected behavior codepath is travelled by tests
    like( exception { $driver->upload_file('@@@SomeFileThatDoesNotExist@@@')},qr/no such file/,"Passing missing file terminates program");
    like( exception { $driver->upload_file(__FILE__) },qr/501/,"Passing this file rightly fails due to mock not being present");
}

QUIT: {
    $ret = $driver->quit();
    ok((not defined $driver->{'session_id'}), 'Killed the remote session');
}

done_testing;
