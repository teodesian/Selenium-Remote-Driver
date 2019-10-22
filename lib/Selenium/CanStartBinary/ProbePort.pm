package Selenium::CanStartBinary::ProbePort;

use strict;
use warnings;

# ABSTRACT: Utility functions for finding open ports to eventually bind to

use IO::Socket::INET;
use Selenium::Waiter qw/wait_until/;

require Exporter;
our @ISA       = qw/Exporter/;
our @EXPORT_OK = qw/find_open_port_above find_open_port probe_port/;

=for Pod::Coverage *EVERYTHING*

=cut

sub find_open_port_above {
    socket(SOCK, PF_INET, SOCK_STREAM, getprotobyname("tcp"));
    bind(SOCK, sockaddr_in(0, INADDR_ANY));
    my $port = (sockaddr_in(getsockname(SOCK)))[0];
    close(SOCK);
    return $port;
}

sub find_open_port {
    my ($port) = @_;

    probe_port($port) ? return 0 : return $port;
}

sub probe_port {
    my ($port) = @_;

    return IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Timeout  => 3
    );
}
