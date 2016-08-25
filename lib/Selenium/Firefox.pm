package Selenium::Firefox;

# ABSTRACT: Use FirefoxDriver without a Selenium server
use Moo;
use Selenium::Firefox::Binary qw/firefox_path/;
use Selenium::CanStartBinary::FindBinary qw/coerce_simple_binary coerce_firefox_binary/;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    # these two are the same, and will only work with Firefox 48 and
    # greater
    my $driver = Selenium::Firefox->new;
    my $driver = Selenium::Firefox->new( marionette_enabled => 1 );

    # For Firefox 47 and older, disable marionette:
    my $driver = Selenium::Firefox->new( marionette_enabled => 0 );

=head1 DESCRIPTION

This class allows you to use the FirefoxDriver without needing the JRE
or a selenium server running. Unlike starting up an instance of
S::R::D, do not pass the C<remote_server_addr> and C<port> arguments,
and we will search for the Firefox executable in your $PATH. We'll try
to start the binary, connect to it, and shut it down at the end of the
test.

If the Firefox application is not found in the expected places, we'll
fall back to the default L<Selenium::Remote::Driver> behavior of
assuming defaults of 127.0.0.1:4444 after waiting a few seconds.

If you specify a remote server address, or a port, our assumption is
that you are doing standard S::R::D behavior and we will not attempt
any binary startup.

If you're curious whether your Selenium::Firefox instance is using a
separate Firefox binary, or through the selenium server, you can check
the value of the C<binary_mode> attr after instantiation.

=cut

has '+browser_name' => (
    is => 'ro',
    default => sub { 'firefox' }
);

=attr binary

Optional: specify the path to the C<geckodriver> binary - this is NOT
the path to the Firefox browser. To specify the path to your Firefox
browser binary, see the L</firefox_binary> attr.

For Firefox 48 and greater, this is the path to your C<geckodriver>
executable. If you don't specify anything, we'll search for
C<geckodriver> in your $PATH.

For Firefox 47 and older, this attribute does not apply, because the
older FF browsers do not use the separate driver binary startup.

=cut

has 'binary' => (
    is => 'lazy',
    coerce => \&coerce_simple_binary,
    default => sub { 'geckodriver' },
    predicate => 1
);

=attr binary_port

Optional: specify the port that we should bind to. If you don't
specify anything, we'll default to the driver's default port. Since
there's no a priori guarantee that this will be an open port, this is
_not_ necessarily the port that we end up using - if the port here is
already bound, we'll search above it until we find an open one.

See L<Selenium::CanStartBinary/port> for more details, and
L<Selenium::Remote::Driver/port> after instantiation to see what the
actual port turned out to be.

=cut

has 'binary_port' => (
    is => 'lazy',
    default => sub { 9090 }
);

=attr firefox_profile

Optional: Pass in an instance of L<Selenium::Firefox::Profile>
pre-configured as you please. The preferences you specify will be
merged with the ones necessary for setting up webdriver, and as a
result some options may be overwritten or ignored.

    my $profile = Selenium::Firefox::Profile->new;
    my $firefox = Selenium::Firefox->new(
        firefox_profile => $profile
    );

=cut

has '_binary_args' => (
    is => 'lazy',
    builder => sub {
        my ($self) = @_;

        if ( $self->marionette_enabled ) {
            my $args = ' --port ' . $self->port;
            $args .= ' --marionette-port ' . $self->marionette_binary_port;

            if ( $self->has_firefox_binary ) {
                $args .= ' --binary "' . $self->firefox_binary . '"';
            }

            return $args;
        }
        else {
            return ' -no-remote';
        }
    }
);

has '+wd_context_prefix' => (
    is => 'ro',
    default => sub {
        my ($self) = @_;

        if ($self->marionette_enabled) {
            return '';
        }
        else {
            return '/hub';
        }

    }
);

=attr marionette_binary_port

Optional: specify the port that we should bind marionette to. If you don't
specify anything, we'll default to the marionette's default port. Since
there's no a priori guarantee that this will be an open port, this is
_not_ necessarily the port that we end up using - if the port here is
already bound, we'll search above it until we find an open one.

    Selenium::Firefox->new(
        marionette_enabled     => 1,
        marionette_binary_port => 12345,
    );

Attempting to specify a C<marionette_binary_port> in conjunction with
setting C<marionette_enabled> does not make sense and will most likely
not do anything useful.

=cut

has 'marionette_binary_port' => (
    is => 'lazy',
    default => sub { 2828 }
);

=attr marionette_enabled

Optional: specify whether
L<marionette|https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette>
should be enabled or not. By default, marionette is enabled, which
assumes you are running with Firefox 48 or newer. To use this module
to start Firefox 47 or older, you must pass C<marionette_enabled =>
0>.

    my $ff48 = Selenium::Firefox->new( marionette_enabled => 1 ); # defaults to 1
    my $ff47 = Selenium::Firefox->new( marionette_enabled => 0 );

=cut

has 'marionette_enabled' => (
    is => 'lazy',
    default => 1
);

=attr firefox_binary

Optional: specify the path to the Firefox browser executable. Although
we will attempt to locate this in your $PATH, you may specify it
explicitly here. Note that path here must point to a file that exists
and is executable, or we will croak.

For Firefox 48 and newer, this will be passed to C<geckodriver> such
that it will attempt to start up the Firefox at the specified path.

For Firefox 47 and older, this browser path will be the file that we
directly start up.

=cut

has 'firefox_binary' => (
    is => 'ro',
    coerce => \&coerce_firefox_binary,
    predicate => 1,
    builder => 'firefox_path'
);


with 'Selenium::CanStartBinary';

=attr custom_args

Optional: specify any additional command line arguments you'd like
invoked during the binary startup. See
L<Selenium::CanStartBinary/custom_args> for more information.

For Firefox 48 and newer, these arguments will be passed to
geckodriver during start up.

For Firefox 47 and older, these arguments will be passed to the
Firefox browser during start up.

=attr startup_timeout

Optional: specify how long to wait for the binary to start itself and
listen on its port. The default duration is arbitrarily 10 seconds. It
accepts an integer number of seconds to wait: the following will wait
up to 20 seconds:

    Selenium::Firefox->new( startup_timeout => 20 );

See L<Selenium::CanStartBinary/startup_timeout> for more information.

=cut

1;
