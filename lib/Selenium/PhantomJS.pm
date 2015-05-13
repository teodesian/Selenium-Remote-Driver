package Selenium::PhantomJS;

# ABSTRACT: Use GhostDriver without a Selenium server
use Moo;
use Selenium::CanStartBinary::FindBinary qw/coerce_simple_binary/;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::PhantomJS->new;

=head1 DESCRIPTION

This class allows you to use PhantomJS via Ghostdriver without needing
the JRE or a selenium server running. When you refrain from passing
the C<remote_server_addr> and C<port> arguments, we will search for
the phantomjs executable binary in your $PATH. We'll try to start the
binary connect to it, shutting it down at the end of the test.

If the binary is not found, we'll fall back to the default
L<Selenium::Remote::Driver> behavior of assuming defaults of
127.0.0.1:4444 after waiting a few seconds.

If you specify a remote server address, or a port, we'll assume you
know what you're doing and take no additional behavior.

If you're curious whether your Selenium::PhantomJS instance is using a
separate PhantomJS binary, or through the selenium server, you can check
the C<binary_mode> attr after instantiation.

    my $driver = Selenium::PhantomJS->new;
    print $driver->binary_mode;

N.B. - if you're using Windows and you installed C<phantomjs> via
C<npm install -g phantomjs>, there is a very high probability that we
will _not_ close down your phantomjs binary correctly after your
test. You will be able to tell if we leave around empty command
windows that you didn't start yourself. The easiest way to fix this is
to download PhantomJS manually from their
L<website|http://phantomjs.org/download.html> and put it in your
C<%PATH%>. If this is a blocking issue for you, let us know in
L<Github|https://github.com/gempesaw/Selenium-Remote-Driver>; thanks!

=cut

has '+browser_name' => (
    is => 'ro',
    default => sub { 'phantomjs' }
);

=attr binary

Optional: specify the path to your binary. If you don't specify
anything, we'll try to find it on our own via L<File::Which/which>.

=cut

has 'binary' => (
    is => 'lazy',
    coerce => \&coerce_simple_binary,
    default => sub { 'phantomjs' },
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
    default => sub { 8910 }
);

has '_binary_args' => (
    is => 'lazy',
    builder => sub {
        my ($self) = @_;

        return ' --webdriver=127.0.0.1:' . $self->port;
    }
);

with 'Selenium::CanStartBinary';

1;
