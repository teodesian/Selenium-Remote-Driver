package Selenium::Chrome;

# ABSTRACT: A convenience package for creating a Chrome instance
use Selenium::Binary qw/start_binary_on_port/;

use Moo;
use namespace::clean;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::Chrome->new;

=head1 DESCRIPTION

This class allows you to use the ChromeDriver without needing the JRE
or a selenium server running. If you refrain from passing the
C<remote_server_addr> and C<port> arguments, we will search for the
chromedriver executable binary in your $PATH. We'll try to start the
binary connect to it, shutting it down at the end of the test.

If the chromedriver binary is not found, we'll fall back to the
default L<Selenium::Remote::Driver> behavior of assuming defaults of
127.0.0.1:4444.

If you specify a remote server address, or a port, we'll assume you
know what you're doing and take no additional behavior.

If you're curious whether your Selenium::Chrome instance is using a
separate ChromeDriver binary, or through the selenium server, you can
check the C<binary_mode> attr after instantiation.

=cut

use constant CHROMEDRIVER_PORT => 9515;

has '+browser_name' => (
    is => 'ro',
    default => sub { 'chrome' }
);

# By shadowing the parent's port function, we can set the port in
# _build_binary_mode's builder
has '+port' => (
    is => 'lazy'
);

has 'binary_mode' => (
    is => 'ro',
    init_arg => undef,
    builder => 1
);

sub _build_binary_mode {
    my ($self) = @_;

    if (! $self->has_remote_server_addr && ! $self->has_port) {
        try {
            my $port = start_binary_on_port('chromedriver', CHROMEDRIVER_PORT);
            $self->port($port);
            return 1;
        }
        catch {
            warn $_;
            return 0;
        }
    }
    else {
        return 0;
    }
}

sub DEMOLISH {
    my ($self) = @_;

    if ($self->binary_mode) {

        my $port = $self->port;
        my $ua = LWP::UserAgent->new;

        $ua->get('127.0.0.1:' . $port . '/wd/hub/shutdown');
    }
}

1;
