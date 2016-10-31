use strict;
use warnings;
use File::Which qw/which/;
use Selenium::Chrome;
use Selenium::Firefox;
use Selenium::Firefox::Binary;
use Selenium::PhantomJS;
use Sub::Install;
use Test::Fatal;
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

MANUAL: {
    ok( exception { PhantomJS->new( binary => '/bad/executable') },
        'we throw if the user specified binary is not executable');

  SKIP: {
        my $phantom_binary = which('phantomjs');
        skip 'PhantomJS needed for manual binary path tests', 2
          unless $phantom_binary;

        my $manual_phantom = Selenium::PhantomJS->new(
            binary => $phantom_binary
        );
        isnt( $manual_phantom->port, 4444, 'manual phantom can start up user specified binary');
        ok( Selenium::CanStartBinary::probe_port( $manual_phantom->port ), 'the manual chrome binary is listening on its port');
    }
}

CHROME: {
  SKIP: {
        my $has_chromedriver = which('chromedriver');
        skip 'Chrome binary not found in path', 3
          unless $has_chromedriver;

        my $chrome = Selenium::Chrome->new(
            custom_args => ' --fake-arg'
        );

        like( $chrome->_construct_command, qr/--fake-arg/, 'can pass custom args');
        ok( $chrome->browser_name eq 'chrome', 'convenience chrome is okay' );
        isnt( $chrome->port, 4444, 'chrome can start up its own binary' );
        like( $chrome->_binary_args, qr/--url-base=wd\/hub/, 'chrome has correct webdriver context' );

        ok( Selenium::CanStartBinary::probe_port( $chrome->port ), 'the chrome binary is listening on its port');
    }
}

FIREFOX: {
  SKIP: {
        skip 'Firefox will not start up on UNIX without a display', 6
          if ($^O ne 'MSWin32' && ! $ENV{DISPLAY});

      SKIP: {
            my $has_geckodriver = which('geckodriver');
            skip 'Firefox geckodriver not found in path', 3
              unless $has_geckodriver;

            my $firefox = Selenium::Firefox->new;
            isnt( $firefox->port, 4444, 'firefox can start up its own binary');
            ok(Selenium::CanStartBinary::probe_port($firefox->port),
               'the firefox binary is listening on its port');

            ok(Selenium::CanStartBinary::probe_port($firefox->marionette_port),
               'the firefox binary is listening on its marionette port');

            EXECUTE_SCRIPT: {
                  $firefox->get("https://www.google.com");

                  my $elem = $firefox->find_element('div', 'css');
                  my $script_elem = $firefox->execute_script('return arguments[0]', $elem);
                  isa_ok($script_elem, 'Selenium::Remote::WebElement', 'execute_script element return');
                  is($elem->id, $script_elem->id, 'Sync script returns identical WebElement id');

                  my $async = q{
var callback = arguments[arguments.length - 1];
callback(arguments[0]);
};
                  my $async_elem = $firefox->execute_async_script($async, $elem);
                  isa_ok($async_elem, 'Selenium::Remote::WebElement', 'execute_async_script element return');
                  is($elem->id, $async_elem->id, 'Async script returns identical WebElement id');
              }

            $firefox->shutdown_binary;
        }

      SKIP: {
            # These are admittedly a very brittle test, so it's getting
            # skipped almost all the time.
            my $ff47_binary = '/Applications/Firefox47.app/Contents/MacOS/firefox-bin';
            skip 'Firefox 47 compatibility tests require FF47 to be installed', 3
              unless -x $ff47_binary;

            my $ff47 = Selenium::Firefox->new(
                marionette_enabled => 0,
                firefox_binary => $ff47_binary
            );
            isnt( $ff47->port, 4444, 'older Firefox47 can start up its own binary');
            ok( Selenium::CanStartBinary::probe_port( $ff47->port ),
                'the older Firefox47 is listening on its port');
            $ff47->shutdown_binary;


          PROFILE: {
                my $encoded = 0;
                {
                    package FFProfile;
                    use Moo;
                    extends 'Selenium::Firefox::Profile';

                    sub _encode { $encoded++ };
                    1;
                }

                my $p = FFProfile->new;

                # we don't need to keep this browser object around at all,
                # we just want to run through the construction and confirm
                # that nothing gets encoded
                Selenium::Firefox->new(
                    marionette_enabled => 0,
                    firefox_binary => $ff47_binary,
                    firefox_profile => $p
                )->shutdown_binary;
                is($encoded, 0, 'older Firefox47 does not encode profile unnecessarily');
            }

        }
    }
}

TIMEOUT: {
  SKIP: {
        my $has_geckodriver = which('geckodriver');
        skip 'Firefox geckodriver not found in path', 1
          unless $has_geckodriver;

        my $binary = Selenium::Firefox::Binary::firefox_path();
        skip 'Firefox browser not found in path', 1
          unless $binary;

        # Override the binary command construction so that no web driver
        # will start up.
        Sub::Install::reinstall_sub({
            code => sub { return '' },
            into => 'Selenium::CanStartBinary',
            as => '_construct_command'
        });

        my $start = time;
        eval { Selenium::Firefox->new( startup_timeout => 1 ) };
        # The test leaves a bit of a cushion to handle any unexpected
        # latency issues when starting up the browser - the important part
        # is that our timeout duration is _not_ the default 10 seconds.
        ok( time - $start < 10, 'We can specify how long to wait for a binary to be available'  );
    }
}

sub is_proper_phantomjs_available {
    my $ver = `phantomjs --version` // '';
    chomp $ver;

    $ver =~ s/^(\d\.\d).*/$1/;
    return $ver >= 1.9;
}

done_testing;
