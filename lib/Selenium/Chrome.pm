package Selenium::Chrome;

# ABSTRACT: A convenience package for creating a Chrome instance
use Moo;
with 'Selenium::CanStartBinary';
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::Chrome->new;

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
    is => 'ro',
    default => sub { 'chrome' }
);

# By shadowing the parent's port function, we can set the port in
# _build_binary_mode's builder
has '+port' => (
    is => 'lazy'
);

has 'binary_name' => (
    is => 'lazy',
    default => sub { 'chromedriver' }
);

has 'binary_port' => (
    is => 'lazy',
    default => sub { 9515 }
);

sub DEMOLISH {
    my ($self) = @_;

    $self->shutdown_binary;
}

1;
