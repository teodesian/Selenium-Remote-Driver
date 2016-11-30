package Selenium::CanStartBinary::ProbePort;

# ABSTRACT: Utility functions for finding open ports to eventually bind to
use IO::Socket::INET;
use Selenium::Waiter qw/wait_until/;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/find_open_port_above find_open_port probe_port/;

sub find_open_port_above {
    my ($port) = @_;

    my $free_port = wait_until {
        if ( probe_port($port) ) {
            $port++;
            return 0;
        }
        else {
            return $port;
        }
    };

    return $free_port;
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
        Timeout => 3
    );
}
