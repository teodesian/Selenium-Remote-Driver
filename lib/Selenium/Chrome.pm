package Selenium::Chrome;

# ABSTRACT: A convenience package for creating a Chrome instance
use Moo;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::Chrome->new;

=cut

has '+browser_name' => (
    is => 'ro',
    default => sub { 'chrome' }
);

sub _find_open_port_above {
    my ($port) = @_;

    my $free_port = wait_until {
        if (_probe_port($port)) {
            $port++;
            return 0;
        }
        else {
            return $port;
        }
    };

    return $free_port;
}

sub _probe_port {
    my ($port) = @_;

    return IO::Socket::INET->new(
        PeerAddr => $default_binary_server,
        PeerPort => $port,
        Timeout => 3
    );
}
1;
