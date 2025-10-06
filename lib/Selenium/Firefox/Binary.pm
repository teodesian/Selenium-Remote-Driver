package Selenium::Firefox::Binary;

use strict;
use warnings;

# ABSTRACT: Subroutines for locating and properly initializing the Firefox Binary
use File::Which qw/which/;
use Selenium::Firefox::Profile;

require Exporter;
our @ISA       = qw/Exporter/;
our @EXPORT_OK = qw/firefox_path setup_firefox_binary_env/;

sub _firefox_windows_path {

    # TODO: make this slightly less dumb
    my @program_files = (
        $ENV{PROGRAMFILES} // 'C:\Program Files',
        $ENV{'PROGRAMFILES(X86)'} // 'C:\Program Files (x86)',
    );

    foreach (@program_files) {
        my $binary_path = $_ . '\Mozilla Firefox\firefox.exe';
        return $binary_path if -x $binary_path;
    }

    # Fall back to a completely naive strategy
    warn
q/We couldn't find a viable firefox.EXE; you may want to specify it via the binary attribute./;
    return which('firefox');
}

sub _firefox_darwin_path {
    my $default_firefox =
      '/Applications/Firefox.app/Contents/MacOS/firefox';
    my $default_firefox_bin =
      '/Applications/Firefox.app/Contents/MacOS/firefox-bin';

    for my $path ( $default_firefox_bin, $default_firefox ) {
        if ( -e $path && -x $path ) {
            return $path;
        }
    }
    return which('firefox-bin') || which('firefox');
}

sub _firefox_unix_path {

    # TODO: maybe which('firefox3'), which('firefox2') ?
    return which('firefox') || '/usr/bin/firefox';
}

=head1 SUBROUTINES

=head2 firefox_path

Return the path to the firefox binary on your system.

=cut

sub firefox_path {
    my $path;
    if ( $^O eq 'MSWin32' ) {
        $path = _firefox_windows_path();
    }
    elsif ( $^O eq 'darwin' ) {
        $path = _firefox_darwin_path();
    }
    else {
        $path = _firefox_unix_path;
    }

    if ( not -x $path ) {
        die $path . ' is not an executable file.';
    }

    return $path;
}

=head2 setup_firefox_binary_env

Sets various environment variables to make firefox work correctly with webDriver.

=cut

# We want the profile to persist to the end of the session, not just
# the end of this function.
my $profile;

sub setup_firefox_binary_env {
    my ( $port, $marionette_port, $caller_profile ) = @_;

    $profile = $caller_profile || Selenium::Firefox::Profile->new;
    $profile->add_webdriver( $port, $marionette_port );
    $profile->add_marionette($marionette_port);

    # For non-geckodriver/marionette startup, we instruct Firefox to
    # use the profile by specifying the appropriate environment
    # variables for it to hook onto.
    if ( !$marionette_port ) {
        $ENV{'XRE_PROFILE_PATH'} = $profile->_layout_on_disk;
        $ENV{'MOZ_NO_REMOTE'} = '1';    # able to launch multiple instances
        $ENV{'MOZ_CRASHREPORTER_DISABLE'} = '1';    # disable breakpad
        $ENV{'NO_EM_RESTART'} =
          '1';    # prevent the binary from detaching from the console.log
    }
    else {
        # In case the user created an old Firefox, which would've set
        # those ENV variables, and then wanted to create a new Firefox
        # afterwards, the env variables would still be around, and the
        # new Firefox would respect the XRE_PROFILE_PATH and try to
        # load it in the new geckodriver Firefox, which would cause an
        # extension compatibility check
        my @env_vars = qw/
          XRE_PROFILE_PATH
          MOZ_NO_REMOTE
          MOZ_CRASHREPORTER_DISABLE
          NO_EM_RESTART
          /;

        foreach (@env_vars) {
            delete $ENV{$_};
        }
    }

    return $profile;
}

1;
