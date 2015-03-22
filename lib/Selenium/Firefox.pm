package Selenium::Firefox;

# ABSTRACT: A convenience package for creating a Firefox instance
use Moo;
use Selenium::CanStartBinary::FindBinary qw/coerce_firefox_binary/;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

my $driver = Selenium::Firefox->new;

=head1 DESCRIPTION

This class allows you to use the FirefoxDriver without needing the JRE
or a selenium server running. When you refrain from passing the
C<remote_server_addr> and C<port> arguments, we will search for the
Firefox executable in your $PATH. We'll try to start the binary
connect to it, shutting it down at the end of the test.

If the Firefox application is not found in the expected places, we'll
fall back to the default L<Selenium::Remote::Driver> behavior of
assuming defaults of 127.0.0.1:4444 after waiting a few seconds.

If you specify a remote server address, or a port, we'll assume you
know what you're doing and take no additional behavior.

If you're curious whether your Selenium::Firefox instance is using a
separate Firefox binary, or through the selenium server, you can check
the C<binary_mode> attr after instantiation.

=cut

has '+browser_name' => (
    is => 'ro',
    default => sub { 'firefox' }
);

=attr binary

Optional: specify the path to your binary. If you don't specify
anything, we'll try to find it on our own via L<File::Which/which>.

=cut

has 'binary' => (
    is => 'lazy',
    coerce => \&coerce_firefox_binary,
    default => sub { 'firefox' },
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

with 'Selenium::CanStartBinary';

1;
