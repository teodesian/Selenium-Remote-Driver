package Selenium::Chrome;

# ABSTRACT: A convenience package for creating a Chrome instance
use File::Which qw/which/;
use IO::Socket::INET;
use Selenium::Waiter qw/wait_until/;

use Moo;
use namespace::clean;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::Chrome->new;

=cut

my $default_binary_server = '127.0.0.1';
my $default_binary_port = 9515;

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
        my $executable = _find_executable('chromedriver');
        my $port = _find_open_port_above($default_binary_port);
        my $command = _construct_command($executable, $port);

        system($command);
        my $success = wait_until { _probe_port($port) } timeout => 10;
        if ($success) {
            $self->port($port);
        }
        else {
            warn qq(
Unable to start up the chromedriver binary via:

    $command

We'll try falling back to standard Remote Driver mode via the webdriver.chrome.driver property...
);

        }

        return 1;
    }
    else {
        return 0;
    }
}

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

sub DEMOLISH {
    my ($self) = @_;

    my $port = $self->port;
    my $ua = LWP::UserAgent->new;

    $ua->get($default_binary_server . ':' . $port . '/wd/hub/shutdown');
}

1;
