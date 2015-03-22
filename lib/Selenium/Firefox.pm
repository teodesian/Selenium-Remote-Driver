package Selenium::Firefox;

# ABSTRACT: A convenience package for creating a Firefox instance
use Moo;
with 'Selenium::CanStartBinary';
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

# By shadowing the parent's port, we can set it in _build_binary_mode properly
has '+port' => (
    is => 'lazy',
    default => sub { 4444 }
);

has 'binary' => (
    is => 'lazy',
    default => sub { 'firefox' },
);

has 'binary_port' => (
    is => 'lazy',
    default => sub { 9090 }
);

1;
