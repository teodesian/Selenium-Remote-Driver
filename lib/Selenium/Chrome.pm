package Selenium::Chrome;

use strict;
use warnings;

# ABSTRACT: Use ChromeDriver without a Selenium server
use Moo;
use Selenium::CanStartBinary::FindBinary qw/coerce_simple_binary/;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::Chrome->new;
    # when you're done
    $driver->shutdown_binary;

=for Pod::Coverage has_binary

=head1 DESCRIPTION

This class allows you to use the ChromeDriver without needing the JRE
or a selenium server running. When you refrain from passing the
C<remote_server_addr> and C<port> arguments, we will search for the
chromedriver executable binary in your $PATH. We'll try to start the
binary connect to it, shutting it down at the end of the test.

If the chromedriver binary is not found, we'll fall back to the
default L<Selenium::Remote::Driver> behavior of assuming defaults of
127.0.0.1:4444 after waiting a few seconds.

If you specify a remote server address, or a port, we'll assume you
know what you're doing and take no additional behavior.

If you're curious whether your Selenium::Chrome instance is using a
separate ChromeDriver binary, or through the selenium server, you can
check the C<binary_mode> attr after instantiation.

=cut

has '+browser_name' => (
    is      => 'ro',
    default => sub { 'chrome' }
);

=attr binary

Optional: specify the path to your binary. If you don't specify
anything, we'll try to find it on our own via L<File::Which/which>.

=cut

has 'binary' => (
    is        => 'lazy',
    coerce    => \&coerce_simple_binary,
    default   => sub { 'chromedriver' },
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
    is      => 'lazy',
    default => sub { 9515 }
);

has '_binary_args' => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;

        my $context = $self->wd_context_prefix;
        $context =~ s{^/}{};

        return ' --port=' . $self->port . ' --url-base=' . $context . ' ';
    }
);

with 'Selenium::CanStartBinary';

=attr custom_args

Optional: specify any additional command line arguments you'd like
invoked during the binary startup. See
L<Selenium::CanStartBinary/custom_args> for more information.

=attr startup_timeout

Optional: specify how long to wait for the binary to start itself and
listen on its port. The default duration is arbitrarily 10 seconds. It
accepts an integer number of seconds to wait: the following will wait
up to 20 seconds:

    Selenium::Chrome->new( startup_timeout => 20 );

See L<Selenium::CanStartBinary/startup_timeout> for more information.

=method shutdown_binary

Call this method instead of L<Selenium::Remote::Driver/quit> to ensure
that the binary executable is also closed, instead of simply closing
the browser itself. If the browser is still around, it will call
C<quit> for you. After that, it will try to shutdown the browser
binary by making a GET to /shutdown and on Windows, it will attempt to
do a C<taskkill> on the binary CMD window.

    $self->shutdown_binary;

It doesn't take any arguments, and it doesn't return anything.

We do our best to call this when the C<$driver> option goes out of
scope, but if that happens during global destruction, there's nothing
we can do.

=attr fixed_ports

Optional: Throw instead of searching for additional ports; see
L<Selenium::CanStartBinary/fixed_ports> for more info.

=cut

1;
