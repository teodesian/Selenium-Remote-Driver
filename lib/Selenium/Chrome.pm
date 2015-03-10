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

sub _find_executable {
    my ($binary) = @_;

    my $executable = which($binary);

    if (not defined $executable) {
        warn q(
Unable to find the chromedriver binary in your $PATH. Please download the server from http://chromedriver.storage.googleapis.com/index.html and place it somewhere on your $PATH. More info is available at http://code.google.com/p/selenium/wiki/ChromeDriver.

We'll try falling back to standard Remote Driver mode via the webdriver.chrome.driver property...
);
    }

    return $executable;
}

sub _construct_command {
    my ($executable, $port) = @_;

    my %args = (
        'base-url' => 'wd/hub',
        'port' => $port
    );

    my @args = map { '--' . $_ . '=' . $args{$_} } keys %args;

    return join(' ', ($executable, @args, '> /dev/null 2>&1 &') );
}

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
