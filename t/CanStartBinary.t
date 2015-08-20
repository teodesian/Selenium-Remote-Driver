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

        my $chrome = Selenium::Chrome->new;
        ok( $chrome->browser_name eq 'chrome', 'convenience chrome is okay' );
        isnt( $chrome->port, 4444, 'chrome can start up its own binary');

        ok( Selenium::CanStartBinary::probe_port( $chrome->port ), 'the chrome binary is listening on its port');
    }
}

FIREFOX: {
  SKIP: {
        skip 'Firefox will not start up on UNIX without a display', 3
          if ($^O ne 'MSWin32' && ! $ENV{DISPLAY});
        my $binary = Selenium::Firefox::Binary::firefox_path();
        skip 'Firefox binary not found in path', 3
          unless $binary;

        ok(-x $binary, 'we can find some sort of firefox');

        my $firefox = Selenium::Firefox->new;
        isnt( $firefox->port, 4444, 'firefox can start up its own binary');
        ok( Selenium::CanStartBinary::probe_port( $firefox->port ), 'the firefox binary is listening on its port');
    }
}

TIMEOUT: {
    my $binary = Selenium::Firefox::Binary::firefox_path();
    skip 'Firefox binary not found in path', 3
      unless $binary;

    # Force the port check to exhaust the wait_until timeout so that
    # we can exercise the startup_timeout constructor option
    # functionality.
    Sub::Install::reinstall_sub({
        code => sub { return 0 },
        into => 'Selenium::CanStartBinary',
        as => 'probe_port'
    });

    my $start = time;
    eval { Selenium::Firefox->new( startup_timeout => 1 ) };
    # The test leaves a bit of a cushion to handle any unexpected
    # latency issues when starting up the browser - the important part
    # is that our timeout duration is _not_ the default 10 seconds.
    ok( time - $start < 10, 'We can specify how long to wait for a binary to be available'  );

}

sub is_proper_phantomjs_available {
    my $ver = `phantomjs --version` // '';
    chomp $ver;

    $ver =~ s/^(\d\.\d).*/$1/;
    return $ver >= 1.9;
}

done_testing;
